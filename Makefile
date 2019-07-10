.PHONY: help
help:
	@echo "Targets:"
	@echo "  docker       -- try to build the docker container"
	@echo "  lint         -- run the linter"

.PHONY: docker
docker:
	docker build . -f Dockerfile

.PHONY: lint
lint:
	golint -set_exit_status smart_exporter.go
	go vet smart_exporter.go
