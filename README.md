<div align="center" width="100%">
    <h2>hcloud rke2 module</h2>
    <p>Simple and fast creation of a rke2 Kubernetes cluster on Hetzner Cloud.</p>
    <a target="_blank" href="https://github.com/wenzel-felix/terraform-hcloud-rke2/stargazers"><img src="https://img.shields.io/github/stars/wenzel-felix/terraform-hcloud-rke2" /></a>
    <a target="_blank" href="https://github.com/wenzel-felix/terraform-hcloud-rke2/releases"><img src="https://img.shields.io/github/v/release/wenzel-felix/terraform-hcloud-rke2?display_name=tag" /></a>
    <a target="_blank" href="https://github.com/wenzel-felix/terraform-hcloud-rke2/commits/master"><img src="https://img.shields.io/github/last-commit/wenzel-felix/terraform-hcloud-rke2" /></a>
</div>

## ✨ Features

- Create a robust Kubernetes cluster deployed to multiple zones
- Fast and easy to use
- Available as module

## 🤔 Why?

There are existing Kubernetes projects with Terraform on Hetzner Cloud, but they often seem to have a large overhead of code. This project focuses on creating an integrated Kubernetes experience for Hetzner Cloud with high availability and resilience while keeping a small code base. 

## 🔧 Prerequisites

There are no special prerequirements in order to take advantage of this module. Only things required are:
* a Hetzner Cloud account
* access to Terraform

## 🚀 Usage

### Standalone

``` bash
terraform init
terraform apply
```

### As module

Refer to the module registry documentation [here](https://registry.terraform.io/modules/wenzel-felix/rke2/hcloud/latest).
