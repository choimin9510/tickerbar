import Cocoa
import SwiftUI

struct Stock: Codable, Identifiable {
    var id: String
    var name = ""
    var price = ""
    var change = ""
    var session = ""
    var url: String?
    var updated: Date?
    var status = "갱신 중"
}

final class Store: ObservableObject {
    @Published var stocks: [Stock] = []
    private var dismissal: DispatchWorkItem?
    @Published var message = "" {
        didSet {
            dismissal?.cancel()
            guard !message.isEmpty else { return }
            let task = DispatchWorkItem { [weak self] in self?.message = "" }
            dismissal = task
            DispatchQueue.main.asyncAfter(deadline:.now()+3, execute:task)
        }
    }
    private var worker: Process?
    private var input: Pipe?
    init() {
        if let data = UserDefaults.standard.data(forKey: "stocks"),
           let saved = try? JSONDecoder().decode([Stock].self, from: data) { stocks = saved }
    }
    func save() { UserDefaults.standard.set(try? JSONEncoder().encode(stocks), forKey: "stocks") }
    func start() {
        guard worker == nil, let res = Bundle.main.resourceURL else { return }
        let proc = Process(), pipe = Pipe(), out = Pipe()
        proc.executableURL = res.appendingPathComponent("node")
        proc.arguments = [res.appendingPathComponent("feed.js").path]
        proc.standardInput = pipe
        proc.standardOutput = out
        do { try proc.run() } catch { message = "시세 수집기를 시작할 수 없어요"; return }
        worker = proc
        input = pipe
        for i in stocks.indices { stocks[i].status = "갱신 중"; request(stocks[i]) }
        DispatchQueue.global().async {
            var buffer = Data()
            while true {
                let chunk = out.fileHandleForReading.availableData
                if chunk.isEmpty { break }
                buffer.append(chunk)
                while let end = buffer.firstIndex(of: 10) {
                    let line = Data(buffer[..<end])
                    buffer.removeSubrange(...end)
                    DispatchQueue.main.async { if self.worker === proc { self.receive(line) } }
                }
            }
            DispatchQueue.main.async {
                if self.worker === proc {
                    self.worker = nil
                    self.input = nil
                    self.message = "시세 수집기가 종료됐어요. 패널을 다시 열어주세요."
                    for i in self.stocks.indices { self.stocks[i].status = "연결 끊김" }
                }
            }
        }
    }
    func stop() { message = ""; input?.fileHandleForWriting.closeFile(); input = nil; worker = nil; save() }
    func request(_ stock: Stock, remove: Bool = false) {
        var cmd: [String:Any] = ["ticker":stock.id,"remove":remove]
        cmd["url"] = stock.url
        if var d = try? JSONSerialization.data(withJSONObject: cmd) {
            d.append(10)
            try? input?.fileHandleForWriting.write(contentsOf:d)
        }
    }
    func add(_ text: String) {
        let id = text.trimmingCharacters(in:.whitespacesAndNewlines).uppercased()
        guard !id.isEmpty else { return }
        guard !stocks.contains(where:{$0.id == id}) else { message = "이미 등록한 티커예요"; return }
        guard id.range(of:"^[A-Z0-9][A-Z0-9.-]{0,15}$",options:.regularExpression) != nil else { message = "티커 형식을 확인해주세요"; return }
        message = ""
        let stock = Stock(id:id)
        stocks.append(stock); request(stock); save()
    }
    func delete(_ stock: Stock) { request(stock, remove:true); stocks.removeAll{$0.id == stock.id}; save() }
    func receive(_ data: Data) {
        guard let d = try? JSONDecoder().decode([String:String].self,from:data),
              let i = stocks.firstIndex(where:{$0.id == d["ticker"]}) else { return }
        if let error = d["error"] {
            if error.hasPrefix("일치"), stocks[i].url == nil {
                message = "\(stocks[i].id) · \(error)"; stocks.remove(at:i); save()
            } else { stocks[i].status = error }
            return
        }
        guard let price=d["price"], let change=d["change"] else { return }
        let firstQuote = stocks[i].url == nil
        stocks[i].name=d["name"] ?? ""; stocks[i].url=d["url"]; stocks[i].price=price
        stocks[i].change=change; stocks[i].session=d["session"] ?? ""
        stocks[i].status=""; stocks[i].updated=Date()
        if firstQuote { save() }
    }
}
struct Panel: View {
    @ObservedObject var store: Store
    @ObservedObject var shortcut: HoldShortcut
    @State private var ticker = ""
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            HStack { Text("관심 종목").font(.headline); Spacer(); Button("종료"){NSApp.terminate(nil)}.buttonStyle(.link) }
            HStack {
                TextField("티커 입력 · AAPL, 005930",text:$ticker).onChange(of:ticker) { value in if !value.isEmpty { store.message = "" } }.onSubmit { add() }
                Button("추가"){add()}
            }
            HStack {
                Text("누르는 동안 보기").font(.caption)
                Spacer()
                Button(shortcut.recording ? "취소" : shortcut.keys.map(\.name).joined(separator:" + ").isEmpty ? "키 설정" : shortcut.keys.map(\.name).joined(separator:" + ")) {
                    if shortcut.recording { shortcut.cancel() } else { shortcut.begin() }
                }
                if !shortcut.keys.isEmpty && !shortcut.recording { Button("해제"){shortcut.clear()} }
            }
            if !shortcut.hint.isEmpty { Text(shortcut.hint).font(.caption) }
            if !store.message.isEmpty { Text(store.message).font(.caption) }
            if store.stocks.isEmpty { Text("티커를 추가하면 여기에 시세가 표시돼요.").foregroundColor(.secondary) }
            ScrollView {
                VStack(spacing:9) {
                    ForEach(store.stocks) { s in
                        HStack {
                            VStack(alignment:.leading) {
                                Text(s.name.isEmpty ? s.id : s.name).bold()
                                Text(s.id+" · "+(s.status.isEmpty ? s.session : s.status)).font(.caption).foregroundColor(.secondary)
                                if !s.status.isEmpty, let date=s.updated { Text("마지막 확인 "+date.formatted(date:.omitted,time:.standard)).font(.caption2) }
                            }
                            Spacer()
                            VStack(alignment:.trailing) {
                                Text(s.price.isEmpty ? "…" : s.price)
                                Text(s.change).foregroundColor(s.change.hasPrefix("+") ? .red : s.change.hasPrefix("−") ? .blue : .secondary)
                            }.monospacedDigit()
                            Button { store.delete(s) } label:{Image(systemName:"minus.circle")}.buttonStyle(.plain).accessibilityLabel("종목 삭제")
                        }
                        Divider()
                    }
                }
            }
        }.padding(16).frame(width:356,height:330)
    }
    func add(){store.add(ticker); ticker=""}
}
final class App: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    let store=Store(), panel=NSPopover(), shortcut=HoldShortcut()
    var openedByHold = false
    var item:NSStatusItem!
    func applicationDidFinishLaunching(_ n:Notification){
        store.start()
        item=NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        let b=item.button!
        b.image=NSImage(systemSymbolName:"chart.line.uptrend.xyaxis",accessibilityDescription:"관심 종목")
        b.target=self; b.action=#selector(toggle)
        panel.animates = false
        shortcut.changed = { [weak self] down in
            guard let self = self, let button = self.item.button else { return }
            if down && !self.panel.isShown {
                self.openedByHold = true
                self.panel.show(relativeTo:button.bounds,of:button,preferredEdge:.minY)
            } else if !down && self.openedByHold { self.panel.performClose(nil) }
        }
        panel.behavior = .applicationDefined; panel.delegate=self
        NSEvent.addGlobalMonitorForEvents(matching:[.leftMouseDown,.rightMouseDown]) { [weak self] _ in
            if self?.panel.isShown == true { self?.panel.performClose(nil) }
        }
        panel.contentViewController=NSHostingController(rootView:Panel(store:store,shortcut:shortcut))
    }
    @objc func toggle(){if panel.isShown {panel.performClose(nil)} else if let b=item.button {
        store.start(); NSApp.activate(ignoringOtherApps:true); panel.show(relativeTo:b.bounds,of:b,preferredEdge:.minY); panel.contentViewController?.view.window?.makeKey()
    }}
    func popoverDidClose(_ notification:Notification){openedByHold = false; shortcut.cancel(); store.message = ""; store.save()}
    func applicationWillTerminate(_ notification:Notification){store.stop()}
}
let app=NSApplication.shared, delegate=App()
app.setActivationPolicy(.accessory); app.delegate=delegate; app.run()
