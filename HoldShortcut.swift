import Cocoa
import SwiftUI

struct RecordedKey: Codable {
    let code: UInt16
    let name: String
}

final class HoldShortcut: ObservableObject {
    @Published private(set) var keys: [RecordedKey] = []
    @Published private(set) var recording = false
    @Published var hint = ""
    var changed: ((Bool) -> Void)?
    private var candidate: [RecordedKey] = []
    private var timer: Timer?
    private var monitor: Any?
    private var held = false
    private var waitForRelease = false
    private let storage = "holdShortcut.v1"
    private let names: [UInt16:String] = [54:"오른쪽 ⌘",55:"왼쪽 ⌘",56:"왼쪽 ⇧",60:"오른쪽 ⇧",58:"왼쪽 ⌥",61:"오른쪽 ⌥",59:"왼쪽 ⌃",62:"오른쪽 ⌃",63:"Fn",49:"Space",36:"Return",48:"Tab",51:"Delete",123:"←",124:"→",125:"↓",126:"↑"]
    init() {
        if let data = UserDefaults.standard.data(forKey:storage),
           let saved = try? JSONDecoder().decode([RecordedKey].self,from:data), (1...2).contains(saved.count) { keys = saved }
        monitor = NSEvent.addLocalMonitorForEvents(matching:[.keyDown,.keyUp,.flagsChanged]) { [weak self] event in
            guard let self = self, self.recording else { return event }
            self.capture(event)
            return nil
        }
        schedule()
    }
    private func down(_ key: RecordedKey) -> Bool {
        CGEventSource.keyState(.combinedSessionState,key:key.code)
    }
    private func schedule() {
        timer?.invalidate()
        guard !keys.isEmpty else { return }
        let t = Timer(timeInterval:0.025,repeats:true) { [weak self] _ in self?.sample() }
        timer = t
        RunLoop.main.add(t,forMode:.common)
    }
    private func sample() {
        guard !recording else { return }
        if waitForRelease {
            if !keys.contains(where:down) { waitForRelease = false }
            return
        }
        let active = keys.allSatisfy(down)
        if active != held { held = active; changed?(active) }
    }
    func begin() { candidate = []; recording = true; hint = "키 1~2개를 함께 누른 뒤 떼세요 · Esc 취소" }
    func cancel() { recording = false; candidate = []; hint = "" }
    func clear() { cancel(); keys = []; UserDefaults.standard.removeObject(forKey:storage); schedule() }
    private func capture(_ event: NSEvent) {
        let code = event.keyCode
        if code == 53 { cancel(); return }
        let chars = event.type == .flagsChanged ? "" : (event.charactersIgnoringModifiers ?? "")
        let printable = chars.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) && $0.value < 0xF700 }
        let label = names[code] ?? (!chars.isEmpty && printable ? chars.uppercased() : "Key "+String(code))
        let key = RecordedKey(code:code,name:label)
        if event.type == .keyUp || (event.type == .flagsChanged && !down(key)) {
            guard candidate.contains(where:{$0.code == code}) else { return }
            keys = candidate
            UserDefaults.standard.set(try? JSONEncoder().encode(keys),forKey:storage)
            waitForRelease = true; held = false; cancel(); schedule()
            return
        }
        guard !candidate.contains(where:{$0.code == code}) else { return }
        guard candidate.count < 2 else { cancel(); hint = "최대 2개까지 설정할 수 있어요"; return }
        candidate.append(key)
        hint = candidate.map(\.name).joined(separator:" + ")+" · 떼면 저장"
    }
}
