Create a cluster issuer and two secrets it will rely on. fill with valid values and use kubectl to insert them directly into the cluster. This is a one time operation.


```js
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    email: user@example.com
    privateKeySecretRef:
      name: issuer-account-key
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
    - dns01:
        cloudflare:
          apiKeySecretRef:
            key: api-key
            name: cloudflare-api-key-secret
          email: user@example.com
    - http01:
        ingress:
          ingressClassName: haproxy
---
apiVersion: v1
data:
  tls.key: XYZ1234..........................................==
kind: Secret
metadata:
  name: issuer-account-key
  namespace: cert-manager
type: Opaque
---
apiVersion: v1
data:
  api-key: XYZ1234...==
kind: Secret
metadata:
  name: cloudflare-api-key-secret
  namespace: cert-manager
type: Opaque
```