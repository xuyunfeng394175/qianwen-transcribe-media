# AI 客户端能力映射

不要依赖固定工具名或根据客户端名称推断能力。查看当前会话实际工具，并将其映射到下面的能力。

## 必需能力

| 能力 | 验证动作 | 缺失时处理 |
| --- | --- | --- |
| 本地命令执行 | Windows 可运行 PowerShell；macOS/Linux 可运行 Bash 与 Python 3，并读取 JSON | `blocked` |
| 浏览器导航 | 能打开千问音视频速读 URL | `blocked` |
| 页面读取 | 能取得可操作 DOM、accessibility snapshot 或等价结构 | `blocked` |
| 页面操作 | 能点击、输入、选择选项并重新读取页面 | `blocked` |
| 本地文件上传 | 能将当前操作系统的绝对路径设置到真实文件输入控件 | 全自动模式 `blocked` |
| 有界等待 | 能短时等待并再次读取记录状态 | `blocked` |
| 下载落盘 | 专用下载工具或一次真实导出证明 Markdown 能进入命令环境可访问的已知目录 | 无证据时 `unverified`；失败时全自动模式 `blocked` |
| 用户接管 | 有专用接管工具，或能暂停让用户操作可见浏览器 | 登录/验证码出现时必需 |

## 平台注意事项

- Windows 路径通常形如 `C:\media\video.mp4`；macOS/Linux 路径形如 `/Users/name/media/video.mp4` 或 `/home/name/media/video.mp4`。不要转换成另一平台的路径格式。
- macOS 客户端可能需要“文件与文件夹”或“完全磁盘访问权限”；只在系统实际提示且用户确认后处理。
- Linux 桌面会话必须让浏览器下载到 AI 客户端可访问的本地目录。容器或远程会话中的路径不一定等于宿主机路径，无法证明映射时标记 `blocked`。
- 浏览器、AI 客户端和本地命令若运行在不同机器、容器或沙箱中，必须验证上传路径与下载目录对双方都可见。

## 常见客户端示例

- TraeWork `integrated_browser`：可映射导航、snapshot、点击和等待；必须额外确认当前版本是否提供本地文件上传。
- WorkBuddy：检查浏览器或 computer-use 工具是否支持本地文件上传、下载落盘与用户接管；存在浏览器工具不等于 `ready`。若工具列表没有下载/保存文件能力，不能根据点击成功推断文件会出现在 Windows 用户的 Downloads 目录。
- Codex、Claude、Cursor 或其他客户端：使用当前实际暴露的浏览器、MCP 或 computer-use 工具，不照搬另一客户端的函数名。

这些只是识别示例。客户端升级、操作系统变化或远程环境变化后必须重新检测。

## 能力报告

```text
platform: windows|macos|linux
client: <检测到或用户指定的客户端>
commandExecution: ready|blocked
browserNavigation: ready|blocked
pageInspection: ready|blocked
pageInteraction: ready|blocked
localFileUpload: ready|blocked
boundedWait: ready|blocked
downloadToLocal: ready|unverified|blocked
userTakeover: ready|manual|blocked
overallStatus: ready|blocked
toolMapping: <每项能力对应的实际工具名>
```

工具存在但尚未实际调用时标记 `unverified`。环境初始化只验证能力，不创建千问任务。
