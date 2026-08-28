# qianwen-transcribe-media

[简体中文](README.md) | [English](README.en.md)

一个面向 Windows AI 客户端的 Agent Skill：通过千问 AI 音视频速读，将本地音视频转写为经过本地校验的“原文”Markdown。

项目采用能力驱动设计，不绑定固定客户端或工具名称。TraeWork、WorkBuddy、Codex、Claude、Cursor，以及其他支持 Agent Skills、浏览器自动化和本地命令执行的客户端，都可以先检测自身能力，再决定是否执行完整自动化流程。

> [!IMPORTANT]
> 这是社区非官方项目，与阿里巴巴、千问及文中提及的 AI 客户端没有隶属或背书关系。网页结构、服务限制和可用功能可能变化，请遵守千问服务条款及所在地法律。

## 工作方式

1. 检测 Windows、PowerShell、目录权限、千问 HTTPS、`winget` 和 FFmpeg。
2. 将当前客户端工具映射到浏览器导航、页面读取、交互、本地文件上传、等待、下载和用户接管能力。
3. 对媒体格式、大小、时长、目标目录和既有输出做本地预检。
4. 在千问中按完整文件名查重，逐个上传、等待和导出“原文”Markdown。
5. 依据导出时间和源文件名定位下载，将其移动到指定目录并验证非空、可读。

## 要求

- Windows x64
- Windows PowerShell 5.1 或更高版本
- 可以执行本地 PowerShell 的 AI 客户端
- 可以读取并操作网页的浏览器自动化能力
- 可以把本地绝对路径上传到文件输入控件
- 可见浏览器或人工接管机制，用于登录、扫码和验证码
- 千问账号及可访问的[音视频速读页面](https://www.qianwen.com/discover/audioread)

FFmpeg 是可选增强依赖，用于本地读取媒体时长。环境准备脚本可以在用户授权后通过 Windows Package Manager 安装 `Gyan.FFmpeg`。

## 安装

下载或克隆仓库后，在 PowerShell 中明确选择客户端：

```powershell
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" -Client TraeWork
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" -Client WorkBuddy
```

内置选项还包括 `Codex`、`Claude`、`Cursor` 和 `Agents`。其他客户端使用：

```powershell
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" `
  -Client Custom `
  -DestinationRoot "C:\path\to\skills"
```

`-Client Auto` 只会在检测到唯一一个已知客户端时选择目标。多客户端共存时会停止并要求明确选择，避免安装到错误目录。

安装后重启或重载客户端，把 [TASK-TEMPLATES.md](TASK-TEMPLATES.md) 中的“首次环境初始化”发送给 AI。能力映射规则见 [CLIENT-CAPABILITIES.md](CLIENT-CAPABILITIES.md)。

## 安全边界

- 不读取或保存密码、Cookie、Token、浏览器存储或私钥。
- 不绕过登录、验证码、安全软件或系统策略。
- 管理员提权、系统级安装、安全警告和许可确认必须由用户决定。
- 全自动模式必须具备真实的本地文件上传能力；仅能点击网页时必须报告 `blocked`。
- 不自动覆盖既有转写，不静默重试上传或导出，避免重复任务和错误文件映射。
- 浏览器 Downloads 仅是临时目录；结果移动并验证到用户指定位置后才算完成。

## 仓库结构

```text
qianwen-transcribe-media/
|-- qianwen-transcribe-media/   # 可安装 Skill
|   |-- SKILL.md
|   |-- references/
|   `-- scripts/
|-- install-skill.ps1           # 多客户端安装器
|-- CLIENT-CAPABILITIES.md      # 能力检测说明
|-- TASK-TEMPLATES.md           # 可直接发送给 AI 的任务模板
`-- original-codex-version/     # 改造前的原始 Skill 留档
```

## 验证状态

- Agent Skill 结构校验通过。
- PowerShell 脚本由 GitHub Actions 在 Windows 上执行语法解析。
- CI 在隔离目录验证自定义安装和媒体预检，不访问账号、不上传文件。
- 不同客户端的浏览器工具和千问端到端流程仍需按版本进行实机验证。

## 贡献

问题报告和客户端适配欢迎提交 Issue 或 Pull Request。提交前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 和 [SECURITY.md](SECURITY.md)。

## 许可证

[MIT](LICENSE)
