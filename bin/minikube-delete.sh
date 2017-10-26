#!/usr/bin/env bash

# delete minikube cluster
killall kubectl
sudo killall ssh
minikube delete
