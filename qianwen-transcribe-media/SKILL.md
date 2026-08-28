---
name: qianwen-transcribe-media
description: Check and prepare Windows, macOS, or Linux AI-client environments, then use Qianwen audio/video quick read to export verified original Markdown. Use when users ask a supported agent client to convert local audio or video to text.
---

# 千问视频转文字（跨平台 AI 客户端通用版）

使用当前 AI 客户端提供的本地命令与浏览器自动化能力，将本地音视频上传到千问 AI 音视频速读，导出“原文”Markdown，并校验最终文件。按实际操作系统选择脚本，不绑定客户端名称或固定工具名。

## 平台路由与环境检测

先识别操作系统，再运行对应检测。不要在 macOS/Linux 运行 PowerShell 版，也不要在 Windows 假设 Bash 可用。

Windows：

```powershell
powershell -ExecutionPolicy Bypass -File "<skill目录>\scripts\Test-Environment.ps1" -SkillDirectory "<skill目录>"
```

macOS 或 Linux：

```bash
"<skill目录>/scripts/Test-Environment.sh" "<skill目录>"
```

解析 JSON 中的 `checks`、`requiredActions` 和 `overallStatus`，不得只看退出码。

- `ready`：继续客户端能力检测。
- `fixable`：说明将安装的软件、官方包管理器、用途及权限影响，获得用户授权后运行准备脚本，再重新检测。
- `blocked`：报告不能自动解决的必需项，不创建千问任务。

Windows 可在授权后使用 `winget` 安装当前用户范围的 FFmpeg：

```powershell
powershell -ExecutionPolicy Bypass -File "<skill目录>\scripts\Setup-Environment.ps1" -SkillDirectory "<skill目录>" -InstallFFmpeg
```

macOS 可在授权后使用 Homebrew；Linux 可在授权后使用已存在的 `apt-get`、`dnf` 或 `pacman`。Linux 系统包安装可能触发 `sudo`，必须在执行前获得用户确认：

```bash
"<skill目录>/scripts/Setup-Environment.sh" --install-python --install-ffmpeg
```

可以自动创建用户的 Downloads 目录。不要下载未知脚本、关闭安全软件、修改系统级执行策略，或读取凭据、Cookie、Token 与浏览器存储。FFmpeg 是可选增强依赖，用于本地时长检测。

## 客户端能力检测

读取 [references/client-capabilities.md](references/client-capabilities.md)，将当前会话实际工具映射到以下能力：本地命令执行、浏览器导航、页面读取与操作、本地文件上传、有界等待、下载落盘及用户接管。

工具名称可以不同，但每项能力都要记录真实工具并实际验证。工具只在列表中但未调用时标记 `unverified`。浏览器能点击下载按钮不等于下载落盘已验证；没有专用下载工具或既往成功落盘证据时，`downloadToLocal` 必须为 `unverified`。缺少本地文件上传时，全自动模式为 `blocked`；要求用户手工选择文件后不得声称全自动。缺少专用接管工具但用户能操作可见浏览器时标记 `manual`。

仅当本机必需项和客户端必需能力都通过时，整体环境才是 `ready`。环境初始化不得创建千问任务。

## 输入与媒体预检

- 接受单文件绝对路径、目录绝对路径或明确文件列表。
- 上传前必须获得本次最终输出目录；Downloads 只作临时下载区。
- 保留用户顺序；否则按文件名稳定排序。

Windows：

```powershell
powershell -ExecutionPolicy Bypass -File "<skill目录>\scripts\Preflight-Media.ps1" -SourcePath "<源>" -OutputDirectory "<最终目录>"
```

macOS 或 Linux：

```bash
python3 "<skill目录>/scripts/Preflight-Media.py" --source-path "<源>" --output-directory "<最终目录>"
```

只上传 JSON 中的 `ready` 项；`existing-output` 不重复处理，除非用户明确批准。

- 视频：`mp4, wmv, m4v, flv, rmvb, dat, mov, mkv, webm, avi, mpeg, 3gp, ogg`，最多 6 GB、6 小时。
- 音频：`mp3, wav, m4a, wma, aac, ogg, amr, flac, aiff`，最多 500 MB。
- `ogg` 按保守的 500 MB 上限处理。
- 有 FFmpeg 时检测时长；视频超过 6 小时标记不支持。

上传前还要检查千问“我的记录”中是否已有完整同名记录。已有输出或记录时不自动重复创建。

## 浏览器流程

使用当前客户端已验证的浏览器工具。页面变化后重新读取页面，不依赖旧 DOM ref、snapshot ref、行号或坐标。

1. 打开 `https://www.qianwen.com/discover/audioread`。
2. 登录、扫码或验证码出现时让用户接管，完成后重新读取页面。
3. 定位真实文件输入控件，使用已验证的本地上传能力和当前文件的本机绝对路径。
4. 检查语言、翻译和发言人选项。应用用户要求，否则保留页面当前默认值。
5. 只点击一次 `确认`，验证“任务添加成功，请在「我的记录」查看进展”。
6. 在“我的记录”按完整文件名定位。有界等待并重新读取，直到该记录 `处理成功`；超时报告 `pending`。
7. 打开该行的 `导出`，仅选择 `原文` 和 `.md`；除非用户指定，保留发言人和时间戳当前选项。
8. 记录导出前的 ISO 8601 时间，只点击一次最终导出。
9. 检查浏览器下载状态及本地文件。不要假设受管浏览器一定使用用户的默认 Downloads 目录；发现真实目录后通过 `-DownloadDirectory` 或 `--download-directory` 显式传入。
10. 运行对应归档脚本。

Windows：

```powershell
powershell -ExecutionPolicy Bypass -File "<skill目录>\scripts\Finalize-Transcript.ps1" -SourceFile "<源文件>" -OutputDirectory "<最终目录>" -NotBefore "<导出前ISO时间>"
```

macOS 或 Linux：

```bash
python3 "<skill目录>/scripts/Finalize-Transcript.py" --source-file "<源文件>" --output-directory "<最终目录>" --not-before "<导出前ISO时间>"
```

仅 JSON `status = completed` 且最终文件存在、非空、可读时才算完成。

如果浏览器显示“失败 - 下载错误”、归档脚本返回 `missing-download`，或下载目录对命令环境不可见，读取 [references/download-recovery.md](references/download-recovery.md) 进行错误分型和受控降级。不要仅凭 Chrome 下载记录就断言千问导出接口不可用，也不要修改浏览器 profile、复制认证信息或反复点击导出。

## 批量、失败与报告

- 一个文件完整完成后再处理下一个；列表变化后按完整文件名重新识别。
- 不静默重试上传或导出；先查记录、网络结果和新下载，避免重复任务。一次诊断性重试仍失败后停止自动重试。
- 目标冲突不覆盖；目标目录不可写时停止后续文件。
- 千问失败或处理超时要保留准确状态；映射不清时停止批次。

环境阶段报告操作系统、本机检查、客户端能力映射、自动准备动作、仍需用户处理事项和最终状态。转写阶段逐项报告源路径、千问状态、最终 Markdown 绝对路径或失败原因，并单独列出 `pending`。
