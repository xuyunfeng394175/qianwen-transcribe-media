# AI 客户端任务模板

路径必须使用运行 AI 客户端那台电脑上的本机绝对路径。Windows 示例使用 `C:\...`，macOS/Linux 示例使用 `/Users/...` 或 `/home/...`；不要混用路径格式。

## 首次环境初始化

```text
请使用 qianwen-transcribe-media skill。先自行检测当前操作系统和架构，再选择对应的本地脚本：Windows 使用 PowerShell，macOS/Linux 使用 Bash + Python。阅读 CLIENT-CAPABILITIES.md，将当前会话实际工具映射到每一项必需能力，并验证命令环境、浏览器、上传工具和下载目录是否能访问同一份本机路径。

下载能力必须实测，不能因为能点击“导出”就默认下载落盘成功。若出现“失败 - 下载错误”或找不到新 Markdown，读取 qianwen-transcribe-media/references/download-recovery.md；不要反复导出或重新上传。必要时让我在可见浏览器完成一次下载，然后使用该文件绝对路径继续校验和归档。

先只检测，不上传媒体。对于当前用户范围内、无需提权且已获我明确授权的准备动作，可创建所需目录并安装我已同意的依赖；涉及管理员权限、sudo、系统级修改、软件安装、许可、安全警告、客户端或 MCP 重载、登录千问、扫码或验证码时必须暂停，说明具体动作并等待我决定。每次变更后复检。最后报告 ready、fixable 或 blocked，以及尚未实机验证的客户端能力。
```

## 单文件转写

Windows 路径示例：

```text
请使用 qianwen-transcribe-media skill 转写：
源文件：C:\完整路径\video.mp4
最终输出目录：D:\完整路径\transcripts
设置：语言、翻译和发言人模式保持网页当前默认值。

先检测操作系统、环境和当前 AI 客户端能力，再按 skill 选择对应脚本。完成本地预检、千问精确文件名查重、上传、等待、仅导出原文 Markdown、移动和校验。登录或验证码时让我接管。不要覆盖目标文件，不要静默重试，不要重复提交任务。
```

macOS/Linux 路径示例：

```text
请使用 qianwen-transcribe-media skill 转写：
源文件：/Users/me/Videos/video.mp4
最终输出目录：/Users/me/Documents/transcripts
设置：语言、翻译和发言人模式保持网页当前默认值。

先检测操作系统、环境和当前 AI 客户端能力，再按 skill 选择对应脚本。确认浏览器和上传工具能读取该绝对路径，然后完成本地预检、千问精确文件名查重、上传、等待、仅导出原文 Markdown、移动和校验。登录或验证码时让我接管。不要覆盖目标文件，不要静默重试，不要重复提交任务。
```

## 批量转写

```text
请使用 qianwen-transcribe-media skill 处理：
源目录：<当前系统的本机绝对路径>
最终输出目录：<当前系统的本机绝对路径>
顺序：按文件名稳定排序

先检测操作系统、环境、路径可访问性和当前 AI 客户端能力。每个文件必须串行完成预检、精确文件名查重、上传、等待、导出、移动和校验后再处理下一个。遇到登录或验证码让我接管；遇到歧义、重复任务或输出冲突时停止该文件，不要猜测或覆盖。最后逐项报告 completed、skipped、failed、pending 或 blocked。
```
