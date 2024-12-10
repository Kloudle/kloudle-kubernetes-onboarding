#!/bin/bash

# Created by Riyaz Walikar @Kloudle
# Copyright Kloudle Inc. 2024

GREEN='\033[0;32m'
COLOR_OFF='\033[0m'

echo "Kloudle onboarding script for internal Kubernetes clusters"
echo "This script performs the following actions"
echo "- Sets up Tinyproxy to act as a HTTP/HTTPS proxy to reach the cluster"
echo "- Creates readonly resources on the cluster and prints the kubeconfig.yml that needs to be shared with Kloudle"
echo
read -p "Press enter to continue ...."

# Setup Tinyproxy and update configuration

sudo apt update
sudo apt install tinyproxy -y

sudo cp /etc/tinyproxy/tinyproxy.conf /etc/tinyproxy/tinyproxy.conf.old
sudo bash -c 'cat > /etc/tinyproxy/tinyproxy.conf << EOF10
User tinyproxy
Group tinyproxy
Port 8443
Timeout 600
DefaultErrorFile "/usr/share/tinyproxy/default.html"
StatFile "/usr/share/tinyproxy/stats.html"
LogFile "/var/log/tinyproxy/tinyproxy.log"
LogLevel Info
PidFile "/run/tinyproxy/tinyproxy.pid"
MaxClients 100
MinSpareServers 5
MaxSpareServers 20
StartServers 10
MaxRequestsPerChild 0
Allow 127.0.0.1
Allow 34.173.52.204
ViaProxyName "tinyproxy"
EOF10'

sudo service tinyproxy restart

export extip=$(curl -sS https://ipv4.icanhazip.com)
echo -e "${GREEN}Public IP address of the current host is: $extip:8443"

echo -e "Ensure port 8443 is open for this host on the cloud provider firewall to 34.173.52.204 ${COLOR_OFF}"

echo "Done setting up Tinyproxy..."
# export HTTPS_PROXY=THIS-MACHINES-PUBLIC-IP:8443 on the client machine."

# if the kubernetes cluster is only accessible from localhost. DONT RUN THIS. Experimental.
# iptables -t nat -A PREROUTING -p tcp -d 10.1.0.4 --dport 8443 -j DNAT --to 192.168.49.2:8443

echo "Setting up the Kubernetes readonly resources next..."
read -p "Press enter to continue ...."
echo 
echo
# Setup of Kubernetes readonly resources from here
echo -e "${GREEN}Creating a readonly clusterrole called 'kloudle-cluster-reader'${COLOR_OFF}"
# Create a readonly clusterrole
cat <<EOF1 | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
 name: kloudle-cluster-reader
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

echo -e "${GREEN}Creating a clusterrolebinding called 'kloudle-global-cluster-reader' to bind the readonly clusterrole to service account${COLOR_OFF}"
# Create a clusterrolebinding to bind the readonly clusterrole to service account
cat <<EOF2 | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
 name: kloudle-global-cluster-reader
subjects:
- kind: ServiceAccount
  name: kloudle-cluster-admin-readonly
  namespace: default
roleRef:
  kind: ClusterRole
  name: kloudle-cluster-reader
  apiGroup: rbac.authorization.k8s.io
EOF2

echo -e "${GREEN}Adding a service account called 'kloudle-cluster-admin-readonly' to the cluster-admin-readonly clusterrole${COLOR_OFF}"
# Add a service account to the cluster-admin-readonly clusterrole
cat <<EOF3 | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kloudle-cluster-admin-readonly
secrets:
- name: kloudle-cluster-admin-readonly-secret-token
EOF3

echo -e "${GREEN}Creating a secret called 'kloudle-cluster-admin-readonly-secret-token', new in Kubernetes v1.24${COLOR_OFF}"

# Create a secret, new after 1.24
cat <<EOF4 | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kloudle-cluster-admin-readonly-secret-token
  annotations:
    kubernetes.io/service-account.name: kloudle-cluster-admin-readonly
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
export CLUSTER_SA_SECRET_NAME=$(kubectl -n default get sa kloudle-cluster-admin-readonly -o jsonpath='{ $.secrets[0].name }')
export CLUSTER_SA_TOKEN_NAME=$(kubectl -n default get secret | grep --color=never $CLUSTER_SA_SECRET_NAME | awk '{print $1}')
export CLUSTER_SA_TOKEN=$(kubectl -n default get secret $CLUSTER_SA_TOKEN_NAME -o "jsonpath={.data.token}" | base64 -d)
export CLUSTER_SA_CRT=$(kubectl -n default get secret $CLUSTER_SA_TOKEN_NAME -o "jsonpath={.data['ca\.crt']}")

export TERM=$T

cat <<EOF5 > $foldername/kloudle-cluster-admin-readonly-$suffix.yml
apiVersion: v1
kind: Config
users:
- name: kloudle-cluster-admin-readonly-user
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
    user: kloudle-cluster-admin-readonly-user
  name: $CLUSTER_NAME
current-context: $CLUSTER_NAME
EOF5

echo -e "All done! $foldername/kloudle-cluster-admin-readonly-$suffix.yml generated. Upload this file to Kloudle."
