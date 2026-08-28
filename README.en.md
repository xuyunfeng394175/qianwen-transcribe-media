# qianwen-transcribe-media

[简体中文](README.md) | [English](README.en.md)

A cross-platform Agent Skill that lets capable AI clients turn local audio and video into locally verified original Markdown transcripts through Qianwen AI Audio/Video Quick Read.

The project does not implement a transcription model. It coordinates environment checks, media preflight, browser upload, bounded waiting, export, file placement, and final validation. TraeWork, WorkBuddy, Codex, Claude, Cursor, and other Agent Skills clients can integrate through the capability contract.

> [!IMPORTANT]
> This is an unofficial community project and is not affiliated with or endorsed by Alibaba, Qianwen, or any AI client mentioned here. Media is uploaded to a third-party cloud service. Do not use it for content that must remain private, and follow Qianwen's terms and applicable law.

## Platform Support

| Platform | Local helpers | Installer | Automated coverage |
|---|---|---|---|
| Windows 10/11 x64 | PowerShell 5.1+ | `install-skill.ps1` | Local workflow on Windows CI |
| macOS | Bash + Python 3.9+ | `install-skill.sh` | Local workflow on macOS CI |
| Linux | Bash + Python 3.9+ | `install-skill.sh` | Local workflow on Ubuntu CI |

The local workflow includes installation, syntax checks, media preflight, and downloaded-file finalization. CI does not log in, upload media, or exercise the live Qianwen site.

Full automation requires the active AI client to provide local command execution, browser navigation and inspection, interaction, real local-file upload, bounded waiting, local download access, and visible user takeover for login or verification. See [CLIENT-CAPABILITIES.md](CLIENT-CAPABILITIES.md).

On Linux, containers, remote hosts, and WSL require extra path validation: the command environment, browser, and upload tool must all access the same media files.

## Requirements

- A Qianwen account with access to [Audio/Video Quick Read](https://www.qianwen.com/discover/audioread).
- An Agent Skills client with local command and required browser capabilities.
- A visible browser or user-takeover mechanism.
- Windows PowerShell 5.1+ on Windows.
- Bash and Python 3.9+ on macOS/Linux.
- Optional FFmpeg/`ffprobe` for local duration validation.

With explicit user approval, setup helpers can install dependencies through Windows Package Manager, Homebrew, `apt-get`, `dnf`, or `pacman`. Elevation, `sudo`, software installation, license acceptance, and security prompts always remain user-controlled.

## Install

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" -Client TraeWork
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" -Client WorkBuddy
```

macOS/Linux:

```bash
chmod +x install-skill.sh
./install-skill.sh --client Codex
./install-skill.sh --client WorkBuddy
```

Custom destinations:

```powershell
powershell -ExecutionPolicy Bypass -File ".\install-skill.ps1" -Client Custom -DestinationRoot "C:\path\to\skills"
```

```bash
./install-skill.sh --client Custom --destination-root "$HOME/path/to/skills"
```

Built-in targets also include `Codex`, `Claude`, `Cursor`, and `Agents`. `Auto` proceeds only when exactly one known client directory is detected. Existing installations are backed up before replacement.

After installation, restart or reload the client and send it the first-run prompt from [TASK-TEMPLATES.md](TASK-TEMPLATES.md).

The installable Skill includes optional `agents/openai.yaml` UI metadata for compatible clients. Workflow behavior remains capability-driven and does not require a specific client.

## Workflow

1. Detect the operating system and select PowerShell or Bash/Python helpers.
2. Check runtimes, directories, network reachability, optional FFmpeg, and client capabilities.
3. Validate media type, size, duration, destination access, and output collisions.
4. Check Qianwen by exact filename, upload one file, and wait for completion.
5. Export only the original Markdown and locate the fresh download.
6. Move it to the requested directory and verify a non-empty UTF-8 file.

## Safety Boundaries

- Never inspect or store passwords, cookies, tokens, browser storage, or private keys.
- Never bypass login, CAPTCHA, security software, client restrictions, or system policy.
- Require explicit approval for software installation, elevation, `sudo`, and license prompts.
- Report `blocked` when real local-file upload is unavailable.
- Do not silently retry uploads or exports, overwrite transcripts, or claim completion before local verification.
- Process files serially by default; parallel batch processing is not promised.

## Validation Status

The Skill structure is validated. CI covers PowerShell parsing and local Windows checks, plus Bash syntax, Python compilation, installation, preflight, and finalization on macOS and Ubuntu. Live browser integration and Qianwen end-to-end behavior still require testing against each client version.

This project fits connected workflows where cloud upload is acceptable. Prefer a local tool such as Whisper, Buzz, or whisperX for sensitive, offline, or high-volume processing.

## Contributing and License

Client capability mappings, platform tests, and error handling improvements are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md). Licensed under the [MIT License](LICENSE).
