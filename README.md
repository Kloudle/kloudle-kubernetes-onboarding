# Kubernetes ReadOnly SA Account Creator

## Introduction

This repository contains a bash shell script that creates resources within the target cluster that will used to generate a `kubeconfig.yml` that can be shared with the Kloudle team.

The script adds the following Kubernetes resources

1. A ReadOnly ClusterRole
2. A ClusterRoleBinding for the ClusterRole
3. A Service Account
4. A Secret Token for the Service Account

## Pre-requisites

1. A kubernetes administrator or user with the ability to create resources at cluster level, is required to run the shell script as it invokes kubectl with the user credentials.
2. Also ensure your kubeconfig cluster context is set correctly, else the script will create resources in the current context. You can verify this using `kubectl cluster-info`.

## Usage

You can pass the shell script to curl directly using the raw GitHub URL

```bash
curl -sS https://raw.githubusercontent.com/Kloudle/kloudle-kubernetes-onboarding/master/kubernetes-readonly-admin-creator.sh | sh
```

Share the output with the Kloudle Team or as required, paste the output in the Kubernetes Onboarding page on the Kloudle App.

You can also save the output displayed on screen to a file called `kubeconfig.yml` for local use.
