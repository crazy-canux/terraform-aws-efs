# terraform-aws-efs


## HowTo

    module "efs_csi" {
        source              = "git::https://github.com/crazy-canux/terraform-aws-efs.git?ref=v1.0.0"
        cluster_name        = local.cluster_name
        csi_namespace       = "kube-system"
        csi_service_account = "efs-csi-controller-sa"
        oidc_issuer         = local.cluster_oidc_issuer_url
        efs_volume_tags     = local.tags
        csi_chart_version   = local.chart_version
        helm_values         = ["${file("${path.module}/helm-values.yaml")}"]
        subnet_ids          = local.subnet_ids
        vpc_id              = local.vpc_id
        depends_on          = [data.terraform_remote_state.eks]
    }