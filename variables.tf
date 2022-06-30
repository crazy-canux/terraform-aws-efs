variable "cluster_name" {
  description = "k8s cluster name"
  type        = string
}

variable "oidc_issuer" {
  description = "OIDC provider, leave in blank for EKS clusters"
  type        = string
  default     = null
}

variable "csi_namespace" {
  description = "EFS CSI namespace"
  type        = string
  default     = "kube-system"
}

variable "csi_service_account" {
  description = "Service account to be created for use with the CSI driver"
  type        = string
  default     = "efs-csi-controller-sa"
}

variable "csi_chart_repo_url" {
  description = "URL to repository containing the EBS CSI helm chart"
  type        = string
  default     = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
}

variable "csi_chart_version" {
  description = "EFS CSI helm chart version"
  type        = string
  default     = "2.2.7"
}

variable "efs_volume_tags" {
  description = "Tags for EFS volumes dynamically created by the CSI driver"
  type        = map(string)
  default     = {}
}

variable "helm_values" {
  description = "Values for external-dns Helm chart in raw YAML."
  type        = list(string)
  default     = []
}

variable "extra_set_values" {
  description = "Specific values to override in the external-dns Helm chart (overrides corresponding values in the helm-value.yaml file within the module)"
  type = list(object({
    name  = string
    value = any
    type  = string
    })
  )
  default = []
}

variable "efs_number" {
  type        = number
  description = "efs file system number"
  default     = 1
}

variable "subnet_ids" {
  type        = list(string)
  description = "subnet ids"
}

variable "vpc_id" {
  type        = string
  description = "vpc id"
}

variable "storage_class" {
  type        = string
  description = "storage class name"
  default     = "efs-sc"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "private subnet cidrs in vpc."
}