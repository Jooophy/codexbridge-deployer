# CodexBridge Deployer

个人自用的 CodexBridge 微信接入部署助手。

> Personal use only. 这是我自己实测 CodexBridge 后整理出来的小工具，不是 OpenAI、微信、OpenClaw 或 CodexBridge 官方项目。

目标不是让小程序直接改用户电脑，而是把最容易卡住的步骤变成清晰的 guide：

- 检查 Node.js、Git、Codex CLI
- 下载或更新 CodexBridge
- 修复 Codex 配置兼容问题
- 引导微信扫码登录
- 启动 WeChat bridge

## 项目结构

```text
miniapp/       微信小程序原型，用来 guide 用户复制部署命令
installer/     本机部署脚本，真正执行 deploy
docs/          这次成功部署的经验笔记
```

## Demo 路线

1. 用微信开发者工具打开 `miniapp`。
2. 在首页选择 Windows。
3. 复制安装命令。
4. 在 PowerShell 里运行脚本。
5. 扫码登录后，启动 bridge。

## 产品定位

第一版只针对“已经有 Codex 账号，并且愿意在本机运行脚本”的用户。

暂时不解决：

- Claude Desktop / Claude Code 的安装
- 多平台常驻服务管理
- 云端托管
- 企业微信稳定通道

后续可以扩展成两个入口：

- Codex 用户：部署 CodexBridge
- Claude 用户：部署 Claude Code / MCP / 微信通知通道

## Windows 本地测试

```powershell
powershell -ExecutionPolicy Bypass -File .\installer\install-windows.ps1
```

脚本默认安装到：

```text
D:\CodexBridge
```

如果已经存在，会执行 update/check，不会删除用户文件。

## 成功经验

这次真正跑通时，关键问题在这里：

- Codex CLI 配置里的 `service_tier = "default"` 会导致当前 CLI 报错，需改成 `fast` 或 `flex`。
- CodexBridge 微信登录轮询可能遇到 `ETIMEDOUT`，需要容错重试。
- 微信扫码成功后，还必须启动 `weixin serve`，否则微信发消息没有回应。

完整笔记见：

```text
docs/SUCCESS_NOTES.md
```

## 免责声明

- 个人微信桥接有风控风险。
- 建议先用小号 test。
- 不要提交 token、二维码、运行日志。
- 这个 repo 只记录个人使用经验，不保证适用于所有环境。

## 发布前要替换

小程序里的安装命令目前使用：

```text
https://example.com/install-codexbridge.ps1
```

正式发布前，需要把脚本上传到自己的 HTTPS 域名，并替换 `miniapp/pages/index/index.js` 里的地址。
