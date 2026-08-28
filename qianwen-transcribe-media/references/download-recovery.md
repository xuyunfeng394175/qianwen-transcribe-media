# 导出下载故障分型与恢复

仅在千问记录已显示 `处理成功`，但最终 Markdown 没有正常进入目标电脑时读取本页。

## 先判断失败发生在哪里

最终导出只点击一次，然后同时检查以下证据：

1. 千问页面是否显示导出请求已提交。
2. 浏览器网络记录中与本次导出对应的请求状态、响应类型和时间。不要展示或保存 Cookie、Token、签名参数及完整认证 URL。
3. 浏览器下载记录中的状态和文件名。
4. 命令环境可访问的候选下载目录中，导出时间之后是否出现匹配的 `.md`、临时下载文件或零字节文件。

按证据分类，不要把所有情况统称为“千问下载接口失败”：

- 导出请求返回 `4xx/5xx` 或页面明确报错：`export-request-failed`。
- 导出请求成功，但浏览器显示“失败 - 下载错误”：`browser-download-failed`。
- 浏览器显示完成，但本地命令找不到文件：`download-path-isolated`。
- 本地出现空文件、非 UTF-8 文件或名称不匹配：`invalid-download`。
- 网络状态或真实目录无法观察：`download-unverified`。

## 受控恢复顺序

1. 若可能，先将真实浏览器下载目录显式传给归档脚本，不要默认使用 `$HOME/Downloads`。
2. 只有在尚不能判断是偶发失败时，允许一次诊断性重试。重试前重新记录时间，重试后重新读取网络、下载记录和本地目录；仍失败则停止自动点击。
3. 如果可见浏览器允许用户正常下载，让用户接管并只执行最终下载。用户说明下载完成后，取得文件的绝对路径，通过归档脚本的 `-DownloadedFile` 或 `--downloaded-file` 参数继续自动校验和归档。
4. 如果用户手工下载也失败，保留千问中的已完成记录，报告准确分类和可复现证据。不要重新上传媒体。

Windows 人工下载后的归档示例：

```powershell
powershell -ExecutionPolicy Bypass -File "<skill目录>\scripts\Finalize-Transcript.ps1" -SourceFile "<源文件>" -OutputDirectory "<最终目录>" -NotBefore "<导出前ISO时间>" -DownloadedFile "<已下载Markdown绝对路径>"
```

macOS/Linux：

```bash
python3 "<skill目录>/scripts/Finalize-Transcript.py" --source-file "<源文件>" --output-directory "<最终目录>" --not-before "<导出前ISO时间>" --downloaded-file "<已下载Markdown绝对路径>"
```

## 不采用的做法

- 不修补或替换浏览器 profile，不关闭安全软件，不修改系统下载安全策略。
- 不从浏览器提取 Cookie、Token、认证请求头或带签名的完整下载链接交给本地命令。
- 不依赖未公开的千问内部 API 作为长期实现。
- 不通过反复导出、重新上传或创建重复任务来碰运气。
- 不从页面截取可能被折叠、分页或工具输出截断的长文本后声称得到完整原文。

## 报告格式

```text
qianwenRecord: processed
exportAttempt: submitted|failed|unverified
networkResult: <脱敏后的状态码与响应类型，或 unverified>
browserDownload: completed|failed|unverified
localArtifact: <绝对路径、missing 或 inaccessible>
classification: export-request-failed|browser-download-failed|download-path-isolated|invalid-download|download-unverified
recovery: completed|manual-download-required|blocked
```
