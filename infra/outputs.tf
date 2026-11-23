# ============================================================================
# 输出
# ============================================================================

output "shared_elb_id" {
  description = "共享 ELB 的 ID（部署蓝/绿 Service 时填入 manifests 的 kubernetes.io/elb.id）"
  value       = huaweicloud_elb_loadbalancer.shared.id
}

output "shared_elb_public_ip" {
  description = "共享 ELB 的公网入口 IP（蓝/绿流量统一入口）"
  value       = huaweicloud_vpc_eip.elb.address
}

output "cluster_names" {
  description = "两个 CCE 集群名称"
  value = {
    for k, v in huaweicloud_cce_cluster.this : k => v.name
  }
}

output "cluster_api_ips" {
  description = "两个 CCE 集群控制面公网 IP（kubectl 连接用）"
  value = {
    for k, e in huaweicloud_vpc_eip.cce : k => e.address
  }
}