# AI 客户端任务模板

## 首次环境初始化

```text
请使用 qianwen-transcribe-media skill。先执行完整环境检测：运行 Windows PowerShell 检测，并阅读 CLIENT-CAPABILITIES.md，将当前会话实际工具映射到每一项必需能力。根据结果自动准备当前用户范围内可安全安装的环境，每次变更后复检。允许创建所需用户目录并通过 winget 安装 FFmpeg；如果需要管理员权限、系统级修改、客户端或 MCP 重载、登录千问、扫码或验证码，请暂停并明确告诉我需要做什么。达到 ready 后只报告检测结果，不上传媒体。
```

## 单文件转写

```text
请使用 qianwen-transcribe-media skill 转写：
源文件：C:\完整路径\video.mp4
最终输出目录：D:\完整路径\transcripts
设置：语言、翻译和发言人模式保持网页当前默认值。

先检测本机环境和当前 AI 客户端能力，不满足时按 skill 规则自动准备并复检。然后完成查重、上传、等待、仅导出原文 Markdown、移动和校验。登录或验证码时让我接管。不要覆盖目标文件，不要重复提交千问任务。
```

## 批量转写

```text
请使用 qianwen-transcribe-media skill 处理：
源目录：D:\完整路径\media
最终输出目录：D:\完整路径\transcripts
顺序：按文件名稳定排序

先检测本机环境和当前 AI 客户端能力。之后每个文件完成预检、查重、上传、等待、导出、移动和校验后再处理下一个。最后逐项报告成功、跳过、失败和 pending。
```
