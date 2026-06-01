# Cost Optimization

## Current resource audit

| Resource | Type | Monthly estimate |
|---|---|---|
| RDS (prod) | db.t3.medium Multi-AZ | ~$70 |
| RDS (staging) | db.t3.micro | ~$15 |
| ECS Fargate | 0.25 vCPU / 0.5 GB × 2 tasks | ~$20 |
| CloudFront + S3 | CDN + assets | ~$5 |
| ECR | Image storage | ~$2 |
| **Total** | | **~$112/month** |

## Auto-scaling policies

Managed by `deploy/terraform/modules/autoscaling/`:

- ECS scales out when CPU > 60% or memory > 70% (60s cooldown)
- ECS scales in when utilisation drops (300s cooldown to avoid flapping)
- Staging/non-prod scales to **zero** at 22:00 UTC and back up at 06:00 UTC — saves ~65% of compute cost outside business hours

## Database sizing

- Production: `db.t3.medium` with Multi-AZ — right-sized for current load
- Staging: `db.t3.micro` — sufficient for testing
- Enable RDS Performance Insights (free tier) to identify slow queries before upsizing

## Cost alerts

Managed by `deploy/terraform/modules/cost-alerts/`:

| Alert | Threshold |
|---|---|
| Actual spend > 80% of monthly budget | Email notification |
| Forecasted spend > 100% of monthly budget | Email notification |
| RDS CPU > 80% for 10 minutes | SNS → email |

Default monthly budget: **$500** (configurable via `monthly_budget_usd` variable).

## Additional strategies

- Use **Savings Plans** for predictable ECS Fargate workloads (up to 66% discount).
- Enable **S3 Intelligent-Tiering** for assets older than 30 days.
- Set **CloudWatch log retention** to 30 days (already configured in CDN module).
- Review **ECR lifecycle policy** — untagged images deleted after 1 day.
- Use **Spot instances** for non-critical batch jobs (seed, migration tests).
