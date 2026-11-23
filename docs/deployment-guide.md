# 部署指导

本文档描述如何从零部署本实践的基础设施，并将蓝/绿应用发布到两个集群。

## 前置条件

- 已开通华为云账号并完成实名认证，具备创建 VPC / CCE / ELB / EIP 的权限（建议 IAM 管理员权限）。
- 已安装 [Terraform](https://www.terraform.io/downloads)（>= 1.5.0）。
- 已安装 [kubectl](https://kubernetes.io/docs/tasks/tools/)（>= 1.28）。
- 已在华为云「我的凭证」页面获取 Access Key ID 与 Secret Access Key。

## 步骤 1：准备凭据

在部署机的 shell 中导出华为云访问密钥（不会写入任何代码或配置文件）：

```bash
export HW_ACCESS_KEY="<your-access-key>"
export HW_SECRET_KEY="<your-secret-key>"
```

## 步骤 2：初始化与规划

```bash
cd infra
terraform init
terraform plan
```

`terraform plan` 应输出将要创建的资源清单（VPC、子网、安全组、两个 CCE 集群与节点池、共享 ELB 与若干 EIP）。

## 步骤 3：创建基础设施

```bash
terraform apply -auto-approve
```

等待资源创建完成（CCE 集群与节点池需数分钟）。

## 步骤 4：获取连接信息

```bash
terraform output
```

关键输出：

- `shared_elb_id`：共享 ELB 的 ID，用于下一步 Service 注解；`shared_elb_public_ip`：共享入口 IP。
- `cluster_names`：两个集群名称；`cluster_api_ips`：两个集群控制面公网 IP。

在华为云控制台「云容器引擎 CCE」为两个集群分别下载 kubeconfig（选择公网访问）。

## 步骤 5：部署蓝绿应用

将两个 Service 清单中的 `<ELB_ID>` 替换为 `terraform output -raw shared_elb_id` 的返回值：

```bash
ELB_ID=$(terraform output -raw shared_elb_id)
sed -i "s/<ELB_ID>/${ELB_ID}/" manifests/blue/service.yaml manifests/green/service.yaml
```

部署蓝环境（到 blue 集群）：

```bash
kubectl --kubeconfig <blue-kubeconfig> apply -f manifests/namespace.yaml
kubectl --kubeconfig <blue-kubeconfig> apply -f manifests/blue/
```

部署绿环境（到 green 集群）：

```bash
kubectl --kubeconfig <green-kubeconfig> apply -f manifests/namespace.yaml
kubectl --kubeconfig <green-kubeconfig> apply -f manifests/green/
```

## 步骤 6：释放资源

```bash
cd infra
terraform destroy -auto-approve
```

> `terraform destroy` 仅释放 Terraform 追踪的资源；若曾手工下载 kubeconfig 或创建其他对象，请一并清理，避免残留。