# CFGPU API Skill for OpenClaw

A comprehensive OpenClaw skill for managing GPU cloud instances on CFGPU platform. Includes **GPU Sniper** for auto-detecting and grabbing available GPU resources.

## Features

- **GPU Sniper**: Auto-poll all regions and GPU types, grab resources when available
- **Resource Probe**: One-shot scan showing availability table across all regions/GPUs
- **Resource Management**: List available regions, GPU types, and system images
- **Instance Lifecycle**: Create, start, stop, release GPU instances
- **Image Management**: List and manage system/user images
- **Interactive Wizard**: User-friendly command-line interface
- **API Integration**: Full CFGPU API coverage

## Installation

### Option 1: Install via ClawHub
```bash
clawhub install cfgpu-api
```

### Option 2: Manual Installation
```bash
git clone https://github.com/r600a-code/GPUCLI.git
cd GPUCLI
chmod +x scripts/*.sh
```

## Quick Start

No manual configuration needed. Just run and the script will prompt for your API token on first use.

```bash
# Quick probe — see what's available right now
./scripts/probe.sh

# Auto sniper — keep polling and grab when available
./scripts/gpu-sniper.sh
```

## GPU Sniper

### Probe Mode (一次性扫描)

```bash
./scripts/probe.sh
```

Scans all region × GPU combinations and outputs a table:

```
            RTX 4090      H800          L40S          A100-PCIe
杭州        无货          无货          无货          无货
重庆        无货          无货          无货          无货
绍兴        ✅ 有货       无货          无货          无货
```

### Sniper Mode (持续监控抢卡)

```bash
./scripts/gpu-sniper.sh                    # 默认30秒轮询
./scripts/gpu-sniper.sh --interval 10      # 10秒轮询
./scripts/gpu-sniper.sh --gpu-num 2        # 抢2卡
```

When a GPU becomes available:

```
═══════════════════════════════════════
  🎉 抢到了!
  GPU: RTX 4090 x1
  区域: 绍兴
  实例ID: instance-xxxxx
  价格模式: Day | 时长: 1
═══════════════════════════════════════
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

## API Coverage

This skill supports the full CFGPU API:

- ✅ Region management
- ✅ GPU type listing
- ✅ Image management (system/user)
- ✅ Instance lifecycle (create/start/stop/release)
- ✅ Instance status monitoring
- ✅ Paginated instance queries
- ✅ **GPU resource detection and auto-grab**

## Security Notes

- **Never commit API tokens** to version control
- **Use environment variables** or secure token files
- **Set appropriate permissions** on token files (`chmod 600`)
- **Regularly rotate API tokens** for security

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Contact

- WeChat: `wwwr600a`
- Twitter/X: [@ADfunAI](https://x.com/ADfunAI)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- [CFGPU Platform](https://cfgpu.com)
- [OpenClaw Documentation](https://docs.openclaw.ai)
- [GitHub Issues](https://github.com/r600a-code/GPUCLI/issues)
