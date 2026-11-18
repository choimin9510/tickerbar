const {chromium} = require('playwright-core')
const readline = require('node:readline')
const pause = ms => new Promise(resolve => setTimeout(resolve, ms))
const send = (ticker, fields) => console.log(JSON.stringify({ticker, ...fields}))
const browser = chromium.launch({channel:'chrome', headless:true})
const context = browser.then(b => b.newContext({locale:'ko-KR', viewport:{width:1440,height:900}}))
context.catch(()=>{})
const jobs = new Map()
async function collect(ticker, url, token) {
  while (jobs.get(ticker) === token) {
    let page
    try {
      page = await (await context).newPage()
      token.page = page
      if (!url) {
        await page.goto('https://www.tossinvest.com/', {waitUntil:'domcontentloaded'})
        await page.getByText('를 눌러 검색하세요').first().click()
        await page.getByPlaceholder('검색어를 입력해주세요').fill(ticker)
        const result = page.locator('a[role=option][href*="/stocks/"]').filter({has:page.locator('span').getByText(ticker,{exact:true})}).first()
        try { await result.waitFor({timeout:7000}) } catch {
          send(ticker,{error:'일치하는 티커를 찾지 못했어요'})
          return
        }
        await result.click()
        await page.waitForURL('**/stocks/*/order')
        url = page.url()
      } else {
        await page.goto(url,{waitUntil:'domcontentloaded'})
      }
      let misses = 0
      while (jobs.get(ticker) === token) {
        const quote = await page.evaluate(t => {
          if (!navigator.onLine) return null
          const headerNode = document.querySelector('[data-section-name="종목상세"] [data-section-name="종목검색"]')?.parentElement?.parentElement
          if (!headerNode) return null
          const lines = headerNode.innerText.split('\n').map(s=>s.trim())
          const i = lines.indexOf(t)
          if (i < 1) return null
          const header = lines.slice(i+1,i+12)
          const change = header.findIndex(s=>/^[+−-]?[\d,.]+(?:원|달러)?\s*\([\d,.]+%\)$/.test(s))
          if (change<0) return null
          const values = header.slice(0,change)
          const price = values.find(s=>/^\$[\d,.]+$/.test(s)) || values.find(s=>/^[\d,.]+원$/.test(s))
          if (!price) return null
          const raw = header[change]
          const percent = raw.match(/\(([\d,.]+%)\)/)[1]
          const sign = /^[−-]/.test(raw)?'−':raw.startsWith('+')?'+':''
          return {name:lines[i-1],price,change:sign+percent,session:values.at(-1)}
        },ticker)
        if (quote) {
          misses=0
          send(ticker,{...quote,url})
        } else if (++misses>=8) throw Error()
        await pause(1000)
      }
    } catch (err) {
      if (process.env.TICKERBAR_DEBUG) console.error(err.message)
      if (jobs.get(ticker)===token) send(ticker,{error:'시세 연결 확인 중'})
    } finally { await page?.close().catch(()=>{}) }
    await pause(3000)
  }
}
const input=readline.createInterface({input:process.stdin})
input.on('line',line=>{
  const {ticker,url,remove}=JSON.parse(line)
  jobs.get(ticker)?.page?.close().catch(()=>{})
  jobs.delete(ticker)
  if (!remove) {
    const token={}
    jobs.set(ticker,token)
    collect(ticker,url,token)
  }
})
input.on('close',async()=>{jobs.clear(); await (await browser).close(); process.exit()})
