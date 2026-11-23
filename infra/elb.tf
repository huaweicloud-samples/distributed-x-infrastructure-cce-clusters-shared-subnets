# ============================================================================
# 共享 ELB：两个集群共用的统一公网入口
# ============================================================================
# 共享 ELB：一个负载均衡器承载蓝/绿两个集群的流量，作为统一公网入口。
# 普通应用型（L7）独享负载均衡：不设 loadbalancer_type，可直接绑定 EIP。
# 注意：CCE 的 LoadBalancer Service 在 overlay_l2 网络下走 L4 转发（ELB→节点 NodePort），
# 因此需同时指定 l4_flavor_id + l7_flavor_id（L4+L7 双栈），否则报 "flavor is not support L4"。

resource "huaweicloud_elb_loadbalancer" "shared" {
  name              = "${var.project_name}-shared-elb"
  vpc_id            = huaweicloud_vpc.main.id
  availability_zone = [var.elb_az]

  # VIP 所在子网（ELB 需 neutron 子网 ID，非 VPC v3 的 id）
  ipv4_subnet_id = huaweicloud_vpc_subnet.nodes[0].subnet_id

  # 固定小规格（L4 转发 + L7 应用），按名称精确选取避免下标歧义
  l4_flavor_id = local.l4_flavor_id
  l7_flavor_id = local.l7_flavor_id

  # 直接绑定 EIP（独享型 ELB 的公网入口）
  ipv4_eip_id = huaweicloud_vpc_eip.elb.id

  tags = {
    project = var.project_name
  }
}

data "huaweicloud_elb_flavors" "l4" {
  type = "L4"
}

data "huaweicloud_elb_flavors" "l7" {
  type = "L7"
}

locals {
  l4_flavor_id = [
    for f in data.huaweicloud_elb_flavors.l4.flavors : f.id
    if f.name == "L4_flavor.elb.s1.small"
  ][0]
  l7_flavor_id = [
    for f in data.huaweicloud_elb_flavors.l7.flavors : f.id
    if f.name == "L7_flavor.elb.s1.small"
  ][0]
}

# 独享型 ELB 的公网 EIP
resource "huaweicloud_vpc_eip" "elb" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.project_name}-elb-bw"
    size        = var.elb_bandwidth
    share_type  = "PER"
    charge_mode = "traffic"
  }
}