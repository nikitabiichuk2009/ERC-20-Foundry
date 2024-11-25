-include .env

.PHONY: all test deploy

all: build

build:
	forge build

test:
	forge test -vvvv

format:
	forge fmt

install:
	forge install openzeppelin/openzeppelin-contracts --no-commit && forge install foundry-rs/forge-std --no-commit

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

deploy:
	@forge script script/DeployOurToken.s.sol:DeployOurToken --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

deploy-sepolia:
	@forge script script/DeployOurToken.s.sol:DeployOurToken --rpc-url $(SEPOLIA_RPC_URL) --account default --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
