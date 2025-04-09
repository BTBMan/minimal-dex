-include .env
-include .env.local

# Constants #########################################################
SIMPLE_STORAGE_SCRIPT := contract/script/SimpleStorage.s.sol:SimpleStorageScript

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

deploy-simple-storage:; @forge script $(SIMPLE_STORAGE_SCRIPT) $(NETWORK_ARGS) && esno scripts/generate-abi.ts $(SIMPLE_STORAGE_SCRIPT)

test:; @forge test