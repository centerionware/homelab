Create a secret or externalsecret for ceph..
```js
apiVersion: v1
kind: Secret
metadata:
  name: csi-cephfs-secret
  namespace: ceph-csi
stringData:
  # Admin or provisioner identity with capabilities to create subvolumes.
  adminID: CEPH_USER          # e.g. kubernetes
  adminKey: CEPH_KEY          # e.g. AQB...==
  # Optional user credentials for mounting (if different from admin)
  userID: CEPH_USER
  userKey: CEPH_KEY
```