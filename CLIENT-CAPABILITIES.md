# AI 客户端能力映射

本 Skill 支持 Windows、macOS 和 Linux，但完整自动化取决于 AI 客户端的实际能力，不取决于客户端名称。

## 后端不可切换

本项目的 `transcriptionProvider` 固定为 `qianwen-web-audioread`。能力检测失败只允许输出 `blocked`、`pending` 或 `failed`，不允许客户端安装或调用 Whisper、whisperX、Vosk、系统语音识别或其他转写服务作为兜底。FFmpeg/ffprobe 仅用于媒体预检，不是转写后端。

## 必需能力

| 能力 | 验证动作 | 缺失时处理 |
| --- | --- | --- |
| 本地命令执行 | Windows 可运行 PowerShell；macOS/Linux 可运行 Bash 与 Python 3 | `blocked` |
| 浏览器导航 | 能打开千问音视频速读 URL | `blocked` |
| 页面读取 | 能取得 DOM、accessibility snapshot 或等价结构 | `blocked` |
| 页面操作 | 能点击、输入、选择并重新读取页面 | `blocked` |
| 本地文件上传 | 能把本机绝对路径设置到真实文件输入控件 | 全自动模式 `blocked` |
| 有界等待 | 能短时等待并再次读取记录状态 | `blocked` |
| 下载落盘 | 专用下载工具或真实导出证明 Markdown 能进入命令环境可访问的已知目录 | 无证据时 `unverified`；失败时全自动模式 `blocked` |
| 用户接管 | 能暂停并让用户处理登录、扫码或验证码 | 登录时必需 |
| 远程调试浏览器 | 若客户端通过 CDP 连接 Chrome，能验证专用非默认 UDD 和本机端点 | `blocked`；不允许退回日常 Chrome 默认 UDD |

## 跨平台边界

- 保持原生路径格式：Windows 使用盘符路径，macOS/Linux 使用 POSIX 绝对路径。
- macOS 的文件访问权限只在系统提示并经用户确认后调整。
- Linux 容器、远程桌面或宿主机路径映射不明确时，不得假设文件上传和下载可用。
- AI 客户端、浏览器和命令执行环境必须能访问同一源文件与下载目录。
- 客户端自带浏览器工具不等于已经具备可用 CDP；只有实际验证过端点和专用 UDD，才可标记远程调试就绪。
- 专用调试 UDD 首次通常需要用户在新窗口扫码或登录；登录后保留该 UDD，后续可复用，不复制日常 profile。

## 能力报告

```text
platform: windows|macos|linux
client: <客户端>
commandExecution: ready|blocked
browserNavigation: ready|blocked
pageInspection: ready|blocked
pageInteraction: ready|blocked
localFileUpload: ready|blocked
boundedWait: ready|blocked
downloadToLocal: ready|unverified|blocked
userTakeover: ready|manual|blocked
browserDebugging: ready|unverified|blocked
overallStatus: ready|blocked
toolMapping: <真实工具名映射>
```

工具未成功调用时标记 `unverified`。具体规则见可安装 Skill 内的 `references/client-capabilities.md`。

## 低 Token 批处理契约

客户端应把重复的文件排序、状态保存和恢复交给 Skill 的本地脚本，而不是把完整清单和历史输出放进对话上下文。批量任务启动时运行一次 `Batch-State.py create`，处理循环只执行 `claim`、浏览器窄状态查询、归档脚本和 `record`；恢复时只执行 `status` 和 `claim`。`claim` 会原子地把一个 `ready` 文件标为 `processing`，避免多个客户端重复处理。

浏览器状态查询只返回以下字段或等价字段：

```json
{"fileName":"example.mp4","status":"处理中|处理成功|处理失败","hasExportButton":false}
```

禁止返回整页 DOM、全量历史、无关导航、下载历史、Cookie、Token、Local Storage 或转写正文。环境检测和 CDP 检查有有效租约时复用；租约只保存平台、客户端、端点、专用 UDD 和过期时间，不保存身份信息。
