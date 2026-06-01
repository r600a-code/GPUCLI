# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-06-01

### Added
- **GPU Sniper** (`gpu-sniper.sh`) — 持续轮询所有 region + GPU，有卡自动创建实例
- **Resource Probe** (`probe.sh`) — 一次性扫描，输出 region × GPU 可用性表格
- 零配置体验：首次运行自动引导输入 Token，自动获取镜像列表
- 支持 `--interval`、`--gpu-num`、`--image`、`--probe` 参数
- 实际错误码适配（BIZ_ERROR + "资源不足"）

### Fixed
- API 响应格式适配（`.content` 包装）
- GPU 名称含空格的解析问题
- Token 文件目录自动创建

## [1.0.0] - 2024-03-27

### Added
- Initial release of CFGPU API Skill
- Complete CFGPU API coverage
- Interactive command-line interface
- Environment setup scripts
- Comprehensive documentation

### Features
- Region and GPU type listing
- Instance lifecycle management
- Image management
- Configuration validation
- Error handling

### Security
- Secure token handling
- Input validation
- No hardcoded credentials
