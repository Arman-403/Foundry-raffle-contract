
-include .env

.PHONY: test
TEST ?=

test: 
	@forge test $(if $(TEST), --mt $(TEST)) -vvvv

fmt :; forge fmt
	
deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account myaccount --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-local:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --private-key $(PRIVATE_KEY) --rpc-url $(RPC_URL) --broadcast