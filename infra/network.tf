# ============================================================================
# 网络底座：VPC + 共享子网 + 安全组
# ============================================================================
# 「共享子网」是本实践的核心：两个 CCE 集群与两个节点池复用同一个 VPC、
# 同一组子网，从而在 IP 资源紧张时不必为第二个集群另建子网/网段。

resource "huaweicloud_vpc" "main" {
  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "nodes" {
  count = 3

  name       = "${var.project_name}-node-subnet-${count.index}"
  vpc_id     = huaweicloud_vpc.main.id
  cidr       = cidrsubnet(var.vpc_cidr, 8, count.index)
  gateway_ip = cidrhost(cidrsubnet(var.vpc_cidr, 8, count.index), 1)

  availability_zone = "${var.region}${element(["a", "b", "c"], count.index)}"
}

# 两个集群共享同一节点子网（以下取第一个；其余子网用于后续扩容）
locals {
  node_subnet_id = huaweicloud_vpc_subnet.nodes[0].id
}

resource "huaweicloud_networking_secgroup" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for the blue/green demo app"
}

# 放行应用端口 3000（两个集群的 Pod 均经此访问）
resource "huaweicloud_networking_secgroup_rule" "app_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.app.id
}