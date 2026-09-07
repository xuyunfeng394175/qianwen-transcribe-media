# 隔离浏览器与远程调试

## 根因

Chrome/Chromium 的远程调试不能直接复用日常浏览器的默认用户数据目录（UDD）。把 `--remote-debugging-port` 直接加到默认 UDD 的启动命令可能被浏览器拒绝，并提示需要 non-default data directory。这个限制是浏览器启动约束，不是千问页面或转录任务本身的错误。

## 标准做法

为自动化单独创建一个 UDD，例如：

```text
Windows: %USERPROFILE%\qianwen-transcribe-media\chrome-debug-profile
macOS:   ~/qianwen-transcribe-media/chrome-debug-profile
Linux:   ~/qianwen-transcribe-media/chrome-debug-profile
```

使用以下脚本启动并验证：

```text
python3 <skill目录>/scripts/Launch-Debug-Chrome.py \
  --user-data-dir <专用UDD绝对路径> \
  --debug-port 9222
```

Windows 如果 `python3` 不存在，使用已检测到的 Python 命令（例如 `py -3`）；不要因为 Windows 命令名不同而改用默认 Chrome UDD。

脚本会：

- 自动寻找常见 Chrome 路径，也接受 `--browser-path` 明确指定路径。
- 创建专用 UDD，使用 `--remote-debugging-port`、`--user-data-dir` 和 `--profile-directory=Default` 启动。
- 通过 `http://127.0.0.1:<端口>/json/version` 验证 CDP 端点。
- 如果端口已有端点，只报告现有端点，不抢占、杀掉或猜测其归属。
- 输出脱敏的 JSON，包含 CDP 地址、专用 UDD 和进程状态。

## 首次登录

专用 UDD 与日常 Chrome 隔离，首次打开千问时通常需要用户扫码或登录一次。AI 客户端必须：

1. 报告专用浏览器窗口已经打开。
2. 明确让用户在该窗口完成扫码、登录或验证码。
3. 等待用户确认后重新读取页面，确认千问音视频速读页可用。
4. 后续复用同一个 UDD，除非用户要求清理或重新登录。

不要保存密码，不要读取 Cookie、Token、Local Storage 或 profile 文件，不要把日常 Chrome 的登录状态复制到专用 UDD。

## 健康检查报告

```text
browserDebug: ready|existing|blocked
browserPath: <绝对路径或 unknown>
debugEndpoint: <本机地址或 unavailable>
userDataDirectory: <专用UDD绝对路径>
login: required|ready|unknown
userTakeover: required|completed|blocked
```

只有 `browserDebug: ready|existing` 且用户完成身份验证后，才能创建千问转写任务。
