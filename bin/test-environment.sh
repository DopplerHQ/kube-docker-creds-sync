#!/usr/bin/env bash

setup() {
    echo '[info]: Building Docker image'
    docker image build -t dopplerhq/kube-docker-creds-sync .

    echo '[info]: Ensuring required Kubernetes resources are installed'
    kubectl apply -f resources.yaml

    echo '[info]: Creating Doppler project'
    doppler projects create kube-docker-credentials
    doppler setup --project kube-docker-credentials --config dev --no-prompt

    echo '[info]: Creating DOCKER_CREDENTIALS secret'

    cat <<EOF > .dockerconfig.json 
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "3b2591fa-d0fc-423d-b3f8-a15e34253bf7"
        }
    }
}
EOF

    doppler secrets set DOCKER_CREDENTIALS="$(cat .dockerconfig.json)"
    rm .dockerconfig.json

    kubectl create secret generic doppler-token-secret \
        --namespace doppler-secrets-sync \
        --from-literal serviceToken=$(doppler configs tokens create doppler-secrets-sync --plain)
}

teardown() {    
    doppler projects delete kube-docker-credentials -y
    kubectl delete -f resources.yaml
    docker image rm dopplerhq/kube-docker-creds-sync
}
