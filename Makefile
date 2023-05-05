VERBOSE?=false

all: verify-charts charts

verify-charts:
	@echo Verifying helm charts images in remote registries && \
	arkade chart verify --verbose=$(VERBOSE) -f ./chart/openfaas-oidc-proxy/values.yaml

upgrade-charts:
	@echo Upgrading helm charts images && \
	arkade chart upgrade --verbose=$(VERBOSE) -w -f ./chart/openfaas-oidc-proxy/values.yaml

charts:
	@cd chart && \
		helm package openfaas-oidc-proxy/
	mv chart/*.tgz docs/
	helm repo index docs --url https://self-actuated.github.io/charts/ --merge ./docs/index.yaml
