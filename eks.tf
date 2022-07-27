data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

locals {
  all_vpc_subnets = concat(module.vpc.public_subnets, module.vpc.private_subnets)
}

//noinspection MissingModulelocals,MissingModule
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.5"

  cluster_name              = var.project_name
  cluster_version           = var.cluster_version
  subnet_ids                = local.all_vpc_subnets
  vpc_id                    = module.vpc.vpc_id
  cluster_enabled_log_types = var.cluster_enabled_log_types
  # Self managed node groups will not automatically create the aws-auth configmap so we need to
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]
  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  self_managed_node_group_defaults = {
    create_security_group = false

    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${var.project_name}" : "owned",
    }
  }

  self_managed_node_groups = {
    #Self managed node group with PRIVATE network
    self_mg_4 = {
      node_group_name      = "self-managed-ondemand"
      instance_type        = "m4.large"
      custom_ami_id        = data.aws_ami.eks_default # Bring your own custom AMI generated by Packer/ImageBuilder/Puppet etc.
      capacity_type        = ""                       # Optional Use this only for SPOT capacity as capacity_type = "spot"
      launch_template_os   = "amazonlinux2eks"        # amazonlinux2eks  or bottlerocket or windows
      pre_userdata         = <<-EOT
          yum install -y amazon-ssm-agent \
          systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent \
      EOT
      post_userdata        = ""
      kubelet_extra_args   = ""
      bootstrap_extra_args = ""
      block_device_mapping = [
        {
          device_name = "/dev/xvda" # mount point to /
          volume_type = "gp3"
          volume_size = 20
        }
        /* {
          device_name = "/dev/xvdf" # mount point to /local1 (it could be local2, depending upon the disks are attached during boot)
          volume_type = "gp3"
          volume_size = 50
          iops        = 3000
          throughput  = 125
        },
        {
          device_name = "/dev/xvdg" # mount point to /local2 (it could be local1, depending upon the disks are attached during boot)
          volume_type = "gp3"
          volume_size = 100
          iops        = 3000
          throughput  = 125
        } */
      ]
      enable_monitoring = false
      public_ip         = false # Enable only for public subnets
      # AUTOSCALING
      max_size   = "3"
      min_size   = "1"
      subnet_ids = module.vpc.private_subnets # Mandatory Public or Private Subnet IDs
      additional_tags = {
        ExtraTag    = "m4x-on-demand"
        Name        = "m4x-on-demand"
        subnet_type = "private"
      }
      additional_iam_policies = []
    },
    #Self managed node group with PUBLIC network
    self_mg_4_pub = {
      node_group_name      = "self-managed-ondemand"
      instance_type        = "m4.large"
      custom_ami_id        = data.aws_ami.eks_default # Bring your own custom AMI generated by Packer/ImageBuilder/Puppet etc.
      capacity_type        = ""                       # Optional Use this only for SPOT capacity as capacity_type = "spot"
      launch_template_os   = "amazonlinux2eks"        # amazonlinux2eks  or bottlerocket or windows
      pre_userdata         = <<-EOT
          yum install -y amazon-ssm-agent \
          systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent \
      EOT
      post_userdata        = ""
      kubelet_extra_args   = ""
      bootstrap_extra_args = ""
      block_device_mapping = [
        {
          device_name = "/dev/xvda" # mount point to /
          volume_type = "gp3"
          volume_size = 20
        }
        /* {
          device_name = "/dev/xvdf" # mount point to /local1 (it could be local2, depending upon the disks are attached during boot)
          volume_type = "gp3"
          volume_size = 50
          iops        = 3000
          throughput  = 125
        },
        {
          device_name = "/dev/xvdg" # mount point to /local2 (it could be local1, depending upon the disks are attached during boot)
          volume_type = "gp3"
          volume_size = 100
          iops        = 3000
          throughput  = 125
        } */
      ]
      enable_monitoring = false
      public_ip         = true # Enable only for public subnets
      # AUTOSCALING
      max_size   = "3"
      min_size   = "1"
      subnet_ids = module.vpc.public_subnets # Mandatory Public or Private Subnet IDs
      additional_tags = {
        ExtraTag    = "m4x-on-demand"
        Name        = "m4x-on-demand"
        subnet_type = "public"
      }
      additional_iam_policies = []
    }
  }
}


data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }
}

resource "aws_security_group" "additional" {
  name_prefix = "${var.project_name}-additional"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}