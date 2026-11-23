# ============================================================================
# 云容器共享子网蓝绿发布 —— Terraform 基础设施
# ============================================================================
# 本目录创建：VPC + 共享子网 → 两个 CCE 集群（共享同一组子网）+ 节点池
#           → 单个共享 ELB（公网入口，两套蓝绿后端）
#
# 蓝/绿应用由 manifests/ 下的 Kubernetes 清单通过 kubectl 部署，
# 两个集群的 LoadBalancer Service 复用同一个 ELB（kubernetes.io/elb.id 注解）。
# ============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.94"
    }
  }

  # 状态文件默认保存在本地；生产环境可迁移到 OBS 桶（backend "s3" + OBS endpoint）
  backend "local" {}
}

provider "huaweicloud" {
  region = var.region
  # 认证凭据经环境变量 HW_ACCESS_KEY / HW_SECRET_KEY 传入（不写入代码）
}