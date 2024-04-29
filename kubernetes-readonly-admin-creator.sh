#!/bin/bash

# Created by Riyaz Walikar @Kloudle
# Copyright Kloudle Inc. 2024
# Usage post: https://kloudle.com/blog/how-to-onboard-kubernetes-to-kloudle

GREEN='\033[0;32m'
COLOR_OFF='\033[0m'

echo "Kloudle kubernetes onboarding script"
echo "Creates readonly resources and prints the kubeconfig.yml that needs to be shared with Kloudle"
echo
read -p "Press enter to continue ...."
# Setup of Kubernetes readonly resources from here
echo -e "${GREEN}Create a readonly clusterrole${COLOR_OFF}"
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

echo -e "${GREEN}Create a clusterrolebinding to bind the readonly clusterrole to service account${COLOR_OFF}"
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

echo -e "${GREEN}Add a service account to the cluster-admin-readonly clusterrole${COLOR_OFF}"
# Add a service account to the cluster-admin-readonly clusterrole
cat <<EOF3 | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-admin-readonly
secrets:
- name: cluster-admin-readonly-secret-token
EOF3

echo -e "${GREEN}Create a secret, new after 1.24${COLOR_OFF}"

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
export foldername="k8s-kloudle-onboarding-kubeconfigs"
if [ ! -d "$foldername" ]; then
  mkdir $foldername
fi
export suffix="$(date +%d-%m-%Y-%H-%M-%S)"

echo -e "${GREEN}Generating kubeconfig in folder $foldername ${COLOR_OFF}"

export T=$TERM
export TERM=dumb

export CLUSTER_NAME=$(kubectl config current-context)
export CLUSTER_SERVER=$(kubectl cluster-info | grep --color=never "control plane" | awk '{print $NF}')
export CLUSTER_SA_SECRET_NAME=$(kubectl -n default get sa cluster-admin-readonly -o jsonpath='{ $.secrets[0].name }')
export CLUSTER_SA_TOKEN_NAME=$(kubectl -n default get secret | grep --color=never $CLUSTER_SA_SECRET_NAME | awk '{print $1}')
export CLUSTER_SA_TOKEN=$(kubectl -n default get secret $CLUSTER_SA_TOKEN_NAME -o "jsonpath={.data.token}" | base64 -d)
export CLUSTER_SA_CRT=$(kubectl -n default get secret $CLUSTER_SA_TOKEN_NAME -o "jsonpath={.data['ca\.crt']}")

export TERM=$T

cat <<EOF5 > $foldername/kloudle-cluster-admin-readonly-$suffix.yml
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