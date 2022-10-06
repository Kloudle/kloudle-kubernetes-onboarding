#!/bin/bash
echo "Kloudle kubernetes onboarding script"
echo "Creates readonly resources and prints the kubeconfig.yml that needs to be shared with Kloudle"
echo 

# Create a readonly clusterrole
cat <<EOF1 | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
 name: cluster-reader
rules:
- apiGroups:
  - ""
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - "*"
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
EOF1

# Create a clusterrolebinding to bind the readonly clusterrole to service account
cat <<EOF2 | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
 name: global-cluster-reader
subjects:
- kind: ServiceAccount
  name: cluster-admin-readonly
  namespace: default
roleRef:
  kind: ClusterRole
  name: cluster-reader
  apiGroup: rbac.authorization.k8s.io
EOF2

# Add a service account to the cluster-admin-readonly clusterrole
cat <<EOF3 | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-admin-readonly
secrets:
- name: cluster-admin-readonly-secret-token
EOF3

# Create a secret, new after 1.24
cat <<EOF4 | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: cluster-admin-readonly-secret-token
  annotations:
    kubernetes.io/service-account.name: cluster-admin-readonly
type: kubernetes.io/service-account-token
EOF4

# Generate config manifest for the cluster
echo 
echo 
export CLUSTER_NAME=$(kubectl config current-context)
export CLUSTER_SERVER=$(kubectl cluster-info | grep --color=never "control plane" | awk '{print $NF}')
export CLUSTER_SA_SECRET_NAME=$(kubectl -n default get sa cluster-admin-readonly -o jsonpath='{ $.secrets[0].name }')
export CLUSTER_SA_TOKEN_NAME=$(kubectl -n default get secret | grep --color=never $CLUSTER_SA_SECRET_NAME | awk '{print $1}')
export CLUSTER_SA_TOKEN=$(kubectl -n default get secret $CLUSTER_SA_TOKEN_NAME -o "jsonpath={.data.token}" | base64 -d)
export CLUSTER_SA_CRT=$(kubectl -n default get secret $CLUSTER_SA_TOKEN_NAME -o "jsonpath={.data['ca\.crt']}")
cat <<EOF5 > /dev/stdout
apiVersion: v1
kind: Config
users:
- name: default
  user:
    token: $CLUSTER_SA_TOKEN
clusters:
- cluster:
    certificate-authority-data: $CLUSTER_SA_CRT
    server: $CLUSTER_SERVER
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    user: default
  name: $CLUSTER_NAME
current-context: $CLUSTER_NAME
EOF5