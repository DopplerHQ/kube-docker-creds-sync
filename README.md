# Doppler Kubernetes Docker Credentials Sync

Experiment using a CronJob to continously sync Docker registry credentials from Doppler to the Kubernetes secret of type ``kubernetes.io/dockerconfigjson`.

## Install

As this is an experiment, you'll need to manually build the image to make it available to your cluster:

```sh
docker image build -t dopplerhq/kube-docker-creds-sync .
```

Then install the required resources in your cluster:

```sh
kubectl apply -f resources.yaml
```

## Configure

Next, create a Kubernetes secret for the Doppler Service Token that provides access to the Doppler Project and Config containing the Docker credentials.

Presuming you're performing this action from your machine which has a Doppler CLI token and therefore, has write access to the Doppler Project and Config:

```sh
 # Select the Project and Config that contains the Docker registry credentials
doppler setup

# Create the Kubernetes secert
kubectl create secret generic doppler-token-secret \
    --namespace doppler-secrets-sync \
    --from-literal serviceToken=$(doppler configs tokens create doppler-secrets-sync --plain)
```

## Sync

Setting up a sync simply requires adding a `CronJob` configured to use the `dopplerhq/kube-docker-creds-sync` image.

The below example taken from [sample-docker-creds-sync-cronjob.yaml](sample-docker-creds-sync-cronjob.yaml) demonstrates how to set up a sync every 5 minutes with environment variables used to configure the [bin/docker-creds-sync.sh] script.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: doppler-docker-creds-sync
  namespace: doppler-secrets-sync
  labels:
    doppler-sync: docker-creds-cronjob
spec:
  schedule: '*/5 * * * *'
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            doppler-sync: docker-creds-cronjob
        spec:
          containers:
          - name: doppler-docker-creds-sync            
            image: dopplerhq/kube-docker-creds-sync
            imagePullPolicy: IfNotPresent
            args:
              - './bin/docker-creds-sync'
            env:
              - name: DOPPLER_TOKEN_SECRET # Doppler Token Kubernetes secret ('.serviceToken')
                value: doppler-token-secret

              - name: DOPPLER_TOKEN_NAMESPACE # Doppler Token Kubernetes secret namespace
                value: doppler-secrets-sync

              - name: DOCKER_CREDS_VAR # Name of secret containing registry credentials in Doppler
                value: DOCKER_CREDENTIALS

              - name: DOCKER_CREDS_SECRET # Name of Kubernetes secret to create
                value: doppler-synced-docker-credentials

              - name: DOCKER_CREDS_NAMESPACE # Namespace that Kubernetes secret will be created in
                value: default

          restartPolicy: Never
          terminationGracePeriodSeconds: 0
          serviceAccountName: doppler-secrets-sync-service-account
```

## Testing

You can set up a test environment by running the following (presumes a `default` namespace exists):

1. Build image, create Kubernetes resources, create a test Doppler project with a DOPPLER_CREDENTIALS secret

```sh
source ./bin/test-environment.sh && setup
```

2. Create CronJob:

```sh
kubectl apply -f sample-docker-creds-sync-cronjob.yaml
```

3. Wait 1 minute, then get CronJob logs to confirm Docker creds secret was created successfully:

```sh
./bin/cronjob-logs.sh
```

4. Verify secret conents matches what's in Doppler:

```sh
kubectl get secret doppler-synced-docker-credentials -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
```

5. Open Doppler dashboard and alter value auth `auth` in `DOPPLER_CREDENTIALS` secret:

```sh
doppler open dashboard
```

6. Wait 1 minute, then verify Docker credentials secret has been updated by the CronJob:

```sh
kubectl get secret doppler-synced-docker-credentials -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
```

7. Cleanup test environment resources

```sh
source ./bin/test-environment.sh && teardown
```
