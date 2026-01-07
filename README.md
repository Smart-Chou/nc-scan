# nc-scan

一个 **跨平台（macOS / Linux）** 的轻量级端口扫描工具，基于 **bash + netcat** 实现，面向工程与运维场景设计。

该工具强调：

* 行为可预测
* 依赖明确
* 输出结构化
* 可直接集成到自动化流程

---

## 一、功能特性

* 支持 **macOS / Linux**
* 强制使用 **bash** 作为解释器（避免 shell 兼容性问题）
* 扫描前自动 **ping 探活**，跳过不可达 IP
* 自动判断 **内网 / 公网 IP**，并采用不同扫描策略
* 支持 **单个 / 多个 IP** 扫描
* 扫描结果同时输出为 **CSV / JSON**
* 仅输出 **开放端口**，结果干净、可复用

---

## 二、运行环境要求

### 必须依赖

| 组件          | 要求     | 说明                              |
| ----------- | ------ | ------------------------------- |
| bash        | >= 3.2 | macOS 自带 3.2；Linux 通常更高         |
| nc (netcat) | 任意常见实现 | BSD nc / GNU netcat / nmap-ncat |
| ping        | 系统自带   | 用于主机探活                          |

> ⚠️ 注意：
>
> * **默认登录 shell 是否为 zsh 不影响使用**
> * 脚本通过 shebang 强制使用 bash 执行

---

## 三、获取脚本

### 方式一：直接下载（推荐）

```bash
curl -L -o nc-scan.sh https://raw.githubusercontent.com/Smart-Chou/nc-scan/main/nc-scan.sh
chmod +x nc-scan.sh
```

或使用 wget：

```bash
wget -O nc-scan.sh https://raw.githubusercontent.com/Smart-Chou/nc-scan/main/nc-scan.sh
chmod +x nc-scan.sh
```

---

## 四、安装与准备

### 1. 获取脚本

```bash
chmod +x nc-scan.sh
```

### 2. macOS 依赖安装（如缺失）

```bash
brew install bash netcat
```

> macOS 默认 bash 为 3.2，已满足要求，无需强制升级。

### 3. Linux 依赖安装示例

```bash
# Debian / Ubuntu
sudo apt install bash netcat

# RHEL / CentOS
sudo yum install bash nc

# Alpine
apk add bash netcat-openbsd
```

---

## 四、使用方法

### 基本用法

```bash
./nc-scan.sh -i <IP 或 IP列表>
```

### 示例

```bash
# 单个 IP
./nc-scan.sh -i 192.168.1.10

# 多个 IP（逗号分隔）
./nc-scan.sh -i 192.168.1.10,8.8.8.8
```

---

## 五、扫描逻辑说明（非常重要）

### 1. 执行流程

```text
bash 检测
  ↓
nc / ping 检测
  ↓
ping 探活（不可达直接跳过）
  ↓
判断 IP 类型（内网 / 公网）
  ↓
选择扫描策略
  ↓
nc 扫描
  ↓
输出 CSV / JSON
```

---

### 2. 内网 / 公网判定规则

遵循 RFC1918：

* 10.0.0.0/8
* 172.16.0.0 – 172.31.0.0
* 192.168.0.0/16

---

### 3. 扫描策略

| IP 类型 | 扫描端口      | 超时  |
| ----- | --------- | --- |
| 内网    | 1–1024    | 1 秒 |
| 公网    | 22,80,443 | 2 秒 |

> 设计原则：
>
> * 内网允许更激进扫描
> * 公网避免全端口扫描，降低风险与噪音

---

## 六、输出说明

### 1. CSV 输出（scan_result.csv）

```csv
ip,port
192.168.1.10,22
192.168.1.10,80
```

适用于：

* Excel / WPS
* 运维报表
* 简单资产统计

---

### 2. JSON 输出（scan_result.json）

```json
[
  {"ip":"192.168.1.10","port":"22","scope":"private"},
  {"ip":"8.8.8.8","port":"443","scope":"public"}
]
```

适用于：

* 自动化脚本
* API / 平台集成
* CMDB / 资产系统

---

## 七、设计原则与边界

### 已明确支持

* TCP 端口扫描
* 小规模 IP 列表
* 内网 / 公网差异化策略

### 明确不支持

* UDP 扫描（nc 不可靠）
* 服务指纹识别
* 绕过防火墙 / IDS

如需以上能力，请使用 **nmap**。

---

## 八、常见问题

### Q1：macOS 默认是 zsh，会有问题吗？

不会。

* 默认登录 shell 是 zsh
* 脚本执行时由 `#!/usr/bin/env bash` 强制使用 bash
* 两者互不冲突

---

### Q2：为什么不支持 `sh nc-scan.sh`？

因为脚本使用了 bash-only 特性：

* 数组
* `[[ ... ]]`
* process substitution

强制 bash 是为了避免隐蔽错误。

---

## 九、适用场景

* 内网资产快速排查
* 云服务器端口核查
* 自动化任务的预扫描阶段
* CI / 运维脚本中的轻量扫描组件

---

## 十、免责声明

本工具仅用于：

* 合法授权的网络环境
* 自有服务器 / 内部网络

禁止用于任何未授权的扫描行为。

---

## 十一、后续可扩展方向

* 并发扫描（xargs / job control）
* CIDR 批量扫描
* 二阶段公网扫描策略
* YAML / ENV 配置文件支持

---

**作者建议**：
这是一个“工程级可维护脚本”，而不是一次性工具。建议纳入版本控制并附带变更记录。
