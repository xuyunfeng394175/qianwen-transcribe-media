# qianwen-transcribe-media

[简体中文](README.md) | [English](README.en.md)

An Agent Skill for Windows AI clients that turns local audio and video into verified original Markdown transcripts through Qianwen AI Audio/Video Quick Read.

The skill is capability-driven rather than tied to a particular client or tool name. TraeWork, WorkBuddy, Codex, Claude, Cursor, and other clients can use it when they provide local PowerShell execution, browser automation, local file upload, and a visible user-takeover path.

> [!IMPORTANT]
> This is an unofficial community project. It is not affiliated with or endorsed by Alibaba, Qianwen, or any AI client mentioned here. Web UI, service limits, and available features may change. Follow Qianwen's terms of service and applicable law.

## What It Does

1. Checks Windows, PowerShell, directory permissions, Qianwen HTTPS access, `winget`, and FFmpeg.
2. Maps the active client's tools to navigation, page inspection, interaction, local file upload, bounded waits, downloads, and user takeover.
3. Validates media format, size, duration, destination access, and existing output locally.
4. Checks Qianwen records by exact filename, then uploads, waits, and exports one item at a time.
5. Finds the fresh Markdown download, moves it to the requested directory, and verifies that it is readable and non-empty.

## Requirements

- Windows x64
- Windows PowerShell 5.1 or later
- An AI client that can run local PowerShell
- Browser automation with page inspection and interaction
- Local file upload to an HTML file input
- A visible browser or user-takeover mechanism for login and verification
- A Qianwen account with access to [Audio/Video Quick Read](https://www.qianwen.com/discover/audioread)

FFmpeg is optional and enables local duration checks. With user authorization, the setup script can install `Gyan.FFmpeg` through Windows Package Manager.

## Install

Clone or download the repository, then select the target client in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" -Client TraeWork
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" -Client WorkBuddy
```

Built-in targets also include `Codex`, `Claude`, `Cursor`, and `Agents`. For another client:

```powershell
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" `
  -Client Custom `
  -DestinationRoot "C:\path\to\skills"
```

Restart or reload the client after installation. Send it the environment initialization prompt from [TASK-TEMPLATES.md](TASK-TEMPLATES.md). See [CLIENT-CAPABILITIES.md](CLIENT-CAPABILITIES.md) for the capability contract.

## Safety Boundaries

- Never inspect or store passwords, cookies, tokens, browser storage, or private keys.
- Never bypass login, CAPTCHA, security software, or system policy.
- Require user approval for elevation, system-wide installation, security warnings, and license prompts.
- Full automation requires a real local-file-upload capability.
- Do not overwrite existing transcripts or silently retry uploads and exports.
- A transcript is complete only after it is moved to and verified in the requested destination.

## Status

The Agent Skill structure is validated. GitHub Actions parses every PowerShell file on Windows and runs isolated installer and media preflight checks. Browser integrations and the live Qianwen workflow still require client-specific end-to-end verification.

## Contributing

Issues and pull requests for client adapters are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md) first.

## License

[MIT](LICENSE)
