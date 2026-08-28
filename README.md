# qianwen-transcribe-media

[简体中文](README.md) | [English](README.en.md)

一个跨平台 Agent Skill：让具备浏览器自动化和本地命令能力的 AI 客户端，通过千问 AI 音视频速读，将本地音视频转写为经过本地校验的“原文”Markdown。

它不实现转录模型，而是组织一条可审计的工作流：环境检测、媒体预检、网页上传、等待处理、导出、移动和结果校验。TraeWork、WorkBuddy、Codex、Claude、Cursor 及其他兼容 Agent Skills 的客户端，都可按能力契约接入。

## 为什么做这个项目

在本地运行 Whisper 等转录模型会持续占用 CPU、GPU、内存和电量。电脑配置不高、正在同时剪辑视频，或需要处理长音视频时，容易出现发热、卡顿和转写速度慢的问题。

这个项目把主要转录计算交给千问云端完成，本机只负责环境检查、上传、等待、下载和结果校验。这样即使电脑性能有限，也能减少本地资源压力、保持其他软件相对流畅，并合理利用千问账号已有的免费额度或平台权益。

说得直白一点：让大平台承担重计算，自己的电脑少受罪，在遵守服务条款和配额规则的前提下，顺手“薅一下大平台的羊毛”。

项目不会绕过收费、配额、登录验证或其他平台限制，也不保证服务永久免费。实际可用额度、处理限制和收费规则以千问当前页面及服务条款为准。

> [!IMPORTANT]
> 这是社区非官方项目，与阿里巴巴、千问及文中提及的 AI 客户端没有隶属或背书关系。媒体会上传到第三方云端，请勿用于不允许外传的敏感内容，并遵守千问服务条款和所在地法律。

## 支持范围

| 平台 | 本地脚本 | 安装器 | 自动化状态 |
|---|---|---|---|
| Windows 10/11 x64 | PowerShell 5.1+ | `install-skill.ps1` | Windows CI 已覆盖本地流程 |
| macOS | Bash + Python 3.9+ | `install-skill.sh` | macOS CI 覆盖本地流程 |
| Linux | Bash + Python 3.9+ | `install-skill.sh` | Ubuntu CI 覆盖本地流程 |

“本地流程”包括 Skill 安装、脚本语法、媒体预检和下载归档校验，不包括真实账号登录、媒体上传或千问网页端到端操作。完整自动化还取决于当前 AI 客户端是否具备以下能力：

1. 执行本地命令。
2. 浏览器导航、页面读取和交互。
3. 将本机绝对路径传给网页文件输入框。
4. 有界等待并判断页面状态。
5. 下载文件并访问浏览器下载目录。
6. 登录、扫码或验证码时允许用户接管。

详细契约见 [CLIENT-CAPABILITIES.md](CLIENT-CAPABILITIES.md)。Linux 若运行在容器、远程主机或 WSL 中，还必须确认命令环境、浏览器与上传工具能访问同一份文件路径。

## 工作方式

1. 自动识别 Windows、macOS 或 Linux，并选择对应脚本。
2. 检测运行时、目录权限、千问 HTTPS、可选 FFmpeg，以及客户端能力。
3. 校验媒体格式、大小、时长、输出冲突和路径可访问性。
4. 在千问中按完整文件名查重，逐个上传并等待处理。
5. 仅导出“原文”Markdown，定位本次新下载并移动到指定目录。
6. 验证结果为非空、UTF-8 可读文件；不覆盖既有转写。

## 要求

所有平台均需要：

- 千问账号及可访问的[音视频速读页面](https://www.qianwen.com/discover/audioread)。
- 支持 Agent Skills、本地命令和上述浏览器能力的 AI 客户端。
- 可见浏览器或人工接管机制。

平台运行时：

- Windows：Windows PowerShell 5.1 或更高版本。
- macOS/Linux：Bash 和 Python 3.9 或更高版本。
- FFmpeg/`ffprobe` 可选，用于本地读取媒体时长。

环境脚本可以在用户明确授权后安装依赖。macOS 使用 Homebrew；Linux 支持 `apt-get`、`dnf` 或 `pacman`，可能触发 `sudo`。提权、软件安装、许可确认和安全警告不能静默执行。

## 安装

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" -Client TraeWork
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" -Client WorkBuddy
```

其他客户端可选择 `Codex`、`Claude`、`Cursor`、`Agents`，或指定自定义目录：

```powershell
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" `
  -Client Custom `
  -DestinationRoot "C:\path\to\skills"
```

### macOS / Linux

```bash
chmod +x install-skill.sh
./install-skill.sh --client Codex
./install-skill.sh --client WorkBuddy
```

自定义目录：

```bash
./install-skill.sh --client Custom --destination-root "$HOME/path/to/skills"
```

`Auto` 只在检测到唯一已知客户端目录时自动选择。多客户端共存时请明确指定，避免安装错位。已有同名 Skill 会先备份再替换。

安装后重启或重载客户端，把 [TASK-TEMPLATES.md](TASK-TEMPLATES.md) 中的“首次环境初始化”发给 AI。

## 安全边界

- 不读取或保存密码、Cookie、Token、浏览器存储或私钥。
- 不绕过登录、验证码、安全软件、客户端限制或系统策略。
- 安装软件、管理员权限、`sudo` 和许可确认必须得到用户明确授权。
- 缺少真实本地文件上传能力时必须报告 `blocked`，不能假装全自动。
- 不静默重试上传或导出，避免重复任务和文件映射错误。
- 不覆盖既有转写；下载移动并验证成功后才算完成。
- 默认串行处理文件，不承诺批量并发。

## 仓库结构

```text
qianwen-transcribe-media/
|-- qianwen-transcribe-media/
|   |-- SKILL.md
|   |-- agents/openai.yaml       # 兼容客户端可选的 UI 元数据
|   |-- references/client-capabilities.md
|   `-- scripts/                 # PowerShell、Bash 和 Python 辅助脚本
|-- install-skill.ps1            # Windows 安装器
|-- install-skill.sh             # macOS/Linux 安装器
|-- CLIENT-CAPABILITIES.md
|-- TASK-TEMPLATES.md
`-- original-codex-version/      # 初始版本留档
```

## 验证状态

- Agent Skill 结构校验。
- Windows：PowerShell 语法、自定义安装、媒体预检。
- macOS/Ubuntu：Shell 语法、Python 编译、自定义安装、媒体预检、下载归档。
- 自动化测试不登录千问、不访问私人账号、不上传媒体。
- 各 AI 客户端与千问网页的真实端到端流程仍需按客户端版本实机验证。

## 适用边界

该方案适合联网、允许上传云端、希望获得千问结构化原文的场景。隐私敏感、需要离线、本地批量并发或可控模型推理时，应优先选择 Whisper、Buzz、whisperX 等本地方案。

## 贡献与许可

欢迎补充客户端能力映射、平台测试和错误处理。提交前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 与 [SECURITY.md](SECURITY.md)。项目使用 [MIT License](LICENSE)。
