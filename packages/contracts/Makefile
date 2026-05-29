# BlueCollar Contracts Makefile
#
# Required env vars for deploy targets:
#   SOURCE          — Stellar secret key or funded account alias
#   ADMIN           — Admin Stellar address
#   FEE_RECIPIENT   — Address that receives protocol fees (market contract)
#   FEE_BPS         — Protocol fee in basis points, default 0

SOURCE        ?= $(error SOURCE is required)
ADMIN         ?= $(error ADMIN is required)
FEE_RECIPIENT ?= $(ADMIN)
FEE_BPS       ?= 0

WASM_DIR := target/wasm32-unknown-unknown/release

.PHONY: build build-registry build-market \
        deploy-testnet deploy-mainnet \
        deploy-registry-testnet deploy-market-testnet \
        deploy-registry-mainnet deploy-market-mainnet \
        clean

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

build: build-registry build-market

build-registry:
	cargo build --release --target wasm32-unknown-unknown --package bluecollar-registry

build-market:
	cargo build --release --target wasm32-unknown-unknown --package bluecollar-market

# ---------------------------------------------------------------------------
# Deploy — testnet
# ---------------------------------------------------------------------------

deploy-testnet: deploy-registry-testnet deploy-market-testnet

deploy-registry-testnet: build-registry
	./scripts/deploy-registry.sh \
	  --network testnet \
	  --source "$(SOURCE)" \
	  --admin "$(ADMIN)"

deploy-market-testnet: build-market
	./scripts/deploy-market.sh \
	  --network testnet \
	  --source "$(SOURCE)" \
	  --admin "$(ADMIN)" \
	  --fee-bps "$(FEE_BPS)" \
	  --fee-recipient "$(FEE_RECIPIENT)"

# ---------------------------------------------------------------------------
# Deploy — mainnet
# ---------------------------------------------------------------------------

deploy-mainnet: deploy-registry-mainnet deploy-market-mainnet

deploy-registry-mainnet: build-registry
	./scripts/deploy-registry.sh \
	  --network mainnet \
	  --source "$(SOURCE)" \
	  --admin "$(ADMIN)"

deploy-market-mainnet: build-market
	./scripts/deploy-market.sh \
	  --network mainnet \
	  --source "$(SOURCE)" \
	  --admin "$(ADMIN)" \
	  --fee-bps "$(FEE_BPS)" \
	  --fee-recipient "$(FEE_RECIPIENT)"

# ---------------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------------

clean:
	cargo clean
