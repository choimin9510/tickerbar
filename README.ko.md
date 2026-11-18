# TickerBar

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md)

macOS 메뉴 막대에서 관심 종목의 시세를 확인하세요. TickerBar는 백그라운드 Chrome을 통해 토스증권 웹에 표시되는 현재가와 등락률을 읽습니다.

## 빌드 및 실행

Mac에 Xcode 명령줄 도구, Google Chrome, npm이 포함된 Node.js 20 이상을 설치하세요.

```sh
git clone https://github.com/choimin9510/tickerbar.git
cd tickerbar
npm ci
bash build.sh
open build/TickerBar.app
```

## 사용법

메뉴 막대의 차트 아이콘을 클릭하고 SOXL이나 005930 같은 티커를 입력한 뒤 Return을 누르세요. 미국 종목은 달러 가격이 제공되면 달러로 표시합니다. 관심 목록은 이 Mac에 저장됩니다.

패널에서 **키 설정**을 클릭하고 키 한두 개를 함께 눌렀다 떼면 저장됩니다. 다른 앱에서 설정한 키를 누르는 동안 시세가 보이고 하나라도 떼면 닫힙니다. **해제**를 누르면 단축키를 지울 수 있습니다.

앱 화면은 한국어입니다. 앱이 실행되는 동안 패널을 닫아도 시세가 갱신됩니다. 토스증권 웹사이트가 변경되면 갱신이 중단될 수 있습니다.
