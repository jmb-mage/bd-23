import Foundation
import AppKit

if CommandLine.arguments.contains("--test") {
    let success = SelfTests.run()
    exit(success ? 0 : 1)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
