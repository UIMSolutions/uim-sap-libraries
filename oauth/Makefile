PLANTUML ?= plantuml
UML_DIR ?= docs/uml
UML_FILES := $(wildcard $(UML_DIR)/*.puml)

IMAGE_NAME ?= ghcr.io/uimsolutions/uim-sap-oau
IMAGE_TAG  ?= latest

.PHONY: build run test clean container-build container-run uml uml-check uml-png uml-svg uml-clean

build:
	cd .. && dub build --config=default -- oauth

run:
	cd .. && dub run -- oauth

test:
	cd .. && dub test -- oauth

clean:
	rm -rf build/

container-build:
	podman build -t $(IMAGE_NAME):$(IMAGE_TAG) .

container-run:
	podman run --rm -p 8090:8090 \
		-e OAU_HOST=0.0.0.0 \
		-e OAU_PORT=8090 \
		-e OAU_BASE_PATH=/api/oau \
		-e OAU_ISSUER=uim-oau \
		$(IMAGE_NAME):$(IMAGE_TAG)
