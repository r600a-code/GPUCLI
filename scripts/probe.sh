#!/bin/bash
# GPU Probe — 快速扫描 CFGPU 可用资源
# 一次性扫描，结果汇总表格输出

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

CFGPU_API_BASE="https://api.cfgpu.com"
TOKEN_FILE="$HOME/.cfgpu/token"
IMAGE_ID=""
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# ─── 参数 ───
while [[ $# -gt 0 ]]; do
    case "$1" in
        --image) IMAGE_ID="$2"; shift 2 ;;
        --token) mkdir -p "$(dirname "$TOKEN_FILE")"; echo "$2" > "$TOKEN_FILE"; chmod 600 "$TOKEN_FILE"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--image ID] [--token TOKEN]"
            exit 0 ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

# ─── Token ───
if [ -f "$TOKEN_FILE" ]; then
    CFGPU_TOKEN=$(cat "$TOKEN_FILE" | tr -d '\n')
fi
if [ -z "$CFGPU_TOKEN" ]; then
    echo -e "${YELLOW}请输入 CFGPU API Token:${NC}"
    read -p "> " CFGPU_TOKEN
    [ -z "$CFGPU_TOKEN" ] && echo -e "${RED}Token 不能为空${NC}" && exit 1
    mkdir -p "$(dirname "$TOKEN_FILE")"
    echo "$CFGPU_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
fi

api() {
    curl -s -H "Authorization: $CFGPU_TOKEN" "$CFGPU_API_BASE$1"
}

# ─── 获取镜像 ───
if [ -z "$IMAGE_ID" ]; then
    IMAGE_ID=$(api "/userapi/v1/image/systemList?adaptType=VM" | jq -r '.. | .code? // empty' 2>/dev/null | head -1)
fi

# ─── 拉取 region + GPU ───
REGIONS_RAW=$(api "/userapi/v1/region/list")
GPUS_RAW=$(api "/userapi/v1/gpu/list")

REGIONS_JSON=$(echo "$REGIONS_RAW" | jq -c '.content[]')
GPUS_JSON=$(echo "$GPUS_RAW" | jq -c '.content[]')

REGION_COUNT=$(echo "$REGIONS_JSON" | wc -l | tr -d ' ')
GPU_COUNT=$(echo "$GPUS_JSON" | wc -l | tr -d ' ')

echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  GPU Probe — 扫描 CFGPU 可用资源${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${GRAY}  区域: ${REGION_COUNT} | GPU: ${GPU_COUNT} | 组合: $((REGION_COUNT * GPU_COUNT))${NC}"
echo -e "${GRAY}  镜像: ${IMAGE_ID}${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""

# ─── 收集名字 ───
# gpu_names[code]=name
i=0
while IFS= read -r line; do
    code=$(echo "$line" | jq -r '.code')
    name=$(echo "$line" | jq -r '.name')
    echo "$code" >> "$TMPDIR/gpu_codes"
    echo "$name" >> "$TMPDIR/gpu_names"
    i=$((i+1))
done <<< "$GPUS_JSON"

i=0
while IFS= read -r line; do
    code=$(echo "$line" | jq -r '.code')
    name=$(echo "$line" | jq -r '.name')
    echo "$code" >> "$TMPDIR/region_codes"
    echo "$name" >> "$TMPDIR/region_names"
    i=$((i+1))
done <<< "$REGIONS_JSON"

# ─── 扫描 ───
TOTAL=0
AVAILABLE=0
NO_STOCK=0
ERRORS=0

echo -ne "${GRAY}扫描中"
while IFS= read -r region_line; do
    r_code=$(echo "$region_line" | jq -r '.code')
    r_name=$(echo "$region_line" | jq -r '.name')

    while IFS= read -r gpu_line; do
        g_code=$(echo "$gpu_line" | jq -r '.code')
        g_name=$(echo "$gpu_line" | jq -r '.name')
        TOTAL=$((TOTAL + 1))

        response=$(curl -s -X POST \
            -H "Authorization: $CFGPU_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"priceType\":\"Day\",\"regionCode\":\"$r_code\",\"gpuType\":\"$g_code\",\"gpuNum\":1,\"expandSize\":0,\"imageId\":\"$IMAGE_ID\",\"serviceTime\":1,\"instanceName\":\"probe-$$\"}" \
            "$CFGPU_API_BASE/userapi/v1/instance/create")

        success=$(echo "$response" | jq -r '.success // empty')
        error_code=$(echo "$response" | jq -r '.errorCode // empty')
        error_msg=$(echo "$response" | jq -r '.errorMsg // empty')

        # 写结果: region_code|gpu_code|status
        if [ "$success" = "true" ]; then
            instance_id=$(echo "$response" | jq -r '.content.instanceId // empty')
            [ -n "$instance_id" ] && curl -s -X POST -H "Authorization: $CFGPU_TOKEN" "$CFGPU_API_BASE/userapi/v1/instance/$instance_id/release" >/dev/null 2>&1
            echo "${r_code}|${g_code}|ok" >> "$TMPDIR/results"
            AVAILABLE=$((AVAILABLE + 1))
            echo -ne "\r\033[K${GREEN}✅ 发现! ${g_name} @ ${r_name}${NC}"
        elif echo "$error_msg" | grep -qi "资源不足\|GPU不足\|显卡"; then
            echo "${r_code}|${g_code}|no" >> "$TMPDIR/results"
            NO_STOCK=$((NO_STOCK + 1))
        elif [ "$error_code" = "51002" ] || [ "$error_code" = "51001" ]; then
            echo "${r_code}|${g_code}|no" >> "$TMPDIR/results"
            NO_STOCK=$((NO_STOCK + 1))
        else
            echo "${r_code}|${g_code}|err:${error_msg}" >> "$TMPDIR/results"
            ERRORS=$((ERRORS + 1))
        fi

        echo -ne "."
    done <<< "$GPUS_JSON"
done <<< "$REGIONS_JSON"
echo -e "\033[K"

# ─── 汇总表格 ───
echo ""
echo -e "${CYAN}───────────────────────────────────────────────────${NC}"
echo -e "${CYAN}  扫描结果${NC}"
echo -e "${CYAN}───────────────────────────────────────────────────${NC}"
echo ""

# 表头
printf "%-12s" ""
gpu_idx=0
while IFS= read -r g_name; do
    # 截断到12字符
    short="${g_name:0:12}"
    printf "%-14s" "$short"
    gpu_idx=$((gpu_idx+1))
done < "$TMPDIR/gpu_names"
echo ""

# 每行一个 region
r_idx=0
while IFS= read -r r_code; do
    r_name=$(sed -n "$((r_idx+1))p" "$TMPDIR/region_names")
    printf "%-12s" "${r_name:0:10}"

    g_idx=0
    while IFS= read -r g_code; do
        key="${r_code}|${g_code}"
        val=$(grep "^${key}|" "$TMPDIR/results" 2>/dev/null | cut -d'|' -f3)
        if [ "$val" = "ok" ]; then
            printf "${GREEN}%-14s${NC}" "✅ 有货"
        elif [ "$val" = "no" ]; then
            printf "${GRAY}%-14s${NC}" "无货"
        else
            printf "${YELLOW}%-14s${NC}" "异常"
        fi
        g_idx=$((g_idx+1))
    done < "$TMPDIR/gpu_codes"
    echo ""
    r_idx=$((r_idx+1))
done < "$TMPDIR/region_codes"

echo ""
echo -e "${CYAN}───────────────────────────────────────────────────${NC}"
echo -e "  总计: ${TOTAL} 组合 | ${GREEN}有货: ${AVAILABLE}${NC} | ${GRAY}无货: ${NO_STOCK}${NC} | ${YELLOW}异常: ${ERRORS}${NC}"
echo -e "${CYAN}───────────────────────────────────────────────────${NC}"

if [ "$AVAILABLE" -gt 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 发现可用资源！运行以下命令抢卡:${NC}"
    echo -e "${GREEN}   bash gpu-sniper/gpu-sniper.sh${NC}"
fi
