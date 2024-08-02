# Skyward DevOps Challenge Solution

This is the requirements for local development as well the list of changes made.
## Local Development Requirements
 - [Go 1.22 or later](https://go.dev/doc/install)
 - [Dive](https://github.com/wagoodman/dive)
 - [Kind](https://kind.sigs.k8s.io/docs/user/quick-start#installation)
 - [Helm](https://helm.sh/docs/intro/install/)
 - [Docker](https://docs.docker.com/engine/install/)
 - [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
 - A running Kubernetes cluster

### Makefile
There exist a makefile to quickly do common commands such as building, running helm, etc. Please read it for a comprehensive list of 
 
## Changes
Following will be a list of changes i made to the project requirements and structure.

### File structure 
I flatten the folder structure and no longer have challenge 1-3. The root contains the dockerfile and the go code being challenge 1, devops-challenge-chart has the helm chart, and terraform has the terraform manifest files.

