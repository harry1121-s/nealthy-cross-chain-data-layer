
build:
	@forge build --sizes

test:
	@forge test

debug: 
	@forge test -vvvvv

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

slither:
	@solc-select use 0.8.21 && \
	slither . 

layout:
	@forge inspect $c storage-layout --pretty

.PHONY: install build test debug clean git coverage slither