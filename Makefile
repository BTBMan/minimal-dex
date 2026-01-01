-include .env
-include .env.local

# Constants #########################################################
SWAP_ROUTER_SCRIPT := contract/script/SwapRouter.s.sol:SwapRouterScript
NONFUNGIBLE_POSITION_MANAGER_SCRIPT := contract/script/NonfungiblePositionManager.s.sol:NonfungiblePositionManagerScript

NETWORK_ARGS :=

# Conditions #######################################################
# E.g: make xxx network=local
ifeq ($(findstring local,$(network)),local)
	NETWORK_ARGS := --rpc-url $(LOCAL_RPC_URL) --private-key $(LOCAL_PRIVATE_KEY) --broadcast -vvvv
endif

# E.g: make xxx network=sepolia
ifeq ($(findstring sepolia,$(network)),sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(TEST_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

# Aliases ###########################################################
build:; forge build

deploy-swap-router:; @forge script $(SWAP_ROUTER_SCRIPT) $(NETWORK_ARGS) && esno scripts/generate-abi.ts $(SWAP_ROUTER_SCRIPT)
deploy-nonfungible-position-manager:; @forge script $(NONFUNGIBLE_POSITION_MANAGER_SCRIPT) $(NETWORK_ARGS) && esno scripts/generate-abi.ts $(NONFUNGIBLE_POSITION_MANAGER_SCRIPT)

test:; @forge test