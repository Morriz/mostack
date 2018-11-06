apiVersion: v1
kind: ServiceAccount
metadata:
  name: drone-deploy
  namespace: team-frontend
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: drone-deploy
  namespace: team-frontend
rules:
  - apiGroups: ["extensions"]
    resources: ["deployments"]
    verbs: ["get","list","patch","update"]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: drone-deploy
  namespace: team-frontend
subjects:
  - kind: ServiceAccount
    name: drone-deploy
    namespace: team-frontend
roleRef:
  kind: Role
  name: drone-deploy
  apiGroup: rbac.authorization.k8s.io
