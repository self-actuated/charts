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

The proxy needs to be accessible from
To receive http calls from AWS SNS the callback url has to be publicly accessible.

The below instructions show how to set up Ingress with a TLS certificate using Ingress Nginx. You can also use any other ingress-controller, inlets-pro or an Istio Gateway. Reach out to us if you need a hand.

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

Create an ingress record for the openfaas-oidc-proxy:

```bash
export DOMAIN="gateway.example.com"

cat > ingress.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: openfaas-oidc-proxy
  namespace: openfaas
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/issuer: letsencrypt-prod
  labels:
    app: openfaas-oidc-proxy
spec:
  tls:
  - hosts:
    - $DOMAIN
    secretName: openfaas-oidc-proxy-cert
  rules:
  - host: $DOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: openfaas-oidc-proxy
            port:
              number: 8080
EOF
```

Apply the Ingress resource:

```bash
kubectl apply -f ingress.yaml
```

## Configure values.yaml

```yaml
# OpenFaaS gateway URL
gatewayURL: http://gateway.openfaas:8080

# The public URL to access the proxy
publicURL: gateway.example.com

# Comma separated list of repository owners for which short-lived OIDC tokens are authorized.
# For example: openfaasltd,self-actuated
repositoryOwners: 'openfaasltd,self-actuated'
```

## Install the chart

- Add the Actuated chart repo and deploy the `openfaas-oidc-proxy` chart. We recommend installing it in the same namespace as the rest of OpenFaaS

```sh
$ helm repo add actuated https://self-actuated.github.io/charts
$ helm upgrade openfaas-oidc-proxy actuated/openfaas-oidc-proxy \
    --install \
    --namespace openfaas
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

| Parameter          | Description                                                                                 | Default                        |
| ------------------ | ------------------------------------------------------------------------------------------- | ------------------------------ |
| `gatewayURL`       | OpenFaaS gateway URL.                                                                       | `http://gateway.openfaas:8080` |
| `publicURL`        | The public URL to access the proxy.                                                         | `""`                           |
| `repositoryOwners` | Comma separated list of repository owners for which short-lived OIDC tokens are authorized. | `""`                           |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. See `values.yaml` for the default configuration.

## Removing the openfaas-oidc-proxy

All components can be cleaned up with helm:

```sh
$ helm uninstall -n openfaas openfaas-oidc-proxy
```
