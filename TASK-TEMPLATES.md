# AI 客户端任务模板

路径必须使用运行 AI 客户端那台电脑上的本机绝对路径。Windows 示例使用 `C:\...`，macOS/Linux 示例使用 `/Users/...` 或 `/home/...`；不要混用路径格式。

## 首次环境初始化

```text
请使用 qianwen-transcribe-media skill。先自行检测当前操作系统和架构，再选择对应的本地脚本：Windows 使用 PowerShell，macOS/Linux 使用 Bash + Python。阅读 CLIENT-CAPABILITIES.md，将当前会话实际工具映射到每一项必需能力，并验证命令环境、浏览器、上传工具和下载目录是否能访问同一份本机路径。

所有使用本模板的 AI 客户端都必须使用唯一转写后端：千问网页端 AI 音视频速读（`transcriptionProvider: qianwen-web-audioread`）。禁止安装、调用或切换到 Whisper、whisperX、Vosk、系统语音识别或其他本地/第三方转写服务。能力不足时必须停止并报告 `blocked`，不得自行改变方案。

下载能力必须实测，不能因为能点击“导出”就默认下载落盘成功。若出现“失败 - 下载错误”或找不到新 Markdown，读取 qianwen-transcribe-media/references/download-recovery.md；不要反复导出或重新上传。必要时让我在可见浏览器完成一次下载，然后使用该文件绝对路径继续校验和归档。

如果当前客户端需要通过 CDP/远程调试连接 Chrome，先使用 qianwen-transcribe-media/scripts/Launch-Debug-Chrome.py 启动专用、非默认的 user-data-dir；不要把日常 Chrome 的默认用户数据目录传给远程调试参数。首次打开专用窗口时暂停，让我扫码或登录千问；我确认完成后再继续。保留这个专用目录供后续复用，不复制或读取日常浏览器的密码、Cookie、Token 或 profile 文件。

先只检测，不上传媒体。对于当前用户范围内、无需提权且已获我明确授权的准备动作，可创建所需目录并安装我已同意的依赖；涉及管理员权限、sudo、系统级修改、软件安装、许可、安全警告、客户端或 MCP 重载、登录千问、扫码或验证码时必须暂停，说明具体动作并等待我决定。每次变更后复检。最后报告 ready、fixable 或 blocked，以及尚未实机验证的客户端能力。
```

## 低 Token 单文件转写

```text
使用 qianwen-transcribe-media skill，以低 Token 模式处理。

后端锁定：`transcriptionProvider: qianwen-web-audioread`。禁止任何本地或第三方转写 fallback；千问链路失败就记录失败，不要安装或调用本地语音识别。

源文件：<当前系统的本机绝对路径>
最终输出目录：<当前系统的本机绝对路径>

规则：
1. 只读取 SKILL.md；只有遇到对应异常才读取 reference。
2. 环境和 CDP 只检测一次；已有有效 lease 时直接复用。
3. 浏览器每次只返回目标文件状态，不返回整页快照或全量历史。
4. 上传后等待 30 秒；处理中每 60 秒检查；超过 10 分钟改为每 120 秒。
5. 每个文件最多一次上传、一次确认、一次最终导出；不要静默重试。
6. 转写阶段不要读取完整 Markdown，只检查文件存在、非空、UTF-8。
7. 正常成功只输出一行：completed | input=<文件名> | output=<绝对路径>
8. 只有异常、人工接管或状态变化时才输出详细信息。
```

## 低 Token 批量转写

```text
使用 qianwen-transcribe-media skill，以低 Token 模式处理：
源目录：<当前系统的本机绝对路径>
最终输出目录：<当前系统的本机绝对路径>
状态目录：<当前系统的本机绝对路径>

后端锁定：`transcriptionProvider: qianwen-web-audioread`。禁止任何本地或第三方转写 fallback；单个文件的千问链路失败只记录该文件状态，不得改用本地模型继续。

启动时用 Batch-State.py create 建立或加载任务状态。环境、客户端能力和 CDP 只检测一次；每轮只调用 claim，完成一个文件后立即 record。不要读取整份 manifest、events.jsonl 或对话历史。每处理约 50 个文件建立 checkpoint；中断恢复时只读取 status 和 claim。文件串行处理，遇到登录、验证码、歧义、重复任务、下载失败或输出冲突时暂停该文件并记录准确状态，不自动猜测或静默重试。最终只报告统计摘要和 failed/pending/blocked 项目。
```

## 单文件转写

Windows 路径示例：

```text
请使用 qianwen-transcribe-media skill 转写：
源文件：C:\完整路径\video.mp4
最终输出目录：D:\完整路径\transcripts
设置：语言、翻译和发言人模式保持网页当前默认值。

转写后端固定为千问网页端 AI 音视频速读。禁止改用或安装任何本地/第三方语音转写工具；若千问不可用，停止并报告 `blocked` 或 `failed`，不要兜底。

先检测操作系统、环境和当前 AI 客户端能力，再按 skill 选择对应脚本。完成本地预检、千问精确文件名查重、上传、等待、仅导出原文 Markdown、移动和校验。登录或验证码时让我接管。不要覆盖目标文件，不要静默重试，不要重复提交任务。

若使用远程调试 Chrome，先报告 `browserDebug: ready|unverified|blocked`、CDP 端点和专用 UDD；未验证专用 UDD 时不要上传媒体。
```

macOS/Linux 路径示例：

```text
请使用 qianwen-transcribe-media skill 转写：
源文件：/Users/me/Videos/video.mp4
最终输出目录：/Users/me/Documents/transcripts
设置：语言、翻译和发言人模式保持网页当前默认值。

转写后端固定为千问网页端 AI 音视频速读。禁止改用或安装任何本地/第三方语音转写工具；若千问不可用，停止并报告 `blocked` 或 `failed`，不要兜底。

先检测操作系统、环境和当前 AI 客户端能力，再按 skill 选择对应脚本。确认浏览器和上传工具能读取该绝对路径，然后完成本地预检、千问精确文件名查重、上传、等待、仅导出原文 Markdown、移动和校验。登录或验证码时让我接管。不要覆盖目标文件，不要静默重试，不要重复提交任务。
```

## 批量转写

```text
请使用 qianwen-transcribe-media skill 处理：
源目录：<当前系统的本机绝对路径>
最终输出目录：<当前系统的本机绝对路径>
顺序：按文件名稳定排序

转写后端固定为千问网页端 AI 音视频速读。禁止改用或安装任何本地/第三方语音转写工具；单个文件的千问链路失败只记录该文件状态，不得改用本地模型继续。

先检测操作系统、环境、路径可访问性和当前 AI 客户端能力。每个文件必须串行完成预检、精确文件名查重、上传、等待、导出、移动和校验后再处理下一个。遇到登录或验证码让我接管；遇到歧义、重复任务或输出冲突时停止该文件，不要猜测或覆盖。最后逐项报告 completed、skipped、failed、pending 或 blocked。
```
