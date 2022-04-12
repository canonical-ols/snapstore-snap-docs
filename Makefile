.PHONY: docs
docs:
	./build.sh

.PHONY: bootstrap
bootstrap:
	sudo snap install documentation-builder
