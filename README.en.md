# qianwen-transcribe-media

[简体中文](README.md) | [English](README.en.md)

A cross-platform Agent Skill that lets capable AI clients turn local audio and video into locally verified original Markdown transcripts through Qianwen AI Audio/Video Quick Read.

The project does not implement a transcription model. It coordinates environment checks, media preflight, browser upload, bounded waiting, export, file placement, and final validation. TraeWork, WorkBuddy, Codex, Claude, Cursor, and other Agent Skills clients can integrate through the capability contract.

> [!IMPORTANT]
> The transcription backend is locked for every compatible Agent Skills client to Qianwen web Audio/Video Quick Read (`transcriptionProvider: qianwen-web-audioread`). Whether the client is WorkBuddy, TraeWork, Codex, Claude, Cursor, or another client, failure to complete the Qianwen workflow must be reported as `blocked`, `pending`, or `failed`; the client must not install or invoke Whisper, whisperX, Vosk, system speech recognition, or another local/third-party transcription service. FFmpeg/`ffprobe` are only for media preflight and file validation. Use `scripts/Validate-Provider.py` as the machine-readable startup gate.

## Why This Project Exists

Running local transcription models such as Whisper can continuously consume CPU, GPU, memory, and battery. On lower-powered computers, while editing video, or when processing long recordings, this can cause heat, lag, and slow transcription.

This project moves the expensive transcription work to Qianwen's cloud service. The local computer only handles environment checks, upload, waiting, download, and output validation. This reduces local resource pressure, keeps other applications more responsive, and lets users make legitimate use of free quotas or account benefits already offered by the platform.

In plain terms, a large cloud platform handles the heavy computation while your computer stays usable, and you get more value from benefits already included with your account.

The project does not bypass billing, quotas, authentication, or other service restrictions, and it does not guarantee that the service will remain free. Current quotas, processing limits, and pricing are governed by Qianwen's live service and terms.

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

When a client connects to Chrome through CDP or remote debugging, it must use a dedicated non-default `user-data-dir`. Chrome rejects direct remote debugging with the everyday default user data directory; this is a browser launch constraint, not a Qianwen transcription failure. The first use of the dedicated profile requires the user to scan in the new window and log in to Qianwen once. The profile can then be reused without affecting the everyday Chrome profile. `Launch-Debug-Chrome.py` performs cross-platform launch and endpoint checks, but never reads or copies passwords, cookies, tokens, or browser profile data.

Some managed browsers, including certain WorkBuddy integrations, can click an export button but cannot expose the downloaded file to the local command environment, or save it inside an AI-client sandbox. When the browser reports "download failed", use the [download recovery guide](qianwen-transcribe-media/references/download-recovery.md) to classify the failure. When necessary, let the user complete one normal download in the visible browser, then continue validation and archival with the downloaded file's absolute path. A browser download error alone is not proof that Qianwen's export endpoint is permanently unavailable.

On Linux, containers, remote hosts, and WSL require extra path validation: the command environment, browser, and upload tool must all access the same media files.

## Requirements

- A Qianwen account with access to [Audio/Video Quick Read](https://www.qianwen.com/discover/audioread).
- An Agent Skills client with local command and required browser capabilities.
- A visible browser or user-takeover mechanism.
- Windows PowerShell 5.1+ on Windows.
- Bash and Python 3.9+ on macOS/Linux.
- Optional FFmpeg/`ffprobe` only for local duration validation and media preflight; they are not transcription engines.

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

The remote-debugging path first checks for an existing usable CDP session. If none exists, it starts Chrome with a dedicated UDD, verifies `debugEndpoint` and `userDataDirectory`, and only then connects. An unverified endpoint or a default Chrome UDD is `blocked`; the workflow never falls back to the everyday profile.

## Low-Token Batch Mode

For batch work, use `qianwen-transcribe-media/scripts/Batch-State.py`. It maintains a local `manifest.json`, `state.json`, and `events.jsonl` for stable ordering, resumability, counters, and duplicate-output skipping. The AI client only claims the next file, performs browser actions, and records the result. Environment and CDP checks can be reused through a four-hour lease, while browser queries return only narrow status for the current file.

This reduces AI-client context and tool-call costs, not Qianwen cloud quota or processing time. Serial uploads, user-controlled login, download verification, and no-overwrite behavior remain in force. See the [low-token mode guide](qianwen-transcribe-media/references/low-token-mode.md) and [task templates](TASK-TEMPLATES.md).

## Safety Boundaries

- Never inspect or store passwords, cookies, tokens, browser storage, or private keys.
- Never bypass login, CAPTCHA, security software, client restrictions, or system policy.
- Require explicit approval for software installation, elevation, `sudo`, and license prompts.
- Report `blocked` when real local-file upload is unavailable.
- Stop when the Qianwen workflow fails; never switch automatically to a local or third-party transcription engine.
- Do not silently retry uploads or exports, overwrite transcripts, or claim completion before local verification.
- Process files serially by default; parallel batch processing is not promised.

## Validation Status

The Skill structure is validated. CI covers PowerShell parsing and local Windows checks, plus Bash syntax, Python compilation, installation, preflight, and finalization on macOS and Ubuntu. Live browser integration and Qianwen end-to-end behavior still require testing against each client version.

The isolated remote-debugging launch rules cover Windows, macOS, and Linux. First-use login in the dedicated profile remains a user action, and each client still needs real-device validation for CDP attachment and download exposure.

This project fits connected workflows where cloud upload is acceptable. It has no local transcription fallback. For sensitive or offline work, use a separate tool such as Whisper, Buzz, or whisperX outside this Skill task.

## Contributing and License

Client capability mappings, platform tests, and error handling improvements are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md). Licensed under the [MIT License](LICENSE).
