# Kubernetes ReadOnly SA Admin Account Creator

## Introduction

This repo contains shell scripts that create resources within the target cluster that will used to generate a `kubeconfig.yml` that can be shared with the Kloudle team.

The script adds the following Kubernetes resources

1. ClusterRole - `kloudle-cluster-reader`
2. ClusterRoleBinding - `kloudle-global-cluster-reader`
3. Service Account - `kloudle-cluster-admin-readonly`
4. Service Account Secret Token - `kloudle-cluster-admin-readonly-secret-token`

Repo contains two primary scripts

1. A shell script to create readonly resources for a cluster that is reachable over the Internet - [kubernetes-readonly-admin-creator.sh](kubernetes-readonly-admin-creator.sh)
2. A shell script that sets up a Tinyproxy HTTP/HTTPS proxy and then creates readonly resources for a cluster that is internal and not reachable over the Internet - [kubernetes-jumpbox-proxy-readonly-admin-setup.sh](kubernetes-jumpbox-proxy-readonly-admin-setup.sh)

## Pre-requisites

1. A kubernetes administrator or user with the ability to create resources at cluster level, is required to run the shell script as it invokes kubectl with the user credentials.
2. Also ensure your kubeconfig cluster context is set correctly, else the script will create resources in the current context. You can verify this using `kubectl cluster-info`.

## Usage

Depending on whether your cluster is internal or external (private or reachable over the Internet), you can choose the following

### If your cluster is externally accessible / has a public IP address

You can pass the shell script to cURL directly using the raw GitHub URL. The script creates ReadOnly resources in the target cluster.

```bash
curl -sS https://raw.githubusercontent.com/Kloudle/kubernetes-readonly-admin-create/master/kubernetes-readonly-admin-creator.sh | bash
```

Save the `kubeconfig` displayed on screen to a file called `kubeconfig.yml` and share it with Kloudle Team or paste the output in the Kubernetes Onboarding page on the Kloudle App.

### If your cluster is internal / not reachable over the Internet

This is meant to be run on a jumpbox or a machine that can reach the cluster. The script does the following

- installs `Tinyproxy`` and sets up a HTTP/HTTPS proxy
- creates ReadOnly resources in the target cluster

```bash
curl -sS https://raw.githubusercontent.com/Kloudle/kloudle-kubernetes-onboarding/master/kubernetes-jumpbox-proxy-readonly-admin-setup.sh | bash
```

Save the `kubeconfig` displayed on screen to a file called `kubeconfig.yml` and share it with Kloudle Team or paste the output in the Kubernetes Onboarding page on the Kloudle App.
