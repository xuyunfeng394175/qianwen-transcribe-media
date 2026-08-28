# Contributing

Thank you for helping this skill work across more operating systems and AI clients. Issues and pull requests may be written in Chinese or English.

## Before opening an issue

Search existing issues first and include enough redacted detail to reproduce the behavior:

- AI client name, version, and installation channel.
- Operating system, version/build, and architecture.
- Windows PowerShell version, or shell and Python versions on macOS/Linux.
- The actual command, browser, upload, download, wait, and user-takeover capabilities exposed by the client.
- Whether the command environment, browser, and upload tool share access to the same local paths.
- The failed step, complete redacted error, and whether a small non-sensitive test file reproduces it.

Do not attach credentials, cookies, tokens, browser profiles, private media, private transcripts, identifying account screenshots, or unrelated personal paths.

## Development principles

- Keep workflow logic capability-driven; client names may define installation defaults or tested examples only.
- Preserve user control for login, CAPTCHA, elevation, `sudo`, software installation, security warnings, and license acceptance.
- Keep PowerShell compatible with Windows PowerShell 5.1 unless the baseline is intentionally changed and documented.
- Keep Unix helpers compatible with Bash and Python 3.9+ on supported macOS/Linux versions.
- Avoid reading authentication state or storing credentials.
- Do not add silent retries that can duplicate uploads, tasks, exports, or overwrite transcripts.
- Keep CI offline from account workflows. Tests must not log in, upload media, create live Qianwen tasks, or require private services.
- Separate local platform support from live client/browser validation in all compatibility claims.

## Pull requests

1. Keep changes focused and explain user-visible behavior.
2. Update documentation for new platforms, client capabilities, or installation locations.
3. Add or update platform-matrix tests for affected scripts.
4. State the operating systems, client versions, and workflows tested, plus what remains untested.
5. Confirm that test artifacts and logs contain no sensitive data.

By contributing, you agree that your contribution is licensed under the repository's MIT License.
