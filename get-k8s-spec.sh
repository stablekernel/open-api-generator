#!/usr/bin/env bash

# The k8s spec is too large to check in to github. This will fetch the spec and place it in test/spec

mkdir -p test/specs

curl https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/swagger.json -o test/specs/kubernetes.json

