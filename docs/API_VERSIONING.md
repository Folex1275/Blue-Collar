# BlueCollar API Versioning Architecture

## Overview

This document describes the API versioning strategy and architecture for BlueCollar.

## Versioning Strategy

### URL Path Versioning (Primary)

All endpoints are versioned using URL paths:

```
/api/v1/workers      # v1 endpoints
/api/v2/workers      # v2 endpoints
```

**Advantages:**
- Clear version visibility in URLs
- Easy to route and debug
- Clear deprecation path
- Search engines understand versions

### Header-Based Versioning (Secondary)

Optional support for `Accept-Version` header:

```bash
curl https://api.bluecollar.app/api/workers \
  -H "Accept-Version: v2"
```

Falls back to path-based version if both are present.

### Default Version

When no version is specified, requests are redirected to v1 with deprecation headers:

```
GET /api/workers → 301 Redirect to /api/v1/workers
Headers: Deprecation: true, Sunset: ...
```

## Version Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│ DEVELOPMENT                                              │
│ (New features, breaking changes tested)                  │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ CURRENT VERSION (v2)                                     │
│ (Active development, all new clients use this)           │
│ - Full support                                           │
│ - Rate limits: 150 req/min                              │
│ - Auth: JWT required, no API keys                        │
└──────────────────────┬──────────────────────────────────┘
                       │ (After 12 months)
                       ▼
┌─────────────────────────────────────────────────────────┐
│ DEPRECATED VERSION (v1)                                  │
│ (Still supported, but migration encouraged)              │
│ - Full support during grace period                       │
│ - Deprecation headers on all responses                   │
│ - Rate limits: 100 req/min                              │
│ - Auth: JWT or API key (legacy)                          │
└──────────────────────┬──────────────────────────────────┘
                       │ (After 12 months + 1 month notice)
                       ▼
┌─────────────────────────────────────────────────────────┐
│ RETIRED (v0)                                             │
│ (No longer supported)                                    │
│ - Returns 410 Gone                                       │
│ - Clients must migrate                                   │
└─────────────────────────────────────────────────────────┘
```

## Implementation

### Configuration

Version config is centralized in `middleware/version.ts`:

```typescript
export const VERSION_CONFIG = {
  current: 'v2',
  supported: ['v1', 'v2'] as const,
  deprecated: [] as string[],
  sunset: {
    v1: null,
    v2: null,
  },
  rateLimitByVersion: {
    v1: { requests: 100, windowMs: 60000 },
    v2: { requests: 150, windowMs: 60000 },
  },
  authPolicies: {
    v1: { allowApiKey: true, requireJWT: true },
    v2: { allowApiKey: false, requireJWT: true },
  },
}
```

### Request Flow

```
1. Request → versionMiddleware
   ├─ Extract version from URL path
   ├─ Fall back to Accept-Version header
   ├─ Default to v1
   └─ Attach to req.apiVersion

2. Request → versionDeprecationMiddleware
   ├─ Check if version is deprecated
   └─ Add deprecation headers if needed

3. Request → Route Handler
   ├─ Process request
   └─ Generate response

4. Response → responseSchemaVersioning
   ├─ Transform fields based on version
   └─ Return compatible schema

5. Response → Client
   ├─ Headers: X-API-Version, Deprecation, Sunset
   └─ Body: Version-compatible JSON
```

### Response Headers

All API responses include version information:

```
X-API-Version: v2                    # Current version
Deprecation: false                   # Is deprecated?
Warning: <optional>                  # Deprecation warning
Sunset: <optional>                   # Sunset date (RFC 7231)
```

Example deprecation response (when v1 is deprecated):

```
HTTP/1.1 200 OK
X-API-Version: v1
Deprecation: true
Warning: 299 - "API version v1 is deprecated. Migrate to v2."
Sunset: Sat, 01 Jan 2027 00:00:00 GMT
Content-Type: application/json

{...}
```

## Schema Versioning

### Field Addition (Backward Compatible)

New fields are added in v2:

```javascript
// v1 Worker
{
  id, name, email, avgRating, categoryId, ...
}

// v2 Worker (all v1 fields + new ones)
{
  id, name, email, avgRating, categoryId,
  verificationStatus,  // NEW in v2
  ...
}
```

### Field Removal (Breaking Change)

If a field must be removed, it happens in the next major version only.

### Field Transformation

Schema transformers in `utils/schemaVersioning.ts` handle:

```typescript
transformResponseData(data, 'worker', 'v2', 'v1')
// Transforms v1 worker to v2 format (adds verificationStatus)

filterCompatibleFields(data, 'v2', 'worker')
// Returns only fields valid for v2
```

## Rate Limiting

Version-specific rate limits using Redis:

```typescript
// Middleware: versionRateLimit
// Uses Redis key: rl:v1:{{userId}}
// Limits: v1=100/min, v2=150/min

// Check limits
GET /api/v1/versions
→ { versions: [{
    version: 'v1',
    rateLimiting: { requests: 100, windowMs: 60000 }
  }]
}
```

## Authentication Policies

Different auth rules per version:

```typescript
// v1: Allows both JWT and API keys
if (isApiKeyAllowedForVersion('v1')) { ... }

// v2: JWT only
if (isJwtRequiredForVersion('v2')) { ... }
```

## API Documentation

Versioned OpenAPI docs are generated and served:

- **v1 Docs**: `GET /api/v1/docs` → Swagger UI for v1
- **v2 Docs**: `GET /api/v2/docs` → Swagger UI for v2
- **OpenAPI JSON**: `GET /api/v1/docs/openapi.json`

Generated via `spec-versioned.ts` which creates separate registries for each version.

## Version Endpoints

Clients can query version information:

```bash
# Get all versions
GET /api/versions
→ {
    versions: [
      { version: 'v1', status: 'current', ... },
      { version: 'v2', status: 'current', ... }
    ],
    current: 'v2'
  }

# Get v1-specific info
GET /api/v1/versions

# Get v2-specific info
GET /api/v2/versions
```

## Testing

### Unit Tests

- `__tests__/versioning.test.ts` - Middleware and utility tests

```bash
pnpm test versioning.test
```

### Integration Tests

Test both versions handle requests correctly:

```typescript
describe('API Versioning', () => {
  it('v1 and v2 handle workers endpoint', async () => {
    const v1 = await request('/api/v1/workers')
    const v2 = await request('/api/v2/workers')
    expect(v1.body).toBeDefined()
    expect(v2.body).toBeDefined()
  })
})
```

### Compatibility Tests

Verify schema transformations:

```typescript
describe('Schema Versioning', () => {
  it('transforms v1 to v2 worker', () => {
    const v1Worker = { ... }
    const v2Worker = transformResponseData(v1Worker, 'worker', 'v2', 'v1')
    expect(v2Worker.verificationStatus).toBeDefined()
  })
})
```

## Gradual Rollout

### Canary Deployment

Deploy v2 alongside v1:

```
├─ /api/v1/* (100% traffic)
└─ /api/v2/* (0% traffic initially)

Phase 1: 10% to v2
Phase 2: 25% to v2
Phase 3: 50% to v2
Phase 4: 100% to v2
```

### Feature Flags

Use environment variables to toggle versions:

```typescript
const enableV2 = process.env.ENABLE_V2_API === 'true'

if (enableV2) {
  app.use('/api/v2', v2Routes)
}
```

### Monitoring

Track requests per version:

```typescript
// Prometheus metrics
api_requests_total{version="v1"} 15000
api_requests_total{version="v2"} 5000
```

## Deprecation Process

### Timeline for Deprecating v1

**Month 1-12: Current (Announcement + Grace Period)**
- Continue supporting v1
- Send emails about migration
- Deprecation headers on responses
- Documentation updated

**Month 12-13: Final Notice**
- Reduce support (higher response times for v1)
- Send final reminder emails
- Update status page

**Month 13+: Retired**
- Return 410 Gone
- Clients must migrate

### Notification Strategy

1. **Email**: Send to registered integrators
2. **Headers**: Add `Deprecation` and `Sunset` headers
3. **Status Page**: Announce on status.bluecollar.app
4. **Documentation**: Update migration guides

## Best Practices

### For API Maintainers

1. **Backward Compatibility First**
   - Never remove fields, only add
   - Only break on major version bumps
   - Provide 12-month deprecation period

2. **Clear Versioning**
   - Use semantic versioning (v1, v2, v3)
   - Document all changes
   - Provide migration guides

3. **Support Multiple Versions**
   - Keep code DRY with transformers
   - Test all versions with CI
   - Monitor usage per version

4. **Communicate Changes**
   - Announce deprecations 12 months early
   - Provide migration examples
   - Offer support during transition

### For API Clients

1. **Use Current Version**
   - Start with `/api/v2`
   - Don't use unversioned `/api/` (deprecated)

2. **Plan for Deprecation**
   - Monitor `Deprecation` header
   - Build version-agnostic client code
   - Test with multiple versions

3. **Stay Updated**
   - Watch repository for announcements
   - Read migration guides
   - Subscribe to status page

## Related Files

- `middleware/version.ts` - Version detection and routing
- `utils/versioning.ts` - Version utilities
- `utils/schemaVersioning.ts` - Schema transformation
- `middleware/versionRateLimit.ts` - Version-specific rate limiting
- `openapi/spec-versioned.ts` - Versioned OpenAPI specs
- `docs/MIGRATION_GUIDE.md` - Client migration guide
