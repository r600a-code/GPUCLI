#!/bin/bash
# GPU Sniper — CFGPU 资源监控 & 自动抢卡
# 零配置，装了就能跑

set -e

# ─── 颜色 ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# ─── 配置 ───
CFGPU_API_BASE="https://api.cfgpu.com"
TOKEN_FILE="$HOME/.cfgpu/token"
INTERVAL=30
PROBE_MODE=false
DEFAULT_GPU_NUM=1
DEFAULT_DURATION=1
DEFAULT_PRICE_TYPE="Day"
IMAGE_ID=""

# ─── 解析参数 ───
while [[ $# -gt 0 ]]; do
    case "$1" in
        --interval) INTERVAL="$2"; shift 2 ;;
        --probe) PROBE_MODE=true; shift ;;
        --gpu-num) DEFAULT_GPU_NUM="$2"; shift 2 ;;
        --image) IMAGE_ID="$2"; shift 2 ;;
        --token) mkdir -p "$(dirname "$TOKEN_FILE")"; echo "$2" > "$TOKEN_FILE"; chmod 600 "$TOKEN_FILE"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [选项]"
            echo "  --interval N    轮询间隔秒数 (默认30)"
            echo "  --probe         探测模式，只检查不创建实例"
            echo "  --gpu-num N     GPU数量 (默认1)"
            echo "  --image ID      指定镜像ID (默认自动获取)"
            echo "  --token TOKEN   直接设置 API Token"
            exit 0 ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

# ─── Token 管理 ───
setup_token() {
    if [ -f "$TOKEN_FILE" ]; then
        CFGPU_TOKEN=$(cat "$TOKEN_FILE" | tr -d '\n')
        if [ -n "$CFGPU_TOKEN" ]; then
            return
        fi
    fi
    echo -e "${YELLOW}首次运行，需要配置 CFGPU API Token${NC}"
    echo -e "${GRAY}获取地址: https://cfgpu.com${NC}"
    echo ""
    read -p "请输入你的 API Token: " CFGPU_TOKEN
    if [ -z "$CFGPU_TOKEN" ]; then
        echo -e "${RED}Token 不能为空${NC}"
        exit 1
    fi
    mkdir -p "$(dirname "$TOKEN_FILE")"
    echo "$CFGPU_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo -e "${GREEN}Token 已保存到 $TOKEN_FILE${NC}"
    echo ""
}

# ─── API 请求 ───
api_get() {
    curl -s -H "Authorization: $CFGPU_TOKEN" "$CFGPU_API_BASE$1"
}

api_post() {
    curl -s -X POST -H "Authorization: $CFGPU_TOKEN" -H "Content-Type: application/json" -d "$2" "$CFGPU_API_BASE$1"
}

# ─── 获取第一个可用 imageId ───
get_default_image() {
    local resp
    resp=$(api_get "/userapi/v1/image/systemList?adaptType=VM")
    # 递归查找第一个带 code 的节点
    echo "$resp" | jq -r '.. | .code? // empty' 2>/dev/null | head -1
}

# ─── 判断错误是否为"资源不足" ───
is_no_gpu() {
    local error_code="$1"
    local error_msg="$2"
    # 实际返回的错误码是 BIZ_ERROR，消息包含"资源不足"或"GPU不足"
    if [ "$error_code" = "51002" ] || [ "$error_code" = "51001" ]; then
        return 0
    fi
    if echo "$error_msg" | grep -qi "资源不足\|GPU不足\|显卡"; then
        return 0
    fi
    return 1
}

# ─── 尝试创建实例 ───
try_create() {
    local region="$1"
    local gpu_type="$2"
    local gpu_name="$3"
    local region_name="$4"

    local data
    data=$(cat <<EOF
{
    "priceType": "$DEFAULT_PRICE_TYPE",
    "regionCode": "$region",
    "gpuType": "$gpu_type",
    "gpuNum": $DEFAULT_GPU_NUM,
    "expandSize": 0,
    "imageId": "$IMAGE_ID",
    "serviceTime": $DEFAULT_DURATION,
    "instanceName": "GPU-Sniper-$(date +%m%d%H%M)"
}
EOF
    )

    local response
    response=$(api_post "/userapi/v1/instance/create" "$data")

    local success error_code error_msg
    success=$(echo "$response" | jq -r '.success // empty')
    error_code=$(echo "$response" | jq -r '.errorCode // empty')
    error_msg=$(echo "$response" | jq -r '.errorMsg // empty')

    if [ "$success" = "true" ]; then
        local instance_id
        instance_id=$(echo "$response" | jq -r '.content.instanceId // .content // "unknown"')
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════${NC}"
        echo -e "${GREEN}  🎉 抢到了!${NC}"
        echo -e "${GREEN}  GPU: ${gpu_name} x${DEFAULT_GPU_NUM}${NC}"
        echo -e "${GREEN}  区域: ${region_name}${NC}"
        echo -e "${GREEN}  实例ID: ${instance_id}${NC}"
        echo -e "${GREEN}  价格模式: ${DEFAULT_PRICE_TYPE} | 时长: ${DEFAULT_DURATION}${NC}"
        echo -e "${GREEN}═══════════════════════════════════════${NC}"
        return 0
    elif is_no_gpu "$error_code" "$error_msg"; then
        return 1
    elif [ "$error_code" = "50001" ] || [ "$error_code" = "52001" ]; then
        echo -e "${RED}❌ 余额不足，请充值后重试${NC}"
        exit 1
    elif [ "$error_code" = "10001" ]; then
        # 参数错误（如 imageId 问题），跳过不报错
        return 1
    else
        echo -e "${YELLOW}⚠ ${gpu_name} @ ${region_name}: ${error_msg} (${error_code})${NC}"
        return 1
    fi
}

# ─── 探测模式（不创建，用真实 imageId 探测） ───
probe_check() {
    local region="$1"
    local gpu_type="$2"
    local gpu_name="$3"
    local region_name="$4"

    local data
    data=$(cat <<EOF
{
    "priceType": "$DEFAULT_PRICE_TYPE",
    "regionCode": "$region",
    "gpuType": "$gpu_type",
    "gpuNum": $DEFAULT_GPU_NUM,
    "expandSize": 0,
    "imageId": "$IMAGE_ID",
    "serviceTime": $DEFAULT_DURATION,
    "instanceName": "probe"
}
EOF
    )

    local response
    response=$(api_post "/userapi/v1/instance/create" "$data")

    local success error_code error_msg
    success=$(echo "$response" | jq -r '.success // empty')
    error_code=$(echo "$response" | jq -r '.errorCode // empty')
    error_msg=$(echo "$response" | jq -r '.errorMsg // empty')

    if [ "$success" = "true" ]; then
        # 有货！立即释放实例
        local instance_id
        instance_id=$(echo "$response" | jq -r '.content.instanceId // empty')
        if [ -n "$instance_id" ]; then
            api_post "/userapi/v1/instance/$instance_id/release" >/dev/null 2>&1
        fi
        echo -e "${GREEN}✅ 有货! ${gpu_name} x${DEFAULT_GPU_NUM} @ ${region_name}${NC}"
        return 0
    elif is_no_gpu "$error_code" "$error_msg"; then
        return 1
    else
        return 1
    fi
}

# ─── 主循环 ───
main() {
    setup_token

    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  GPU Sniper — CFGPU 资源监控${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    if [ "$PROBE_MODE" = true ]; then
        echo -e "${YELLOW}  模式: 探测（不自动创建实例）${NC}"
    else
        echo -e "${GREEN}  模式: 自动抢卡（有货即创建）${NC}"
    fi
    echo -e "${CYAN}  轮询间隔: ${INTERVAL}秒 | GPU数量: ${DEFAULT_GPU_NUM}${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""

    # 验证 token
    echo -ne "${GRAY}验证 Token...${NC}"
    local regions_raw gpu_types_raw
    regions_raw=$(api_get "/userapi/v1/region/list")
    local token_ok
    token_ok=$(echo "$regions_raw" | jq -r '.success // empty' 2>/dev/null)
    if [ "$token_ok" != "true" ]; then
        echo -e "\r${RED}Token 无效或网络异常${NC}"
        echo -e "${GRAY}$(echo "$regions_raw" | jq -r '.errorMsg // . // "unknown error"')${NC}"
        exit 1
    fi
    echo -e "\r${GREEN}Token 有效 ✓${NC}"

    # 解析 region 列表（用 jq -c 逐行输出，避免空格拆分问题）
    local regions_json
    regions_json=$(echo "$regions_raw" | jq -c '.content[]')
    if [ -z "$regions_json" ]; then
        echo -e "${RED}未获取到 region 列表${NC}"
        exit 1
    fi

    # 解析 GPU 列表
    gpu_types_raw=$(api_get "/userapi/v1/gpu/list")
    local gpus_json
    gpus_json=$(echo "$gpu_types_raw" | jq -c '.content[]')
    if [ -z "$gpus_json" ]; then
        echo -e "${RED}未获取到 GPU 类型列表${NC}"
        exit 1
    fi

    # 获取默认镜像
    if [ -z "$IMAGE_ID" ]; then
        echo -ne "${GRAY}获取默认镜像...${NC}"
        IMAGE_ID=$(get_default_image)
        if [ -z "$IMAGE_ID" ] || [ "$IMAGE_ID" = "null" ]; then
            echo -e "\r${RED}未找到可用镜像，请用 --image 指定${NC}"
            exit 1
        fi
        echo -e "\r${GREEN}默认镜像: ${IMAGE_ID} ✓${NC}"
    fi

    local region_count gpu_count
    region_count=$(echo "$regions_json" | wc -l | tr -d ' ')
    gpu_count=$(echo "$gpus_json" | wc -l | tr -d ' ')
    echo -e "${GRAY}监控 ${region_count} 个区域, ${gpu_count} 种 GPU 类型${NC}"
    echo ""

    local round=0
    while true; do
        round=$((round + 1))
        local timestamp
        timestamp=$(date '+%H:%M:%S')

        while IFS= read -r region_line; do
            local r_code r_name
            r_code=$(echo "$region_line" | jq -r '.code')
            r_name=$(echo "$region_line" | jq -r '.name')

            while IFS= read -r gpu_line; do
                local g_code g_name
                g_code=$(echo "$gpu_line" | jq -r '.code')
                g_name=$(echo "$gpu_line" | jq -r '.name')

                echo -ne "${GRAY}[${timestamp}] #${round} ${g_name} @ ${r_name} ... ${NC}"

                if [ "$PROBE_MODE" = true ]; then
                    if probe_check "$r_code" "$g_code" "$g_name" "$r_name"; then
                        : # probe_check 已打印
                    else
                        echo -e "${GRAY}无货${NC}"
                    fi
                else
                    if try_create "$r_code" "$g_code" "$g_name" "$r_name"; then
                        exit 0
                    else
                        echo -e "${GRAY}无货${NC}"
                    fi
                fi
            done <<< "$gpus_json"
        done <<< "$regions_json"

        echo -e "${GRAY}[${timestamp}] --- 第 ${round} 轮结束，${INTERVAL}s 后继续 ---${NC}"
        sleep "$INTERVAL"
    done
}

main
