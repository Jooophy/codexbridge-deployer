# 成功部署笔记

这是一次个人实测后的经验整理，不是官方指南。

## 目标

把已有 Codex 用户的本机环境接到微信：

```text
WeChat / OpenClaw
  -> CodexBridge
  -> local Codex CLI / Codex app-server
```

## 成功路径

1. 准备环境：
   - Node.js 24+
   - Git
   - Codex CLI 可运行
2. clone CodexBridge。
3. 安装依赖。
4. 修复 Codex 配置兼容问题。
5. 运行微信二维码登录。
6. 登录成功后启动 `weixin serve`。
7. 在微信里发送 `/h` 或短消息测试。

## 这次踩到的坑

### 1. Codex 配置不兼容

现象：

```text
unknown variant `default`, expected `fast` or `flex`
in `service_tier`
```

原因：

`C:\Users\<user>\.codex\config.toml` 里有：

```toml
service_tier = "default"
```

当前 Codex CLI 只接受：

```toml
service_tier = "fast"
```

或：

```toml
service_tier = "flex"
```

本项目 installer 会把 `default` 自动改成 `fast`。

### 2. 微信登录状态轮询超时

现象：

二维码能生成，但登录进程报：

```text
HTTPS request timed out after 14988ms
code: ETIMEDOUT
```

原因：

登录轮询只处理了部分超时类型，`ETIMEDOUT` 会直接让进程退出。

本项目提供了一个本地 patch 脚本：

```powershell
powershell -ExecutionPolicy Bypass -File .\installer\patch-login-timeout.ps1 -CodexBridgeDir D:\CodexBridge
```

### 3. login 成功不等于 bridge 已启动

登录成功只会保存账号 token。还需要运行：

```powershell
node node_modules\tsx\dist\cli.mjs src\cli.ts weixin serve --cwd D:\
```

否则微信里发消息不会有回复。

### 4. 收到消息但没回复

先看日志：

```text
C:\Users\<user>\.codexbridge\weixin\serve\codexbridge-serve.err.log
```

如果看到 `process_inbound_event_start`，说明微信消息进来了。

如果看到 `final_delivery_decision`，说明 Codex 已生成回复并尝试发送。

## 安全提醒

- 这不是 OpenAI 官方微信接入。
- 个人微信桥接有风控可能。
- 建议先用小号 test。
- 不要把账号 token、日志、二维码提交到 GitHub。

