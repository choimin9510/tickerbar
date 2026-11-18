# TickerBar

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md)

在 macOS 菜单栏查看自选股行情。TickerBar 通过后台运行的 Chrome 读取 Toss 证券网页显示的最新价格和涨跌幅。

## 构建与运行

请先在 Mac 上安装 Xcode 命令行工具、Google Chrome 和带有 npm 的 Node.js 20 或更高版本。

```sh
git clone https://github.com/choimin9510/tickerbar.git
cd tickerbar
npm ci
bash build.sh
open build/TickerBar.app
```

## 使用方法

点击菜单栏中的走势图标，输入股票代码（例如 SOXL 或 005930），然后按回车键。美股在有美元报价时优先显示美元价格。自选列表保存在本机。

点击面板中的 **키 설정**（设置快捷键），同时按住一至两个键再松开即可保存。在其他应用中按住设定的快捷键即可查看行情，松开任意一个键即可收起面板。点击 **해제** 可清除快捷键。

应用界面为韩语。只要应用仍在运行，收起面板后行情也会继续更新。Toss 证券网站的改动可能导致更新中断。
