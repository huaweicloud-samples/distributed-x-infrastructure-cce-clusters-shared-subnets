# ============================================================================
# 容器底座：两个 CCE 集群 + 节点池（共享同一子网）
# ============================================================================
# 「蓝/绿」对应两个独立 Kubernetes 集群：
#   - blue  集群承载当前生产版本
#   - green 集群承载待上线的下一个版本
# 升级时先在 green 集群验证，再把入口流量切过去（端点不变）。

locals {
  clusters = {
    blue  = { color = "blue" }
    green = { color = "green" }
  }
}

# 节点登录密钥对（绕开 provider 在 ARM64 上密码加密的 panic，改用 SSH 密钥登录）
resource "huaweicloud_compute_keypair" "main" {
  name       = "${var.project_name}-cce-keypair"
  public_key = file("${path.module}/cce-keypair.pub")
}

resource "huaweicloud_cce_cluster" "this" {
  for_each = local.clusters

  name                   = "${var.project_name}-${each.key}"
  cluster_type           = "VirtualMachine"
  flavor_id              = "cce.s1.small"
  vpc_id                 = huaweicloud_vpc.main.id
  subnet_id              = local.node_subnet_id
  container_network_type = "overlay_l2"
  authentication_mode    = "rbac"

  # 控制面公网访问，便于本机 kubectl 连接（调试期用；收紧为私网 + 白名单更安全）
  eip = huaweicloud_vpc_eip.cce[each.key].address

  tags = {
    project = var.project_name
    color   = each.value.color
  }
}

# 每个集群一个控制面公网 EIP（与共享 ELB 的 EIP 独立）
resource "huaweicloud_vpc_eip" "cce" {
  for_each = local.clusters

  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.project_name}-${each.key}-cce-bw"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_cce_node_pool" "this" {
  for_each = local.clusters

  cluster_id         = huaweicloud_cce_cluster.this[each.key].id
  name               = "${var.project_name}-${each.key}-nodepool"
  flavor_id          = var.node_flavor
  initial_node_count = var.node_count
  os                 = "Huawei Cloud EulerOS 2.0"
  subnet_id          = local.node_subnet_id
  scall_enable       = false

  # 节点登录：SSH 密钥对（provider 在 arm64 上加密 password 会 panic，故用 key_pair）
  key_pair = huaweicloud_compute_keypair.main.name

  root_volume {
    size       = 40
    volumetype = "SSD"
  }
  data_volumes {
    size       = 100
    volumetype = "SSD"
  }

  tags = {
    project = var.project_name
    color   = each.value.color
  }
}