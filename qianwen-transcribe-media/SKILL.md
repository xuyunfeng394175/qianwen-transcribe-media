---
name: qianwen-transcribe-media
description: Checks and prepares a Windows AI-client environment, then uses Qianwen audio/video quick read to export verified original Markdown. Use when users ask any supported agent client to convert local audio or video to text.
---

# 千问视频转文字（Windows AI 客户端通用版）

使用当前 AI 客户端实际提供的本地命令和浏览器自动化能力，将 Windows 本地音视频上传到千问 AI 音视频速读，导出“原文”Markdown，并校验最终文件。不要绑定某个客户端或照搬其他客户端的工具名。

## 阶段 0：环境检测与准备

任何上传前先运行：

```powershell
powershell -ExecutionPolicy Bypass -File "<skill目录>\scripts\Test-Environment.ps1" -SkillDirectory "<skill目录>"
```

解析 JSON 中的 `checks`、`requiredActions` 和 `overallStatus`，不得只看退出码。

- `ready`：继续客户端能力检测。
- `fixable`：运行准备脚本并重新检测：

```powershell
powershell -ExecutionPolicy Bypass -File "<skill目录>\scripts\Setup-Environment.ps1" -SkillDirectory "<skill目录>" -InstallFFmpeg
```

- 可以自动创建用户目录和 Downloads；获得当前用户范围安装授权后，可通过 `winget` 安装 FFmpeg 并刷新当前进程 PATH。
- 软件安装前说明软件、来源和用途。触发管理员提权、系统级安装、许可确认或安全警告时暂停并请求确认。
- 不下载未知脚本，不关闭安全软件，不修改系统级执行策略，不读取凭据、Cookie、Token 或浏览器存储。
- FFmpeg 是推荐增强依赖，用于本地时长检查。`winget` 缺失时不要从随机网址下载安装包，可报告官方人工安装路径或继续由千问检查时长。

## 客户端能力检测

读取 [references/client-capabilities.md](references/client-capabilities.md)，按其中的报告格式映射当前会话实际工具。至少检测：

1. 能运行本地 PowerShell 并读取 JSON。
2. 能导航到指定 URL 并读取当前页面结构。
3. 能点击、输入、选择选项，并在页面变化后重新读取。
4. 能把 Windows 绝对路径上传到真实 `<input type="file">`。
5. 能执行有界等待、重新检查记录状态。
6. 浏览器下载可落到已知本机目录。
7. 登录、扫码或验证码时，有专用人工接管工具，或可暂停让用户操作可见浏览器。

工具名称可以不同，但必须记录每项能力对应的真实工具并实际验证。工具只出现在列表中、尚未成功调用时标记 `unverified`。缺少本地文件上传能力时，全自动模式为 `blocked`；要求用户手工选择文件后不能声称全自动。缺少专用接管工具但可让用户操作可见浏览器时，标记 `manual`，不是阻塞。

仅当 PowerShell 必需项和客户端必需能力都通过时，整体环境才是 `ready`。环境初始化模式不得创建千问任务。

## 输入与媒体预检

- 接受单文件绝对路径、目录绝对路径或明确文件列表。
- 上传前必须获得本次最终输出目录；不沿用历史路径。Downloads 仅为临时下载区。
- 保留用户顺序；否则按文件名稳定排序。

```powershell
powershell -ExecutionPolicy Bypass -File "<skill目录>\scripts\Preflight-Media.ps1" -SourcePath "<源>" -OutputDirectory "<最终目录>"
```

读取 JSON。仅 `ready` 项可上传；`existing-output` 不重复处理，除非用户明确批准。

- 视频：`mp4, wmv, m4v, flv, rmvb, dat, mov, mkv, webm, avi, mpeg, 3gp, ogg`，最多 6 GB、6 小时。
- 音频：`mp3, wav, m4a, wma, aac, ogg, amr, flac, aiff`，最多 500 MB。
- `ogg` 类型有歧义，脚本按保守的 500 MB 上限。
- 有 FFmpeg 时检测时长；视频超过 6 小时标记不支持。

上传前还要检查千问“我的记录”是否已有完整同名记录。已有输出或记录时不自动重复创建。

## 浏览器流程

使用当前客户端已验证的浏览器工具。页面变化后重新读取页面；DOM ref、snapshot ref、行号或坐标可能失效，不依赖旧定位信息。

1. 打开 `https://www.qianwen.com/discover/audioread`。
2. 登录、扫码或验证码出现时让用户接管，完成后重新读取页面。
3. 定位真实文件输入控件，使用已验证的本地上传能力和当前文件 Windows 绝对路径。
4. 检查语言、翻译和发言人选项。应用用户要求，否则保留页面当前默认值。
5. 只点击一次 `确认`，验证“任务添加成功，请在「我的记录」查看进展”。
6. 在“我的记录”按完整文件名定位。短等待后重新读取，直到该记录 `处理成功`；超时报告 `pending`。
7. 打开该行的 `导出`，仅选择 `原文` 和 `.md`；除非用户指定，保留发言人和时间戳当前选项。
8. 记录导出前时间，只点击一次最终导出。
9. 运行归档脚本：

```powershell
powershell -ExecutionPolicy Bypass -File "<skill目录>\scripts\Finalize-Transcript.ps1" -SourceFile "<源文件>" -OutputDirectory "<最终目录>" -NotBefore "<导出前ISO时间>"
```

仅 JSON `status = completed` 且最终文件存在、非空、可读时才算完成。

## 批量、失败与报告

- 一个文件完整完成后再处理下一个；每次列表变化后按完整文件名重新识别。
- 不静默重试上传或导出；先查记录和新下载，避免重复任务。
- 目标冲突不覆盖；目标目录不可写时停止后续文件。
- 千问失败或处理超时要保留准确状态；映射不清时停止批次。

环境阶段报告本机检查、客户端能力映射、自动准备动作、仍需用户处理的事项和最终状态。转写阶段逐项报告源路径、千问状态、最终 Markdown 绝对路径或失败原因，并单独列出 `pending`。
