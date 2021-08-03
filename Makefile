SHELL=/bin/bash

setup-test-environment:
	source ./bin/test-environment.sh && setup

teardown-test-environment:
	source ./bin/test-environment.sh && teardown

build:
	docker image build -t dopplerhq/kube-docker-creds-sync .

cronjob:
	kubectl apply -f sample-docker-creds-sync-cronjob.yaml

cronjob-logs:
	@./bin/cronjob-logs.sh

delete:
	kubectl delete -f sample-docker-creds-sync-cronjob.yaml
