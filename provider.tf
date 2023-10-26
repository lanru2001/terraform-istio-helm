######################################################################################
#Helm Provider
######################################################################################

#Some cloud providers have short-lived authentication tokens that can expire relatively quickly. 
#To ensure the Kubernetes provider is receiving valid credentials, an exec-based plugin can be used to fetch a new token before initializing the provider.

# S3 remote state 
terraform {
  backend "s3" {
    bucket         = "dlframe-test-9"
    key            = "project/DLFrame/istio"
    region         = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.12"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.23.0"
    }

    helm = {
      source = "hashicorp/helm"
      version = "2.11.0"
    }
  }
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.certificate_authority)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.certificate_authority)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}
