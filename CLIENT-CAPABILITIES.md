# AI 客户端能力映射

本 Skill 支持 Windows、macOS 和 Linux，但完整自动化取决于 AI 客户端的实际能力，不取决于客户端名称。

## 必需能力

| 能力 | 验证动作 | 缺失时处理 |
| --- | --- | --- |
| 本地命令执行 | Windows 可运行 PowerShell；macOS/Linux 可运行 Bash 与 Python 3 | `blocked` |
| 浏览器导航 | 能打开千问音视频速读 URL | `blocked` |
| 页面读取 | 能取得 DOM、accessibility snapshot 或等价结构 | `blocked` |
| 页面操作 | 能点击、输入、选择并重新读取页面 | `blocked` |
| 本地文件上传 | 能把本机绝对路径设置到真实文件输入控件 | 全自动模式 `blocked` |
| 有界等待 | 能短时等待并再次读取记录状态 | `blocked` |
| 下载落盘 | Markdown 能下载到已知本机目录 | `blocked` |
| 用户接管 | 能暂停并让用户处理登录、扫码或验证码 | 登录时必需 |

## 跨平台边界

- 保持原生路径格式：Windows 使用盘符路径，macOS/Linux 使用 POSIX 绝对路径。
- macOS 的文件访问权限只在系统提示并经用户确认后调整。
- Linux 容器、远程桌面或宿主机路径映射不明确时，不得假设文件上传和下载可用。
- AI 客户端、浏览器和命令执行环境必须能访问同一源文件与下载目录。

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
downloadToLocal: ready|blocked
userTakeover: ready|manual|blocked
overallStatus: ready|blocked
toolMapping: <真实工具名映射>
```

工具未成功调用时标记 `unverified`。具体规则见可安装 Skill 内的 `references/client-capabilities.md`。
