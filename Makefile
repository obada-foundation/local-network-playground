install: install_contracts install_rd

install_contracts: clone_contracts

clone_contracts:
	git clone git@github.com:obada-foundation/contracts

install_rd: clone_rd

clone_rd:
	git clone git@github.com:obada-foundation/example-client-system
