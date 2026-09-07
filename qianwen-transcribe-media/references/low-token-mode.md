# 低 Token 模式

低 Token 模式减少的是 AI 客户端的上下文读取、浏览器轮询和过程输出，不减少千问云端的用量、账号额度或平台计费。

## 状态协议

批量任务开始时使用 `scripts/Batch-State.py create` 建立一次性任务目录。该目录包含：

- `manifest.json`：输入文件、稳定顺序、文件大小、修改时间和预期输出路径。
- `state.json`：每个文件的当前状态，可在客户端中断后恢复。
- `events.jsonl`：每次状态变更一行，不写入转写正文、Cookie、Token 或密码。
- `lease.json`：可选的环境/CDP租约，不保存认证信息。

状态只允许使用 `ready`、`processing`、`completed`、`skipped`、`failed`、`pending`、`blocked`。多客户端协作时用 `claim` 原子领取一个 `ready` 文件，成功归档后使用 `record completed`，不要依靠聊天记录判断完成。

## 推荐调用

```bash
python3 "<skill目录>/scripts/Batch-State.py" create \
  --source-path "/绝对路径/媒体目录" \
  --output-directory "/绝对路径/转写结果" \
  --state-directory "/绝对路径/任务状态/任务名"

python3 "<skill目录>/scripts/Batch-State.py" next \
  --state-directory "/绝对路径/任务状态/任务名"

python3 "<skill目录>/scripts/Batch-State.py" claim \
  --state-directory "/绝对路径/任务状态/任务名"

python3 "<skill目录>/scripts/Batch-State.py" record \
  --state-directory "/绝对路径/任务状态/任务名" \
  --source-file "/绝对路径/媒体目录/example.mp4" \
  --status completed \
  --output-path "/绝对路径/转写结果/example_原文.md"

python3 "<skill目录>/scripts/Batch-State.py" status \
  --state-directory "/绝对路径/任务状态/任务名"
```

Windows 使用 `python` 或 `py -3`，并把路径替换为 Windows 本机绝对路径；参数和 JSON 协议相同。

## 浏览器最小交互

环境、能力和专用 CDP 浏览器只检测一次。每次浏览器查询只返回目标文件的窄结果：

```json
{"fileName":"episode-038.mp4","status":"处理中","hasExportButton":false}
```

不要返回整页 DOM、全量记录、无关推荐、下载历史、Cookie、Token 或 Local Storage。页面变化后重新定位目标记录，不复用失效的 DOM 引用。

等待策略：上传后等待 30 秒；处理中每 60 秒检查；超过 10 分钟后每 120 秒检查；达到任务上限后记录 `pending`，不要静默重传。

## 上下文预算

- 正常任务只读取 `SKILL.md`；只有对应异常才读取相关 reference。
- 脚本直接执行并解析 JSON，不读取脚本源码。
- 转写阶段只检查 Markdown 存在、非空和 UTF-8，不读取完整正文。
- 正常成功只输出：`completed | input=<文件名> | output=<绝对路径>`。
- 每处理约 50 个文件建立 checkpoint；恢复时只读取 `status` 和 `claim`。
- 最终只输出统计摘要和失败/待处理项目。
