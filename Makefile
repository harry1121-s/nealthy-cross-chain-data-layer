
build:
	@forge build --sizes

test:
	@forge test --match-path tests/DataLayer.t.sol -vvv

clean:
	@forge clean && \
	rm -rf coverage && \
	rm lcov.info

git:
	@git add .
	git commit -m "$m"
	git push

coverage:
	@forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage

deploySource: 
	@forge script script/DeployChainA.s.sol:DeployChainAScript --rpc-url https://api.avax-test.network/ext/bc/C/rpc --broadcast

deployDestination:
	@forge script script/DeployChainB.s.sol:DeployChainBScript --rpc-url https://bsc-testnet.public.blastapi.io --broadcast

configureSource:
	@forge script script/ConfigureChainA.s.sol:ConfigureChainAScript --rpc-url https://api.avax-test.network/ext/bc/C/rpc --broadcast

configureDestination:
	@forge script script/ConfigureChainB.s.sol:ConfigureChainBScript --rpc-url https://bsc-testnet.public.blastapi.io --broadcast

UpdateCounter:
	@forge script script/IncrementCounter.s.sol:IncrementCounterScript --rpc-url https://api.avax-test.network/ext/bc/C/rpc -vvvvv --broadcast
slither:
	@solc-select use 0.8.22 && \
	slither . 

layout:
	@forge inspect $c storage-layout --pretty

.PHONY: install build test debug clean git coverage slither