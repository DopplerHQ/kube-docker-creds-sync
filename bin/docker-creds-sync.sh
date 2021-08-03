#! /usr/bin/env sh

if [ -z "$DOPPLER_TOKEN_SECRET" ]; then
    echo 'The DOPPLER_TOKEN_SECRET environment variable is required (name of the Kube secret containing the Doppler ''.serviceToken'' secret'
fi

if [ -z "$DOPPLER_TOKEN_NAMESPACE" ]; then
    echo 'The DOPPLER_TOKEN_SECRET_NAMESPACE environment variable is required (namespace the Doppler token secrets belongs to)'
fi

if [ -z "$DOCKER_CREDS_VAR" ]; then
    echo 'The DOCKER_CREDS_VAR environment variable is required (name of the secret containing the Docker credentials in Doppler)'
fi

if [ -z "$DOCKER_CREDS_SECRET" ]; then
    echo 'The DOCKER_CREDS_SECRET environment variable is required (name to give the Docker creds Kube secret)'
fi

if [ -z "$DOCKER_CREDS_NAMESPACE" ]; then
    echo 'The DOCKER_CREDS_NAMESPACE environment variable is required (namespace the Docker creds Kube secret be created in)'
fi

DOPPLER_TOKEN=$(kubectl get secret "$DOPPLER_TOKEN_SECRET" -o jsonpath='{.data.serviceToken}' --namespace "$DOPPLER_TOKEN_NAMESPACE" | base64 -d)
export DOPPLER_TOKEN
DOCKER_CREDS=$(doppler secrets get "$DOCKER_CREDS_VAR" --plain | base64 -w 0)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $DOCKER_CREDS_SECRET
  namespace: $DOCKER_CREDS_NAMESPACE
data:
  .dockerconfigjson: $DOCKER_CREDS
type: kubernetes.io/dockerconfigjson
EOF

echo "Docker credentials successfully synced from Doppler to '$DOCKER_CREDS_SECRET' in $DOCKER_CREDS_NAMESPACE' namespace"
