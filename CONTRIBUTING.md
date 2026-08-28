# Contributing

Thank you for helping this skill work across more Windows AI clients. Issues and pull requests may be written in Chinese or English.

## Before opening an issue

Search existing issues first. Include enough environment detail to reproduce the behavior:

- AI client name, version, and installation channel.
- Windows edition/build, architecture, and PowerShell version.
- The actual command, browser, upload, download, wait, and user-takeover tool names exposed by the client.
- Which step failed and the complete redacted error message.
- Whether the failure is reproducible with a small, non-sensitive test file.

Do not attach credentials, cookies, tokens, browser profiles, private media, private transcripts, or identifying account screenshots. Redact local usernames and unrelated paths when they are not necessary to reproduce the problem.

## Development principles

- Keep the design capability-driven. Client names may provide installation defaults or tested examples, but workflow logic must not depend on a single fixed MCP or tool name.
- Preserve explicit user control for login, CAPTCHA, elevation, software installation, security warnings, and license acceptance.
- Keep all PowerShell compatible with Windows PowerShell 5.1 unless the supported baseline is intentionally changed and documented.
- Avoid storing credentials or reading browser authentication state.
- Do not add silent retries that could create duplicate uploads, tasks, exports, or overwritten transcripts.
- Keep CI offline from account workflows. Automated tests must not log in to Qianwen, upload media, create live tasks, or depend on private services.

## Pull requests

1. Keep the change focused and explain the user-visible behavior.
2. Add or update documentation for new client capabilities or installation locations.
3. Test PowerShell syntax and the affected local workflow on Windows when possible.
4. State what was tested, the client/version used, and what remains untested.
5. Confirm that test artifacts and logs contain no sensitive data.

By contributing, you agree that your contribution is licensed under the repository's MIT License.
