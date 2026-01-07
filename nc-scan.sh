#!/usr/bin/env bash
# ==========================================================
# Cross-Platform Netcat Port Scanner (macOS / Linux)
# 功能：
# 1. 自动检测 nc 是否存在（macOS / Linux 通用）
# 2. 扫描前 ping 探活，跳过不可达 IP
# 3. 自动判断内网 / 公网 IP，动态调整扫描策略
# 4. 支持单 / 多 IP
# 5. 扫描结果同时输出 CSV 与 JSON
# ==========================================================

set -e

# -----------------------------
# 默认配置
# -----------------------------
DEFAULT_PRIVATE_PORTS="1-1024"
DEFAULT_PUBLIC_PORTS="22,80,443"
DEFAULT_TIMEOUT_PRIVATE=1
DEFAULT_TIMEOUT_PUBLIC=2
OUTPUT_PREFIX="scan_result"

# -----------------------------
# Shell / 工具检测
# -----------------------------

check_bash() {
  if command -v bash >/dev/null 2>&1; then
    BASH_PATH=$(command -v bash)
    echo "[OK] bash 已安装：$BASH_PATH"
  else
    echo "[FATAL] 系统未检测到 bash，脚本无法运行。"
    echo
    echo "请先安装 bash："
    echo "  macOS（Homebrew）："
    echo "    brew install bash"
    echo "    安装完成后请重新打开终端"
    echo
    echo "  Linux："
    echo "    Debian/Ubuntu: sudo apt install bash"
    echo "    RHEL/CentOS:   sudo yum install bash"
    echo "    Alpine:        apk add bash"
    exit 1
  fi
}

check_nc() {
  if ! command -v nc >/dev/null 2>&1; then
    echo "[ERROR] 未检测到 netcat (nc)，请先安装。"
    echo "macOS: brew install netcat"
    echo "Linux: 使用发行版包管理器安装 netcat 或 nmap-ncat"
    exit 1
  fi
}

check_ping() {
  if ! command -v ping >/dev/null 2>&1; then
    echo "[ERROR] 系统未提供 ping 命令"
    exit 1
  fi
}

check_nc() {
  if ! command -v nc >/dev/null 2>&1; then
    echo "[ERROR] 未检测到 netcat (nc)，请先安装。"
    echo "macOS: brew install netcat"
    echo "Linux: 使用发行版包管理器安装 netcat 或 nmap-ncat"
    exit 1
  fi
}

check_ping() {
  if ! command -v ping >/dev/null 2>&1; then
    echo "[ERROR] 系统未提供 ping 命令"
    exit 1
  fi
}

# -----------------------------
# IP 判断
# -----------------------------

is_private_ip() {
  local ip=$1
  [[ $ip =~ ^10\. ]] && return 0
  [[ $ip =~ ^192\.168\. ]] && return 0
  [[ $ip =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] && return 0
  return 1
}

# -----------------------------
# 探活
# -----------------------------

is_alive() {
  ping -c 1 -W 1 "$1" >/dev/null 2>&1
}

# -----------------------------
# 扫描函数
# -----------------------------

scan_ip() {
  local ip=$1
  local ports=$2
  local timeout=$3

  nc -zv -w "$timeout" "$ip" "$ports" 2>&1 | grep succeeded | awk -v ip="$ip" '{print ip "," $4}'
}

# -----------------------------
# 参数解析
# -----------------------------

usage() {
cat <<EOF
用法：
  $0 -i <IP 或 IP列表>

示例：
  $0 -i 192.168.1.10
  $0 -i 192.168.1.10,8.8.8.8
EOF
}

while getopts ":i:h" opt; do
  case $opt in
    i) IP_INPUT="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

[[ -z "$IP_INPUT" ]] && usage && exit 1

# -----------------------------
# -----------------------------
# 主流程
# -----------------------------

check_bash
check_nc
check_ping

echo "ip,port" > "${OUTPUT_PREFIX}.csv"
echo "[" > "${OUTPUT_PREFIX}.json"
FIRST_JSON=true

IFS=',' read -ra IPS <<< "$IP_INPUT"

for ip in "${IPS[@]}"; do
  echo "处理 IP: $ip"

  if ! is_alive "$ip"; then
    echo "  [SKIP] ping 不可达"
    continue
  fi

  if is_private_ip "$ip"; then
    PORTS="$DEFAULT_PRIVATE_PORTS"
    TIMEOUT="$DEFAULT_TIMEOUT_PRIVATE"
    SCOPE="private"
  else
    PORTS="$DEFAULT_PUBLIC_PORTS"
    TIMEOUT="$DEFAULT_TIMEOUT_PUBLIC"
    SCOPE="public"
  fi

  echo "  类型: $SCOPE | 端口: $PORTS"

  while IFS=',' read -r ip_out port; do
    echo "$ip_out,$port" >> "${OUTPUT_PREFIX}.csv"

    if [ "$FIRST_JSON" = true ]; then
      FIRST_JSON=false
    else
      echo "," >> "${OUTPUT_PREFIX}.json"
    fi

    cat >> "${OUTPUT_PREFIX}.json" <<EOF
  {"ip":"$ip_out","port":"$port","scope":"$SCOPE"}
EOF

  done < <(scan_ip "$ip" "$PORTS" "$TIMEOUT")

done

echo "]" >> "${OUTPUT_PREFIX}.json"

echo "扫描完成"
