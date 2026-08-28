---
name: qianwen-transcribe-media
description: Transcribe local audio or video with Qianwen AI audio/video quick read (千问 AI 音视频速读), then export the original transcript as Markdown. Use for one file or a batch when the user asks to upload media to Qianwen, wait for transcription, export 原文, or create `_原文.md` transcripts. Handles filename matching, duplicate avoidance, sequential processing, and download verification.
---

# 视频转文字

Use Qianwen's browser interface to turn local media into original Markdown transcripts. For batches, process one file at a time so every Qianwen record and downloaded transcript can be matched to its source.

## Inputs and Defaults

- Accept explicit file paths, a directory, or a clearly identified group of media files.
- Resolve the source path and final output directory independently. The final output directory is always the location specified by the user; never infer it from a previous task or replace it with a fixed Downloads archive directory.
- When the user has not provided a final output directory, ask for it before uploading. Do not silently default to `~/Downloads`, the source directory, or any previously used directory.
- Treat the browser's download directory as a temporary intake location only. A file is not complete until it has been placed and verified in the user's requested final output directory.
- Ask for clarification before uploading when the intended batch is ambiguous.
- Preserve the user's order when one is supplied; otherwise use a stable filename sort.
- Keep the visible Qianwen defaults unless the user requests different settings. The observed defaults include no translation (`不翻译`). Verify visible selections before confirming.
- Treat language and speaker mode as user-controlled settings. Available speaker modes may include `暂不体验`, `单人演讲`, `2人对话`, and `多人讨论`.
- Export only `原文` as `.md`. Preserve visible `发言人` and `时间戳` options unless the user requests otherwise.

## Preflight

1. Resolve every source and the user-specified final output directory to absolute paths. Record each exact source filename and the expected final `_原文.md` path.
2. Create the final output directory when it does not exist and the user's requested path is unambiguous. Verify that it is writable before uploading.
3. Check that each source is supported:
   - Video: `mp4`, `wmv`, `m4v`, `flv`, `rmvb`, `dat`, `mov`, `mkv`, `webm`, `avi`, `mpeg`, `3gp`, or `ogg`; at most 6 GB and 6 hours.
   - Audio: `mp3`, `wav`, `m4a`, `wma`, `aac`, `ogg`, `amr`, `flac`, or `aiff`; at most 500 MB.
4. Note that Qianwen may accept up to 50 files in one upload, but use sequential upload and export by default.
5. Look for an existing matching `_原文.md` file in the user-specified final output directory. Also inspect recent Qianwen records for a matching source filename before creating a new task.
6. Do not submit a duplicate automatically. Report the existing output or record and ask only when it is unclear whether reprocessing is intended.

## Browser Setup

Use `$control-chrome` for all browser interaction and follow its browser selection and bootstrap instructions. Work through the existing Chrome profile so the user's Qianwen login can be reused.

Never inspect cookies, browser storage, passwords, tokens, or session data. If authentication blocks the workflow, stop and ask the user to sign in to Qianwen in the controlled Chrome window.

## Process One File

1. Open `https://www.qianwen.com/discover/audioread`.
2. Activate the audio/video upload area and select exactly the current local source file.
3. Wait for the configuration dialog to become ready.
4. Verify the visible language, translation, and speaker settings. Apply explicit user choices; otherwise retain the visible defaults.
5. Click `确认` once.
6. Verify the success notice: `任务添加成功，请在「我的记录」查看进展`.
7. In `我的记录`, locate the row whose filename matches the current source. Do not use position alone because nearby jobs may reorder as they finish.
8. Poll conservatively until that exact row shows `处理成功`. Keep long waits bounded and report a timeout rather than waiting indefinitely.
9. Open that row's action menu and choose `导出`.
10. In the export dialog, select only `原文`, select `.md`, and preserve the visible `发言人` and `时间戳` selections unless directed otherwise.
11. Click the final `导出` once.
12. Verify that a matching file ending in `_原文.md` appears in the browser's download directory. Use both the source-name stem and a fresh modification time to distinguish it from older exports.
13. Move that verified download into the exact final output directory supplied by the user. Preserve the `_原文.md` filename unless the user requested another naming rule.
14. Verify the final file at the destination: expected filename, nonzero size, readable content, and a fresh modification time. Remove no pre-existing destination file unless the user explicitly approved replacement.
15. Record the source path, Qianwen status, temporary download path, and verified final output path before advancing to the next file.

## Batch Rules

- Complete upload, processing, export, and local verification for one item before starting the next.
- Use the user-specified final output directory for every item in the batch. Do not redirect later items to Downloads or a directory remembered from another batch.
- Re-identify the current row by filename after every navigation or refresh.
- Never export from an adjacent row merely because it reached `处理成功` first.
- Continue past a failed item only when doing so will not obscure which output belongs to which source.
- Do not silently retry an upload or final export, because retries can create duplicate tasks or downloads. Re-check records and Downloads first.

## Failure Handling

- **Login required:** Ask the user to sign in, then resume from the current file.
- **Unsupported, oversized, or overlong source:** Skip it and report the exact limit violated.
- **Upload success not confirmed:** Check `我的记录` for the exact filename before retrying.
- **Task failed:** Capture the visible Qianwen status or error, mark the item failed, and continue only if the remaining mapping stays unambiguous.
- **Processing timeout:** Leave the task intact, report it as pending, and do not export another row under its name.
- **Export download missing:** Re-check Downloads and the browser's download state. Retry only after confirming no matching fresh file exists.
- **Destination unavailable:** Stop before processing more files, preserve the verified temporary download, and report the exact final output directory that could not be written.
- **Filename collision:** Compare source filename, Qianwen row, output modification time, and any browser-added numeric suffix. Do not overwrite automatically; report the collision and preserve both files until the intended result is clear.

## Completion Report

Report every requested item with:

- Source file
- Final Qianwen status
- Verified Markdown path in the user-specified final output directory, when successful
- Skip or failure reason, when not successful

State separately whether any items remain pending. Do not claim completion based only on a Qianwen success status or a file left in the browser's download directory; the `_原文.md` file must be verified at the user's requested final output path.
