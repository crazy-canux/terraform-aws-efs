locals {
  oidc_provider = trimprefix(var.oidc_issuer, "https://")
}

# Trust policy to enable IRSA
data "aws_iam_policy_document" "irsa_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values = [
        "system:serviceaccount:${var.csi_namespace}:${var.csi_service_account}"
      ]
    }
  }
}

# Policy Document for IAM policy.
# Retrieved from https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/v1.4.0/docs/example-iam-policy.json
data "aws_iam_policy_document" "efs_csi_policy_document" {
  # The role created with this policy is to be assumed by the pod via IRSA
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}


# Create IAM policy
resource "aws_iam_role_policy" "efs_csi_policy" {
  role   = aws_iam_role.efs_csi_role.name
  policy = data.aws_iam_policy_document.efs_csi_policy_document.json
}

# Create IAM role to be used by CSI driver pods with the trust policy
resource "aws_iam_role" "efs_csi_role" {
  name_prefix          = "Proj-efs-csi-"
  description          = "Role to enable csi-driver pods to manage EFS resources via IRSA in EKS cluster ${var.cluster_name}"
  permissions_boundary = "arn:aws:iam::aws:policy/PowerUserAccess"
  assume_role_policy   = data.aws_iam_policy_document.irsa_trust_policy.json
}