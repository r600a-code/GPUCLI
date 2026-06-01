# CFGPU API Skill for OpenClaw

![OpenClaw Skill](https://img.shields.io/badge/OpenClaw-Skill-blue)
![CFGPU API](https://img.shields.io/badge/CFGPU-API-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

管理 CFGPU 平台 GPU 云实例的 OpenClaw skill。内置 **GPU 抢卡器**，自动检测并抢占可用 GPU 资源。

## 功能特性

### GPU 抢卡器
- **资源探测**: 一次性扫描所有 region × GPU，输出可用性表格
- **自动抢卡**: 持续轮询，发现有卡立即创建实例
- **零配置**: 首次运行自动引导输入 Token，无需手动配置
- **智能检测**: 自动获取所有区域、GPU 类型、默认镜像

### 核心功能
- **资源管理**: 列出可用区域、GPU 类型、系统镜像
- **实例管理**: 创建、启动、停止、释放 GPU 实例
- **镜像管理**: 浏览和选择系统/用户镜像
- **交互式向导**: 用户友好的命令行界面

## 支持的 GPU 类型

| GPU 型号 | 代码 | 适用场景 |
|---------|------|---------|
| RTX 4090 | `nt8cyt3s` | AI 训练、渲染 |
| H800 | `8sxe63f5` | 企业级 AI、大模型 |
| L40S | `ldo3kj09` | 专业工作站 |
| RTX 4070 | `vupgiaxl` | 中端 AI/ML |
| RTX 4060 | `h7c0m6x0` | 入门级 AI 开发 |
| A800-PCIe | `xegcm0st` | A100 替代方案 |
| RTX 3080 | `0d783kuh` | 性价比之选 |
| A100-PCIe | `jfu3hf09` | 数据中心、HPC |
| H200-SXM | - | 最新一代 |
| H100-SXM5 | - | 最新一代 |

## 安装

### 方式一：通过 ClawHub 安装
```bash
clawhub install cfgpu-api
```

### 方式二：手动安装
```bash
git clone https://github.com/r600a-code/GPUCLI.git
cd GPUCLI
chmod +x scripts/*.sh
```

## 快速开始

无需手动配置。直接运行，首次使用时脚本会引导输入 API Token。

### 资源探测（一次性扫描）

```bash
./scripts/probe.sh
```

输出所有 region × GPU 的可用性表格：

```
            RTX 4090      H800          L40S          A100-PCIe
杭州        无货          无货          无货          无货
重庆        无货          无货          无货          无货
绍兴        ✅ 有货       无货          无货          无货
苏州        无货          无货          无货          无货
```

### 自动抢卡（持续监控）

```bash
# 默认30秒轮询
./scripts/gpu-sniper.sh

# 10秒轮询
./scripts/gpu-sniper.sh --interval 10

# 抢2卡
./scripts/gpu-sniper.sh --gpu-num 2
```

发现有卡时自动创建实例：

```
[16:08:16] #1 RTX 4090 @ 杭州 ... 无货
[16:08:16] #1 H800 @ 杭州 ... 无货
[16:08:17] #1 RTX 4090 @ 绍兴 ...
═══════════════════════════════════════
  🎉 抢到了!
  GPU: RTX 4090 x1
  区域: 绍兴
  实例ID: instance-xxxxx
  价格模式: Day | 时长: 1
═══════════════════════════════════════
```

## 脚本列表

| 脚本 | 说明 |
|------|------|
| `gpu-sniper.sh` | **GPU 抢卡** — 持续轮询，有卡自动创建实例 |
| `probe.sh` | **资源探测** — 一次性扫描，输出可用性表格 |
| `cfgpu-helper.sh` | 主 CLI 工具，支持所有 CFGPU 操作 |
| `setup-env.sh` | 交互式环境配置 |
| `check-config.sh` | 配置验证 |
| `example-usage.sh` | 使用示例 |

## API 覆盖

- ✅ 区域管理
- ✅ GPU 类型列表
- ✅ 镜像管理（系统/用户）
- ✅ 实例生命周期（创建/启动/停止/释放）
- ✅ 实例状态监控
- ✅ 分页查询实例
- ✅ **GPU 资源检测与自动抢占**

## 安全注意事项

- **不要将 API Token 提交到版本控制**
- **使用环境变量**或安全的 Token 文件（`~/.cfgpu/token`）
- **设置适当的权限**（`chmod 600`）
- **定期轮换 API Token**

## 贡献

1. Fork 仓库
2. 创建功能分支
3. 提交更改
4. 发起 Pull Request

## 联系方式

- 微信：`wwwr600a`
- Twitter/X：[@ADfunAI](https://x.com/ADfunAI)

## 许可证

MIT License - 详见 [LICENSE](LICENSE)

## 支持

- [CFGPU 平台](https://cfgpu.com)
- [OpenClaw 文档](https://docs.openclaw.ai)
- [GitHub Issues](https://github.com/r600a-code/GPUCLI/issues)
