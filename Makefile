VERSION ?= v0.1.2
CONTROLLER_IMAGE ?= registry.cn-hangzhou.aliyuncs.com/ceerdecy/github-actions-controller
RUNNER_IMAGE ?= registry.cn-hangzhou.aliyuncs.com/ceerdecy/github-actions-runner
CONTROLLER_TEMPLATE ?= github-actions-controller
RUNNER_TEMPLATE ?= github-actions-runner

.PHONY: test build images runner-template controller-template publish-templates
test:
	bash scripts/test-hosted.sh
	go test ./...
	PYTHONPATH=provisioner/ppio python -m pytest -q provisioner/ppio/test_adapter.py
build:
	CGO_ENABLED=0 go build -trimpath -o controller ./cmd/ppio-actions-controller
images:
	CONTROLLER_IMAGE=$(CONTROLLER_IMAGE) RUNNER_IMAGE=$(RUNNER_IMAGE) scripts/release-images.sh $(VERSION)
runner-template:
	ppio template create $(RUNNER_TEMPLATE) --path templates/runner --dockerfile ppio.Dockerfile --cpu-count 2 --memory-mb 4096 --cmd /home/user/actions-runner/entrypoint.sh --ready-cmd 'test -x /home/user/actions-runner/entrypoint.sh'
controller-template:
	ppio template create $(CONTROLLER_TEMPLATE) --path . --dockerfile templates/controller/ppio.Dockerfile --cpu-count 1 --memory-mb 1024 --cmd /usr/local/bin/ppio-actions-controller-entrypoint --ready-cmd 'test -x /usr/local/bin/ppio-actions-controller-entrypoint'
publish-templates:
	ppio template publish $(RUNNER_TEMPLATE) -y
	ppio template publish $(CONTROLLER_TEMPLATE) -y
