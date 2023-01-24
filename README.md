# Automation using Azure Pipeline

## 1. Introduction:

The purpose of this project is to implement a continuous integration/continuous delivery (CI/CD) pipeline for a React JS application using Azure DevOps, Terraform, Docker and Kubernetes. The pipeline will automate the building, testing, and deployment of the application to a Kubernetes cluster provisioned in Azure using Terraform.

## 2. Project scope:

This project includes the following technologies and tools:
- Azure DevOps for pipeline management and automation.
- Terraform for provisioning resources in Azure.
- Docker for containerizing the application.
- Kubernetes for deploying and scaling the application.

The project will be deployed in an Azure Kubernetes Service (AKS) cluster.

## 3. Architecture:
![Developers](https://user-images.githubusercontent.com/105864615/214238240-1cc1fbec-9075-4a9d-ab99-2624e477d58e.jpg)
- The pipeline will be triggered by a push to the `main` branch in GitHub.
- The pipeline will include five stages: Terraform, Build & Test React Application, Build & Push Docker Image, Get, Set & Replace Build Id and Deploy.
- Terraform will be used to provision an AKS cluster in Azure.
- NPM is used to build and test application
- The application will be built and containerized using Docker.
- The containerized application will be pushed to an Azure Container Registry.
- The application will be deployed to the AKS cluster using Kubernetes manifests.
## 4. Pipeline Code

- This is the azure-pipeline.yaml file.

```
trigger:
  branches:
    include:
    - master

resources:
  repositories:
    - repository: self
      type: github
      name: KarthikSaladi047/Azure-Pipeline-Project
      connection: github-connection

pool:
  vmImage: 'ubuntu-latest'

variables:
  - name: 'ACR_NAME'
    value: $(ACR_NAME)
  - name: 'AKS_CLUSTER_NAME'
    value: $(aksName)
  - name: 'RESOURCE_GROUP'
    value: $(resourceGroup)

  buildId: ''

stages:
- stage: Terraform
  displayName: Terraform
  jobs:
  - job: Terraform
    displayName: Terraform
    steps:
    - task: TerraformInstaller@0
      displayName: 'Install Terraform'
      inputs:
        terraformVersion: '0.14.x'

    - script: terraform init
      displayName: 'Terraform Init'

    - script: terraform apply -auto-approve
      displayName: 'Terraform Apply'
      
- stage: Build & Test React Application
  displayName: Build & Test
    jobs:
    -  job: Build and Test
       displayName: Build and Test
       steps:
       - script: |
            npm install
            npm run build
         displayName: 'Build React App'
         
       - script: npm test
         displayName: 'Test React App'
            

- stage: Build & Push Docker Image
  displayName: Build & Push
  jobs:
  - job: Build
    displayName: Build
    steps:
    - task: Docker@2
      displayName: 'Build an image'
      inputs:
        command: build
        containerRegistry: $(ACR_NAME)
        tags: |
          react-app:$(Build.BuildId)
        Dockerfile: '**/Dockerfile'

    - task: AzureCLI@2
      displayName: 'Login to ACR'
      inputs:
        azureSubscription: 'azure-connection'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az acr login --name $(ACR_NAME)

    - task: Docker@2
      displayName: 'Push an image'
      inputs:
        command: push
        containerRegistry: $(ACR_NAME)
        tags: |
          react-app:$(Build.BuildId)


- stage: Get, Set & Replace Build Id
  jobs:
  - job: Get & Set Build Id
    steps:
    - script: echo "##vso[build.updatebuildnumber]$(date +%s)"
      name: GetBuildId

    - script: echo "##vso[task.setvariable variable=buildId]$(Build.BuildId)"
      name: SetBuildId

    - script: |
        sed -i "s/<build-id>/$(buildId)/g" deployment.yaml
      name: ReplaceBuildId
 
- stage: Deploy
  displayName: Deploy
  jobs:
  - job: Deploy
    displayName: Deploy
    steps:
    - task: AzureCLI@2
      displayName: 'Get AKS Credentials'
      inputs:
        azureSubscription: 'Azure-connection'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az aks get-credentials -g $(RESOURCE_GROUP) -n $(AKS_CLUSTER_NAME)

    - script: |
        az aks update -g $(RESOURCE_GROUP) -n $(AKS_CLUSTER_NAME) --attach-acr my-registry
      displayName: 'Configure AKS to use my-registry'

    - task: KubernetesManifest@0
      displayName: 'Deploy to AKS'
      inputs:
        command: 'apply'
        manifests: |
          k8s/*

```

## 5. Pipeline Stages:

- Terraform: In this stage, Terraform will be used to provision an AKS cluster and Azure Container Registry in Azure.

This is aks.tf file.
```
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.40.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
}

//creating Azure Kubernetes service
resource "azurerm_resource_group" "aks" {
  name     = "my-aks-rg"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "my-aks-cluster"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "my-aks-cluster"
  
  kubernetes_version = "1.19.7"
  
  role_based_access_control {
    enabled = true
  }
}

// creating Azure container registry
resource "azurerm_resource_group" "container_rg" {
  name     = "acr-rg"
  location = "East US"
}

resource "azurerm_container_registry" "acr" {
  name                = "my-registry"
  resource_group_name = azurerm_resource_group.container_rg.name
  location            = azurerm_resource_group.container_rg.location
  sku                 = "Premium"
  admin_enabled       = false
  georeplications {
    location                = "West Europe"
    zone_redundancy_enabled = true
    tags                    = {}
  }
  georeplications {
    location                = "North Europe"
    zone_redundancy_enabled = true
    tags                    = {}
  }
}
```
- Build: In this stage, the application will be built and containerized using Docker.
- Push: In this stage, the containerized application will be pushed to an Azure Container Registry.
- Deploy: In this stage, the application will be deployed to the AKS cluster using Kubernetes manifests.

## 5. Configuration:

- Install Azure CLI and Terraform on the pipeline agent.
- Configure Azure DevOps service connection to your Azure subscription.
- Create an Azure Container Registry and configure the pipeline to use it.
- Configure pipeline variables for Terraform, Docker and Kubernetes tasks.
- Store sensitive data like passwords and secrets in Azure DevOps secure variables.
- Link your GitHub repository to your Azure DevOps organization and configure a webhook.

## 7. Monitoring and troubleshooting:
- Monitor pipeline run and job logs in Azure DevOps.
- Monitor pipeline run and job status in GitHub.
- Monitor the AKS cluster and application logs using Azure Monitor.

## Summary
This pipeline project has successfully implemented a CI/CD pipeline for a React JS application using Azure DevOps, Terraform, Docker and Kubernetes. The pipeline automates the building, testing, and deployment of the application to a Kubernetes cluster provisioned in Azure using Terraform. By implementing this pipeline, the development team can now focus on delivering new features and improvements, while the pipeline ensures that the application is always up-to-date and ready for production.

## References:
- Azure DevOps documentation: https://docs.microsoft.com/en-us/azure/devops/
- Terraform documentation: https://www.terraform.io/docs/
- Docker documentation: https://docs.docker.com/
- Kubernetes documentation: https://kubernetes.io/docs/
