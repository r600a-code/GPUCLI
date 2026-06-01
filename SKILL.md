---
name: cfgpu-api
description: Manage GPU cloud instances on CFGPU platform. Includes GPU Sniper for auto-detecting and grabbing available GPU resources.
---

# CFGPU API Skill

Manage GPU cloud instances on CFGPU (https://cfgpu.com) platform. Includes **GPU Sniper** for auto-detecting and grabbing available GPU resources.

## When to Use

Use this skill immediately when the user asks any of:

- "manage GPU instances on CFGPU"
- "create GPU instance"
- "check GPU instance status"
- "start/stop/release GPU instance"
- "query available GPU types/regions"
- "manage CFGPU cloud resources"
- **"抢卡" / "gpu-sniper" / "有没有卡" / "监控GPU" / "GPU有货吗"**

## Quick Start

### Prerequisites

1. **API Token**: Get your API token from [CFGPU platform](https://cfgpu.com)
2. Token will be auto-saved on first run — no manual config needed

### Basic Usage

```bash
# List available regions
./scripts/cfgpu-helper.sh list-regions

# List available GPU types
./scripts/cfgpu-helper.sh list-gpus

# Interactive instance creation
./scripts/cfgpu-helper.sh quick-create
```

## GPU Sniper (抢卡功能)

### Quick Probe — 一次性扫描所有资源

```bash
./scripts/probe.sh
```

输出所有 region × GPU 的可用性表格：

```
            RTX 4090      H800          L40S          A100-PCIe
杭州        无货          无货          无货          无货
重庆        无货          无货          无货          无货
绍兴        ✅ 有货       无货          无货          无货
```

### Auto Sniper — 持续监控，有卡就抢

```bash
./scripts/gpu-sniper.sh
```

每 30 秒轮询所有 region + GPU 组合，发现有卡自动创建实例：

```
[16:08:16] #1 RTX 4090 @ 杭州 ... 无货
[16:08:16] #1 H800 @ 杭州 ... 无货
[16:08:17] #1 RTX 4090 @ 绍兴 ...
═══════════════════════════════════════
  🎉 抢到了!
  GPU: RTX 4090 x1
  区域: 绍兴
  实例ID: instance-xxxxx
═══════════════════════════════════════
```

### Sniper Options

```bash
# 自定义轮询间隔（默认30秒）
./scripts/gpu-sniper.sh --interval 10

# 指定 GPU 数量
./scripts/gpu-sniper.sh --gpu-num 2

# 指定镜像
./scripts/gpu-sniper.sh --image image_xxxx

# 探测模式（只看不抢）
./scripts/probe.sh
```

## API Reference

### Base Configuration

| Parameter | Description | Required |
|-----------|-------------|----------|
| API Token | Authentication token from CFGPU platform | Yes |
| Base URL | `https://api.cfgpu.com` | Yes |

### Response Format

All responses follow this format:

```json
{
  "success": true,
  "errorCode": "",
  "errorMsg": "",
  "content": null
}
```

### Error Codes

| Code | Message | Action |
|------|---------|--------|
| 10001 | 请求参数错误 | Check request parameters |
| 50001 | 余额不足 | Add funds to account |
| 51001 | 资源不足 | Try different region/GPU type |
| 51002 | GPU不足 | Reduce GPU count or wait |
| BIZ_ERROR | 当前主机可用资源不足 [显卡] | GPU not available, keep polling |

## Core Operations

### 1. Region Management

```bash
GET /userapi/v1/region/list
```

### 2. GPU Type Management

```bash
GET /userapi/v1/gpu/list
```

### 3. Instance Management

```bash
# Create
POST /userapi/v1/instance/create

# Status
GET /userapi/v1/instance/{instanceId}/status

# All instances
GET /userapi/v1/instance/status

# Start / Stop / Release
POST /userapi/v1/instance/{instanceId}/start
POST /userapi/v1/instance/{instanceId}/stop
POST /userapi/v1/instance/{instanceId}/release

# Change image
POST /userapi/v1/instance/{instanceId}/changeImage

# Query (paginated)
POST /userapi/v1/instance/page
```

## Scripts Overview

| Script | Description |
|--------|-------------|
| `gpu-sniper.sh` | **GPU 抢卡** — 持续轮询，有卡自动创建实例 |
| `probe.sh` | **资源探测** — 一次性扫描，输出可用性表格 |
| `cfgpu-helper.sh` | Main CLI tool for all operations |
| `setup-env.sh` | Interactive environment setup |
| `check-config.sh` | Configuration validation |
| `example-usage.sh` | Usage examples |

## Security Notes

- **Never commit API tokens** to version control
- **Use environment variables** or secure token files (`~/.cfgpu/token`)
- **Set appropriate permissions** on token files (`chmod 600`)
- **Regularly rotate API tokens** for security

## 联系方式

- 微信：`wwwr600a`
- Twitter/X：[@ADfunAI](https://x.com/ADfunAI)

## License

MIT License - see [LICENSE](LICENSE) file for details.
