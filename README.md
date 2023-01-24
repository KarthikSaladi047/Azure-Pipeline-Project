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
- The pipeline will include five stages: Terraform, Build & Test React Application, Build & Push Docker Image, Replace Build Id and Deploy.
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
        - main

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


    - stage: Replace Build Id
      jobs:
      - job: Build Id
        steps:
        - script: |
            sed -i "s/<build-id>/$(Build.BuildId)/g" deployment.yaml
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

- The Terraform stage runs terraform commands to initialize and apply a Terraform configuration.

- The Build & Test React Application stage runs npm commands to install dependencies, build the React application and run tests.

- The Build & Push Docker Image stage uses the Docker task to build and push a Docker image of the React application to an Azure Container Registry (ACR).

- The Replace Build Id stage uses a bash script to replace a placeholder in a deployment file with the build id.

- The Deploy stage uses Azure CLI task to get AKS credentials and configure AKS to use a registry, then deploys the application to the AKS cluster using KubernetesManifest task.

## 5. Pipeline Stages:

- 1.Terraform: In this stage, Terraform will be used to provision an AKS cluster and Azure Container Registry in Azure.

    This is Terraform Configuration file(aks.tf).
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
- 2.Build & Test React Application: In this stage, the application is build and tested using NPM.

  ```
  npm install
  npm run build
  npm test
  ```

- 3.Build & Push Docker Image: In this stage, the application will be built and containerized using Docker then the containerized application will be pushed to an Azure Container Registry.
   Here we build a Docker image using the Dockerfile in the repository, and tags the image with myapp:$(Build.BuildId)

  ```
  docker build -t myapp:$(Build.BuildId) .
  docker image tag myapp:$(Build.BuildId) my-registery.azurecr.io/myapp:$(Build.BuildId)
  docker image push my-registery.azurecr.io/myapp:$(Build.BuildId)
  ```
  
- 4.Replace Build Id: In this stage, we execute a script task to replace the placeholder <build-id> in the deployment manifest file with the actual build ID, which is obtained from the $(Build.BuildId) variable.
  
  ```
    sed -i "s/<build-id>/$(Build.BuildId)/g" deployment.yaml
  ```
  
- 5.Deploy: In this stage, the application will be deployed to the AKS cluster using Kubernetes manifests.
  
  The manifest files of the KubernetesManifest task  include all of the necessary configuration files for your React.js application to run on AKS,    such as the deployment file, service file, and ingress file. These files will define the resources and configurations needed for your application to run on AKS, such as the number of replicas, the container image, and the exposed ports.
  
  - k8s/deployment.yaml
  ```
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: react-app
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: react-app
    template:
      metadata:
        labels:
          app: react-app
      spec:
        containers:
          - name: react-app
            image: my-registry.azurecr.io/react-app:<build-id>
            imagePullPolicy: Always
            ports:
              - containerPort: 3000
            env:
              - name: NODE_ENV
                value: "production"
  ```
  
    - k8s/service.yaml
  ```
  apiVersion: v1
  kind: Service
  metadata:
    name: react-app
  spec:
    selector:
      app: react-app
    ports:
    - name: http
      port: 3000
      targetPort: 3000
    type: LoadBalancer
  ```
  
  - k8s/ingress.yaml
  ```
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: react-app
    annotations:
      nginx.ingress.kubernetes.io/rewrite-target: /
  spec:
    rules:
    - host: react-app.example.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: react-app
              port:
                name: http
  ```
## 5. Configuration:
- As we are using Microsoft hosted agent, Azure CLI, Docker and Terraform are pre-installed on the pipeline agent.
- Configure Azure DevOps service connection to your Azure subscription.
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
