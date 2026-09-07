# 转写后端政策

```text
transcriptionProvider: qianwen-web-audioread
providerSwitching: forbidden
localTranscriptionFallback: forbidden
thirdPartyTranscriptionFallback: forbidden
```

## 执行规则

1. 本 Skill 只负责千问网页端音视频速读：网页上传、等待、导出“原文” `.md` 和本地校验。
2. 任何本地语音识别模型、系统语音识别功能或其他云服务都不属于本 Skill 的后端。
3. 千问不可用时必须保留真实状态并停止：能力不足用 `blocked`，仍在处理用 `pending`，已知失败用 `failed`。
4. 不得以“帮助完成任务”为理由自动安装或启动本地转写软件，不得静默改变用户选择的后端。
5. FFmpeg/ffprobe 只可用于媒体预检和元数据读取，不能读取音频并生成文字。

## 完成判定

只有同时满足以下条件才可报告 `completed`：

- 千问页面中的对应记录明确显示处理成功；
- 本次导出的 Markdown 文件存在、非空且可读；
- 文件被归档到用户指定的最终输出目录；
- 没有使用任何本地或其他第三方转写引擎。

客户端无法证明这些条件时，必须报告未完成，不得用本地结果填补。
