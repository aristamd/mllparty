# Kubernetes cluster deployment and set up

## Requirements

[azure cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

## Deployment

Change the value in aks-deployment.yaml image to use sha of your last commit and run

`az login`

```az aks get-credentials --name vitvioCluster --resource-group shared```

`kubectl apply -f ./deploy_config/aks-deployment.yaml`

## Set up steps

Rough steps for setting up this cluster:
1. create cluster in Azure

```az aks create --resource-group shared --name vitvioCluster --vm-set-type VirtualMachineScaleSets --node-count 2 --location uksouth --load-balancer-sku standard --generate-ssh-keys --attach-acr stagingvitvio``` 

2. get credentials for it

```az aks get-credentials --name vitvioCluster --resource-group shared```

3. assign permissions to the cluster with user managed identity

- create user identity with permissions to pull images from azure registry and networking add-on
- get user identity object id
- assign the user identity to the cluster

`RESOURCE_ID=$(az identity show \\n--name aksAccessIdentity \\n--resource-group shared \\n--query id \\n--output tsv)`

`az aks update \\n--resource-group shared \\n--name vitvioCluster \\n--enable-managed-identity \\n--assign-identity $RESOURCE_ID`

4. Apply manifests

`kubectl apply -f deploy_config/aks-service-deployment.yaml`

`kubectl apply -f ./deploy_config/aks-deployment.yaml`

`kubectl apply -f deploy_config/ingress.yaml`


### Notes

recommended order of applying manifests following [kubernetes configuration best practices](https://kubernetes.io/docs/concepts/configuration/overview/)

aks-service.yaml

aks-deployment.yaml

ingress.yaml