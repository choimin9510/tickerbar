# TickerBar

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md)

Watch stock prices from the macOS menu bar. TickerBar reads the live price and signed percentage change displayed on Toss Securities using a background Chrome session.

## Build and run

On a Mac, install the Xcode Command Line Tools, Google Chrome, and Node.js 20 or later with npm.

```sh
git clone https://github.com/choimin9510/tickerbar.git
cd tickerbar
npm ci
bash build.sh
open build/TickerBar.app
```

## Using TickerBar

Click the chart icon, enter a ticker such as SOXL or 005930, and press Return. US stocks show the dollar price when available. Your watchlist is saved on this Mac.

To peek from another app, click **키 설정** in the panel, hold one or two keys together, then release to save. Hold the saved shortcut to show prices and release any key to hide them. Choose **해제** to clear it.

The interface is in Korean. Quotes keep updating while TickerBar runs. Changes to the Toss Securities website may interrupt updates.
