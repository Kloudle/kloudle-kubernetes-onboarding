# Kubernetes ReadOnly SA Admin Account Creator

## Introduction

This repo contains a bash shell script that creates resources within the target cluster that will used to generate a `kubeconfig.yml` that can be shared with the Kloudle team.

The script adds the following Kubernetes resources

1. ClusterRole
2. ClusterRoleBinding
3. Service Account
4. Service Account Secret Token

## Pre-requisites

1. A kubernetes administrator or user with the ability to create resources at cluster level, is required to run the shell script as it invokes kubectl with the user credentials.
2. Also ensure your kubeconfig cluster context is set correctly, else the script will create resources in the current context. You can verify this using `kubectl cluster-info`.

## Usage

You can pass the shell script to curl directly using the raw GitHub URL

```
curl -sS https://raw.githubusercontent.com/Kloudle/kubernetes-readonly-admin-create/main/kubernetes-readonly-admin-creator.sh | sh
```

Save the `kubeconfig` displayed on screen to a file called `kubeconfig.yml` and share it with Kloudle Team or paste the output in the Kubernetes Onboarding page on the Kloudle App.
