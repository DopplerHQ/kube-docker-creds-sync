#!/usr/bin/env bash

LATEST_CRONJOB_ID=$(kubectl get jobs --namespace doppler-secrets-sync --no-headers --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.labels.job-name}')
POD_NAME=$(kubectl get pods -l job-name="$LATEST_CRONJOB_ID" --namespace doppler-secrets-sync -o jsonpath='{.items[0].metadata.name}')
kubectl logs --namespace doppler-secrets-sync pods/"$POD_NAME"
