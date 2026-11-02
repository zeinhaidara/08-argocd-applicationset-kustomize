# ApplicationSet + Kustomize

Hand-copying the same app into dev, stage and prod configs lets the environments
drift apart over time. Each one ends up patched a little differently by hand, and
nobody is quite sure which overlay is "right" anymore. Promoting to prod is a
manual, error-prone sync because there's no single place that defines all three
environments together.

This repo fixes that with one ApplicationSet that generates one Argo CD
Application per environment, each pointing at a Kustomize overlay over a shared
base.

## Flow

```mermaid
flowchart LR
    AS[ApplicationSet] --> A1[Application: web-dev]
    AS --> A2[Application: web-stage]
    AS --> A3[Application: web-prod]
    A1 --> O1[overlays/dev]
    A2 --> O2[overlays/stage]
    A3 --> O3[overlays/prod]
    O1 --> B[base]
    O2 --> B
    O3 --> B
```

## Environments

| environment | replicas | sync mode | cluster placeholder |
|-------------|----------|-----------|----------------------|
| dev         | 1        | auto-sync, prune, self-heal | https://dev.example.com |
| stage       | 2        | auto-sync, prune, self-heal | https://stage.example.com |
| prod        | 3        | manual                      | https://prod.example.com |

## Usage

To add a fourth environment:

1. Add one element to the `elements` list in [applicationset.yaml](applicationset.yaml)
   with its `env`, `clusterURL` and `autosync`.
2. Add a matching `overlays/<env>/` directory with a `kustomization.yaml`, a
   replica patch and an image tag.

That's it — the ApplicationSet picks up the new element and renders the
matching Application.

## Status

Tested with kustomize build, kubeconform and a rendered-output test only. Not
applied to any Argo CD instance.

## Limits

- The ApplicationSet is not run against a real Argo CD.
- Cluster URLs are placeholders.
- Secrets are not handled.
- Sync waves and progressive rollout are not included.
