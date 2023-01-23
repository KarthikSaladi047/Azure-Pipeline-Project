# automation using Azure Pipeline

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

- The pipeline will be triggered by a push to the `main` branch in GitHub.
- The pipeline will include four stages: Terraform, Build, Push, and Deploy.
- Terraform will be used to provision an AKS cluster in Azure.
- The application will be built and containerized using Docker.
- The containerized application will be pushed to an Azure Container Registry.
- The application will be deployed to the AKS cluster using Kubernetes manifests.

## 4. Pipeline Stages:

- Terraform: In this stage, Terraform will be used to provision an AKS cluster in Azure.
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

## 6. Monitoring and troubleshooting:
- Monitor pipeline run and job logs in Azure DevOps.
- Monitor pipeline run and job status in GitHub.
- Monitor the AKS cluster and application logs using Azure Monitor.

## Summary
This pipeline project has successfully implemented a CI/CD pipeline for a React JS application using Azure DevOps, Terraform, Docker and Kubernetes. The pipeline automates the building, testing, and deployment of the application to a Kubernetes cluster provisioned in Azure using Terraform. By implementing this pipeline, the development team can now focus on delivering new features and improvements, while the pipeline ensures that the application is always up-to-date and ready for production.

## References:
Azure DevOps documentation: https://docs.microsoft.com/en-us/azure/devops/
Terraform documentation: https://www.terraform.io/docs/
Docker documentation: https://docs.docker.com/
Kubernetes documentation: https://kubernetes.io/docs/
