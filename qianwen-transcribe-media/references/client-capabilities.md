# AI 客户端能力映射

不要依赖固定工具名。查看当前会话实际可用的工具，并映射到下面的能力。不要仅根据客户端名称推断工具存在。

## 必需能力

| 能力 | 验证动作 | 缺失时处理 |
| --- | --- | --- |
| 本地命令执行 | 能运行 PowerShell 脚本并读取 JSON | `blocked` |
| 浏览器导航 | 能打开千问音视频速读 URL | `blocked` |
| 页面读取 | 能取得可操作 DOM、accessibility snapshot 或等价结构 | `blocked` |
| 页面操作 | 能点击、输入、选择选项并重新读取页面 | `blocked` |
| 本地文件上传 | 能把指定 Windows 绝对路径设置到真实文件输入控件 | 全自动模式 `blocked` |
| 有界等待 | 能短时等待并再次读取记录状态 | `blocked` |
| 下载落盘 | 导出的 Markdown 能进入已知本机下载目录 | `blocked` |
| 用户接管 | 有专用接管工具，或能暂停让用户操作可见浏览器 | 登录/验证码出现时必需 |

## 常见客户端示例

- TraeWork `integrated_browser`：导航、snapshot、点击和等待可直接映射；必须额外确认当前版本是否暴露本地文件上传工具。
- WorkBuddy：检查其浏览器或 computer-use 工具是否支持本地文件上传和用户接管；不能只因存在浏览器工具就判断 ready。
- Codex、Claude、Cursor 或其他客户端：使用当前实际暴露的浏览器、MCP 或 computer-use 工具映射，不照搬其他客户端的函数名。

这些只是识别示例，不是固定依赖。客户端升级后应重新检测。

## 能力报告

上传前报告：

```text
client: <检测到或用户指定的客户端>
commandExecution: ready|blocked
browserNavigation: ready|blocked
pageInspection: ready|blocked
pageInteraction: ready|blocked
localFileUpload: ready|blocked
boundedWait: ready|blocked
downloadToLocal: ready|blocked
userTakeover: ready|manual|blocked
overallStatus: ready|blocked
toolMapping: <每项能力对应的实际工具名>
```

工具存在但尚未实际调用时标记为 `unverified`，不能提前写 `ready`。环境初始化模式只验证能力，不创建千问任务。
