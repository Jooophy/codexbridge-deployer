const installCommands = {
  windows: 'irm https://example.com/install-codexbridge.ps1 | iex',
  macos: 'curl -fsSL https://example.com/install-codexbridge.sh | bash',
  linux: 'curl -fsSL https://example.com/install-codexbridge.sh | bash'
};

Page({
  data: {
    selectedPlatform: 'windows',
    platforms: [
      { id: 'windows', label: 'Windows' },
      { id: 'macos', label: 'macOS' },
      { id: 'linux', label: 'Linux' }
    ],
    command: installCommands.windows,
    steps: [
      {
        title: '环境检查',
        desc: 'check Node.js 24+、Git、Codex CLI 是否可用。'
      },
      {
        title: '部署 CodexBridge',
        desc: 'clone 或 update 仓库，安装依赖并修复常见 config。'
      },
      {
        title: '微信扫码',
        desc: '生成登录二维码，保存账号 token。'
      },
      {
        title: '启动 bridge',
        desc: '运行 weixin serve，把微信消息转给 Codex。'
      }
    ]
  },

  selectPlatform(event) {
    const selectedPlatform = event.currentTarget.dataset.id;
    this.setData({
      selectedPlatform,
      command: installCommands[selectedPlatform]
    });
  },

  copyCommand() {
    wx.setClipboardData({
      data: this.data.command,
      success: () => {
        wx.showToast({ title: '已复制', icon: 'success' });
      }
    });
  },

  copyLocalCommand() {
    wx.setClipboardData({
      data: 'powershell -ExecutionPolicy Bypass -File .\\installer\\install-windows.ps1',
      success: () => {
        wx.showToast({ title: '已复制', icon: 'success' });
      }
    });
  }
});
