# ============================================================================
# 变量定义
# ============================================================================

variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4"
}

variable "project_name" {
  description = "项目名称，用于资源命名前缀"
  type        = string
  default     = "cce-shared-subnets"
}

variable "vpc_cidr" {
  description = "VPC 网段"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_flavor" {
  description = "CCE 节点规格（显式指定）"
  type        = string
  default     = "s6.large.2"
}

variable "node_count" {
  description = "每个集群的初始节点数"
  type        = number
  default     = 1
}

variable "elb_az" {
  description = "共享 ELB 可用区（需与集群节点可用区一致）"
  type        = string
  default     = "cn-north-4a"
}

variable "elb_bandwidth" {
  description = "共享 ELB 公网带宽（Mbit/s）"
  type        = number
  default     = 5
}