locals {
  efs_list = flatten([
    for i in range(var.efs_number) : [
      for s in var.subnet_ids : {
        index  = i
        subnet = s
      }
    ]
  ])
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_region" "this" {}

data "aws_caller_identity" "current" {}

##############################
# module and resources
##############################
# create efs security group
resource "aws_security_group" "efs_sg" {
  name_prefix        = "Efs-Security-Group-"
  description = "Efs security group"
  vpc_id      = var.vpc_id

  ingress {
    description      = "nfs access"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = var.efs_volume_tags
}

# create efs file system.
resource "aws_efs_file_system" "storage" {
  count            = var.efs_number
  performance_mode = "generalPurpose"
  tags             = var.efs_volume_tags
  depends_on = [
    aws_security_group.efs_sg
  ]
}

# create mount target for each subnet.
resource "aws_efs_mount_target" "mount_target" {
  count           = length(local.efs_list)
  file_system_id  = aws_efs_file_system.storage[local.efs_list[count.index].index].id
  subnet_id       = local.efs_list[count.index].subnet
  security_groups = [aws_security_group.efs_sg.id]
  depends_on = [
    aws_efs_file_system.storage
  ]
}

# create access point for 777 access
resource "aws_efs_access_point" "default_access_point" {
  count          = var.efs_number
  file_system_id = aws_efs_file_system.storage[count.index].id
  posix_user {
    uid = 1000
    gid = 1000
  }
  root_directory {
    path = "/default"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0777"
    }
  }
  depends_on = [
    aws_efs_mount_target.mount_target
  ]
}

# Deploy CSI driver helm chart
resource "helm_release" "efs-csi" {
  name       = "efs-csi"
  repository = var.csi_chart_repo_url
  chart      = "aws-efs-csi-driver"
  version    = var.csi_chart_version
  namespace  = var.csi_namespace
  values     = length(var.helm_values) > 0 ? var.helm_values : ["${file("${path.module}/helm-values.yaml")}"]
  depends_on = [
    aws_efs_file_system.storage
  ]

  # Set volume tags
  dynamic "set" {
    for_each = var.efs_volume_tags
    content {
      name  = "controller.extraVolumeTags.${set.key}"
      value = set.value
    }
  }

  # Set any extra values provided by the user
  dynamic "set" {
    for_each = var.extra_set_values
    content {
      name  = set.value.name
      value = set.value.value
      type  = set.value.type
    }
  }

  # Set storageclass and file system id.
  # TODO: support multi efs file system.
  # TODO: support multi storageclass.
  set {
    name  = "storageClasses[0].parameters.fileSystemId"
    value = aws_efs_file_system.storage[0].id
  }
  set {
    name  = "storageClasses[0].name"
    value = var.storage_class
  }

  # Set efs-csi service account name and IAM role annotaion
  set {
    name  = "controller.serviceAccount.name"
    value = var.csi_service_account
  }
  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.efs_csi_role.arn
  }
}