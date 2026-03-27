---
name: cfgpu-api
description: Manage GPU cloud instances on CFGPU platform. Use when you need to create, manage, or query GPU instances, regions, GPU types, or images on CFGPU cloud platform.
---

# CFGPU API Skill

Manage GPU cloud instances on CFGPU (https://cfgpu.com) platform.

## When to Use

Use this skill immediately when the user asks any of:

- "manage GPU instances on CFGPU"
- "create GPU instance"
- "check GPU instance status"
- "start/stop/release GPU instance"
- "query available GPU types/regions"
- "manage CFGPU cloud resources"

## Quick Start

### Prerequisites

1. **API Token**: Get your API token from CFGPU platform
2. **Environment Variable**: Set `CFGPU_API_TOKEN` environment variable
   ```bash
   export CFGPU_API_TOKEN="YOUR_API_TOKEN"
   ```

### Basic Usage Examples

```bash
# List available regions
curl -H "Authorization: $CFGPU_API_TOKEN" https://api.cfgpu.com/userapi/v1/region/list

# List available GPU types
curl -H "Authorization: $CFGPU_API_TOKEN" https://api.cfgpu.com/userapi/v1/gpu/list

# Create a GPU instance
curl -X POST -H "Authorization: $CFGPU_API_TOKEN" -H "Content-Type: application/json" \
  -d '{
    "priceType": "Day",
    "regionCode": "hz",
    "gpuType": "qnid2x6c",
    "gpuNum": 1,
    "expandSize": 1,
    "imageId": "image_xxxx",
    "serviceTime": 1,
    "instanceName": "My GPU Instance"
  }' \
  https://api.cfgpu.com/userapi/v1/instance/create
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

Common error codes to handle:

| Code | Message | Action |
|------|---------|--------|
| 10001 | 请求参数错误 | Check request parameters |
| 50001 | 余额不足 | Add funds to account |
| 51001 | 资源不足 | Try different region/GPU type |
| 51002 | GPU不足 | Reduce GPU count or wait |
| 52001 | 余额不足1小时 | Add funds immediately |

## Core Operations

### 1. Region Management

**List Regions**
```bash
GET /userapi/v1/region/list
```

Response:
```json
[
  {
    "code": "hz",
    "name": "杭州"
  }
]
```

### 2. GPU Type Management

**List GPU Types**
```bash
GET /userapi/v1/gpu/list
```

Response:
```json
[
  {
    "code": "qnid2x6c",
    "name": "RTX 4090"
  }
]
```

### 3. Image Management

**List User Images**
```bash
GET /userapi/v1/image/privateList?adaptType=VM
```

**List System Images**
```bash
GET /userapi/v1/image/systemList?adaptType=VM
```

### 4. Instance Management

**Create Instance**
```bash
POST /userapi/v1/instance/create
```

Required parameters:
```json
{
  "regionCode": "string",
  "gpuType": "string",
  "gpuNum": 1,
  "imageId": "string",
  "priceType": "Day|Week|Month|Usage",
  "serviceTime": 1
}
```

**Get Instance Status**
```bash
GET /userapi/v1/instance/{instanceId}/status
```

**Get All Instance Status**
```bash
GET /userapi/v1/instance/status
```

**Start Instance**
```bash
POST /userapi/v1/instance/{instanceId}/start
```

**Stop Instance**
```bash
POST /userapi/v1/instance/{instanceId}/stop
```

**Release Instance**
```bash
POST /userapi/v1/instance/{instanceId}/release
```

**Change Instance Image**
```bash
POST /userapi/v1/instance/{instanceId}/changeImage
```

**Query Instances (Paginated)**
```bash
POST /userapi/v1/instance/page
```

## Usage Patterns

### Pattern 1: Quick Instance Creation

```bash
# 1. Check available regions
REGIONS=$(curl -s -H "Authorization: $CFGPU_API_TOKEN" \
  https://api.cfgpu.com/userapi/v1/region/list)

# 2. Check available GPU types
GPUS=$(curl -s -H "Authorization: $CFGPU_API_TOKEN" \
  https://api.cfgpu.com/userapi/v1/gpu/list)

# 3. Create instance
curl -X POST -H "Authorization: $CFGPU_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "priceType": "Day",
    "regionCode": "hz",
    "gpuType": "qnid2x6c",
    "gpuNum": 1,
    "imageId": "image_exc6f72b",
    "serviceTime": 1,
    "instanceName": "AI-Training-Instance"
  }' \
  https://api.cfgpu.com/userapi/v1/instance/create
```

### Pattern 2: Instance Lifecycle Management

```bash
# Create instance
INSTANCE_ID=$(curl -s -X POST -H "Authorization: $CFGPU_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"priceType": "Day", "regionCode": "hz", "gpuType": "qnid2x6c", "gpuNum": 1, "imageId": "image_xxxx", "serviceTime": 1}' \
  https://api.cfgpu.com/userapi/v1/instance/create | jq -r '.content.instanceId')

# Check status
curl -s -H "Authorization: $CFGPU_API_TOKEN" \
  https://api.cfgpu.com/userapi/v1/instance/$INSTANCE_ID/status

# Stop instance when done
curl -s -X POST -H "Authorization: $CFGPU_API_TOKEN" \
  https://api.cfgpu.com/userapi/v1/instance/$INSTANCE_ID/stop

# Release instance
curl -s -X POST -H "Authorization: $CFGPU_API_TOKEN" \
  https://api.cfgpu.com/userapi/v1/instance/$INSTANCE_ID/release
```

### Pattern 3: Cost Monitoring

```bash
# Check all instances
ALL_INSTANCES=$(curl -s -H "Authorization: $CFGPU_API_TOKEN" \
  https://api.cfgpu.com/userapi/v1/instance/status)

# Filter running instances
RUNNING_INSTANCES=$(echo "$ALL_INSTANCES" | jq -r '.[] | select(.statusCode == "RUNNING") | .instanceId')

# Calculate estimated cost
# (Based on GPU type, duration, and pricing model)
```

## Best Practices

### 1. Cost Optimization

- **Use spot/preemptible instances** when available
- **Monitor usage** and stop instances when not in use
- **Choose appropriate GPU type** for your workload
- **Set up auto-shutdown** for long-running tasks

### 2. Resource Management

- **Check resource availability** before creating instances
- **Use appropriate disk sizes** (30GB system disk, 50GB data disk free)
- **Monitor GPU memory usage**
- **Clean up unused instances** to avoid unnecessary charges

### 3. Security

- **Keep API tokens secure** (use environment variables)
- **Regularly rotate API tokens**
- **Monitor instance access logs**
- **Use secure images** from trusted sources

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Authentication failed | Check API token validity and format |
| Insufficient balance | Add funds to your CFGPU account |
| Resource unavailable | Try different region or GPU type |
| Instance creation failed | Check all required parameters |
| Instance not starting | Check instance status and logs |

### Debugging Commands

```bash
# Test API connectivity
curl -I -H "Authorization: $CFGPU_API_TOKEN" \
  https://api.cfgpu.com/userapi/v1/region/list

# Check account balance (if endpoint available)
# curl -H "Authorization: $CFGPU_API_TOKEN" \
#   https://api.cfgpu.com/userapi/v1/account/balance

# View instance logs (if endpoint available)
# curl -H "Authorization: $CFGPU_API_TOKEN" \
#   https://api.cfgpu.com/userapi/v1/instance/{instanceId}/logs
```

## Integration Examples

### With AI Workloads

```bash
# Create instance for AI training
INSTANCE_ID=$(create_gpu_instance \
  --gpu-type "RTX 4090" \
  --gpu-num 2 \
  --image "pytorch-latest" \
  --duration 24h)

# Setup AI environment
setup_ai_environment $INSTANCE_ID

# Run training job
run_training_job $INSTANCE_ID --model "llama-3b" --dataset "custom"

# Monitor and stop
monitor_training $INSTANCE_ID
stop_instance $INSTANCE_ID
```

### With CI/CD Pipeline

```bash
# In CI/CD script
if [ "$NEEDS_GPU" = "true" ]; then
  INSTANCE_ID=$(create_gpu_instance --duration 2h)
  run_gpu_tests $INSTANCE_ID
  capture_results $INSTANCE_ID
  release_instance $INSTANCE_ID
fi
```

## Related Resources

- [CFGPU Platform](https://cfgpu.com)
- [API Documentation](https://doc.cfgpu.com/API文档/APIToken认证/)
- [Pricing Information](https://cfgpu.com/pricing)
- [Support & Community](https://cfgpu.com/support)

---

**Note**: This skill provides guidance for using CFGPU API. Actual implementation may require additional error handling, retry logic, and security considerations based on your specific use case.