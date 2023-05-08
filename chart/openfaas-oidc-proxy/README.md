# OpenFaaS OIDC Proxy

Proxy for OpenFaaS for actuated customers.

## Prerequisites

- Purchase a license

  You will need an Actuated License

  Contact us to find out more: [actuated.dev](https://actuated.dev/)

- Install OpenFaaS

  You must have a working OpenFaaS installation.

## Configure your secrets

- Create the required secret with your Actuated license:

```bash
$ kubectl create secret generic \
    -n openfaas \
    actuated-license \
    --from-file license=$HOME/.actuated/LICENSE
```

## Configure ingress

The proxy needs to be accessible from the Internet.

It could be exposed via Ingress, an Istio Gateway, or an [inlets tunnel](https://inlets.dev/).

Install [cert-manager](https://cert-manager.io/docs/), which is used to manage TLS certificates.

You can use Helm, or [arkade](https://github.com/alexellis/arkade):

```bash
arkade install cert-manager
```

Install ingress-nginx using arkade or Helm:

```bash
arkade install ingress-nginx
```

Create an ACME certificate issuer:

```bash
export EMAIL="mail@example.com"

cat > issuer-prod.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-prod
  namespace: openfaas
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

```bash
kubectl apply -f issuer-prod.yaml
```

## Configure values.yaml

```yaml
# The public URL to access the proxy
publicURL: https://oidc-proxy.example.com

# Comma separated list of repository owners for which short-lived OIDC tokens are authorized.
# For example: alexellis,self-actuated
repositoryOwners: 'alexellis,self-actuated'

ingress:
  host: oidc-proxy.example.com
  issuer: letsencrypt-prod
  annotations: {}
```

## Install the chart

- Add the Actuated chart repo and deploy the `openfaas-oidc-proxy` chart. We recommend installing it in the same namespace as the rest of OpenFaaS

```sh
$ helm repo add actuated https://self-actuated.github.io/charts/
$ helm repo update
$ helm upgrade openfaas-oidc-proxy actuated/openfaas-oidc-proxy \
    --install \
    --namespace openfaas \
    -f ./values.yaml
```

> The above command will also update your helm repo to pull in any new releases.

## Install a development version

```sh
$ helm upgrade openfaas-oidc-proxy ./chart/openfaas-oidc-proxy \
    --install \
    --namespace openfaas \
    -f ./values.yaml
```

## Configuration

Additional openfaas-oidc-proxy options in `values.yaml`.

| Parameter             | Description                                                                                 | Default                        |
| --------------------- | ------------------------------------------------------------------------------------------- | ------------------------------ |
| `gatewayURL`          | OpenFaaS gateway URL.                                                                       | `http://gateway.openfaas:8080` |
| `publicURL`           | The public URL to access the proxy.                                                         | `""`                           |
| `repositoryOwners`    | Comma separated list of repository owners for which short-lived OIDC tokens are authorized. | `""`                           |
| `ingress.enabled`     | Enable ingress.                                                                             | `true`                         |
| `ingress.class`       | Ingress class.                                                                              | `nginx`                        |
| `ingress.issuer`      | Name of cert-manager Issuer                                                                 | `letsencrypt-prod`             |
| `ingress.annotations` | Annotations to be added to the ingress resource                                             | `{}`                           |
| `ingress.host`        | Hostname used for the ingress resource                                                      | `""`                           |
| `nodeSelector`        | Node labels for pod assignment.                                                             | `{}`                           |
| `affinity`            | Node affinity for pod assignments.                                                          | `{}`                           |
| `tolerations`         | Node tolerations for pod assignment.                                                        | `[]`                           |
| `logs.debug`          | Print debug logs                                                                            | `false`                        |
| `logs.format`         | The log encoding format. Supported values: `json` or `console`                              | `console`                      |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. See `values.yaml` for the default configuration.

## Removing the openfaas-oidc-proxy

All components can be cleaned up with helm:

```sh
$ helm uninstall -n openfaas openfaas-oidc-proxy
```
