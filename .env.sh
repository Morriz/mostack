export ISLOCAL=1
export CLUSTERTYPE=docker-for-desktop # minikube
export INGRESS_CLASS=nginx
export HELMOPERATOR_CA=$(cat ./tls/ca.pem)
