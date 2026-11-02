#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

dev=$(kustomize build overlays/dev)
stage=$(kustomize build overlays/stage)
prod=$(kustomize build overlays/prod)

echo "$dev" | grep -A1 "^spec:" | grep -q "replicas: 1" && echo "ok: dev has 1 replica"

echo "$stage" | grep -q "replicas: 2" && echo "$prod" | grep -q "replicas: 3" && echo "ok: stage has 2 replicas and prod has 3"

tags=()
for env in dev stage prod; do
  tag=$(grep "newTag:" overlays/$env/kustomization.yaml | sed 's/.*newTag: *"\?\([^"]*\)"\?/\1/')
  kustomize build overlays/$env | grep -q "image: nginx:$tag" || { echo "fail: $env image tag mismatch"; exit 1; }
  tags+=("$tag")
done
[ "${tags[0]}" = "${tags[1]}" ] && [ "${tags[1]}" = "${tags[2]}" ] && echo "ok: dev, stage and prod all use the same image tag"

[ "$(grep -c '^ *- env: ' applicationset.yaml)" -eq 3 ] && echo "ok: applicationset has exactly 3 list elements"

grep -A2 "env: prod" applicationset.yaml | grep -q 'autosync: "false"' && echo "ok: prod element has autosync false"
