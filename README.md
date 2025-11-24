# Auto Wallpager

一个自动更换桌面壁纸的命令行应用程序，可以连接到 ComfyUI 服务器生成 AI 图像并将其设置为 Windows 桌面壁纸。

## 功能特点

- 自动从 ComfyUI 服务器获取 AI 生成的图像并设置为桌面背景
- 可配置的图像生成参数（模型、标签等）
- REST API 控制接口
- 支持定时自动更换壁纸
- 支持黑名单标签过滤不想要的内容

## 安装

确保系统中已安装 Dart SDK。

```bash
# 克隆项目
git clone <repository-url>
cd auto_wallpager

# 安装依赖
dart pub get
```

## 使用方法

### 启动服务模式

```bash
dart run bin/main.dart --deamon [-u <comfyui_url>] [-t <interval_minutes>] [-c <config_file>]
```

参数说明：
- `-d, --deamon`: 以守护进程模式启动服务
- `-u, --url`: ComfyUI 服务器地址，默认为 http://127.0.0.1:8188
- `-t, --time`: 更换壁纸的时间间隔（分钟），默认为 10 分钟
- `-c, --config`: 配置文件路径，默认为 config.json

例如：
```bash
dart run bin/main.dart --deamon --url http://127.0.0.1:8188 --time 5
```

### 触发立即更换壁纸

当服务正在运行时，可以通过以下命令触发立即更换壁纸：

```bash
dart run bin/main.dart
```

或者直接访问 API：
```bash
curl http://127.0.0.1:8987/nextPaper
```

## API 接口

服务启动后会监听本地 8987 端口，提供以下 REST API：

- `POST /config` - 更新配置
- `GET /nextPaper` - 立即更换壁纸
- `GET /pause` - 暂停自动更换
- `GET /restart` - 重启定时任务

## 配置文件

默认配置文件为 `config.json`，包含以下字段：

```json
{
  "address": "http://127.0.0.1:8188",
  "duration": 5,
  "model": "your_model.safetensors",
  "tag_model": "dart-v2-sft",
  "rating": "general",
  "block_tags": ["nsfw"],
  "target": {
    "name": "character_name",
    "product": "copyright_name"
  }
}
```

字段说明：
- `address`: ComfyUI 服务器地址
- `duration`: 更换壁纸间隔（分钟）
- `model`: 使用的模型文件名
- `tag_model`: 标签模型
- `rating`: 内容评级（如 general, sensitive, questionable, explicit）
- `block_tags`: 黑名单标签列表
- `target`: 目标角色或作品信息

## 开发

### 运行测试

```bash
dart test
```

### 构建可执行文件

```bash
dart compile exe bin/main.dart -o auto_wallpager.exe
```

## 依赖

- args: 命令行参数解析
- dio: HTTP 客户端
- path: 路径处理
- win32: Windows API 调用
- web_socket: WebSocket 连接
- uuid: UUID 生成
- collection: 数据集合处理
- json_annotation: JSON 序列化
- shelf: HTTP 服务器
- shelf_router: 路由处理

## 许可证

详见 LICENSE 文件。