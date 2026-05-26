#!/usr/bin/env swift

// Print the CGWindowID of the first on-screen window owned by `argv[1]`
// (either a numeric PID or a process-name substring, case-insensitive) whose
// window name contains `argv[2]`. Exit 1 if no match.

import AppKit
import CoreGraphics

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write(Data("usage: _find_window_id.swift <pid-or-name> <name-substring>\n".utf8))
    exit(2)
}

let ownerArg = args[1]
let pidFilter = Int(ownerArg)
let ownerNeedle = ownerArg.lowercased()
let nameNeedle = args[2].lowercased()

let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []

for window in windows {
    let name = (window[kCGWindowName as String] as? String ?? "").lowercased()
    guard name.contains(nameNeedle) else { continue }

    if let pid = pidFilter {
        guard (window[kCGWindowOwnerPID as String] as? Int) == pid else { continue }
    } else {
        let owner = (window[kCGWindowOwnerName as String] as? String ?? "").lowercased()
        guard owner.contains(ownerNeedle) else { continue }
    }

    if let id = window[kCGWindowNumber as String] as? UInt32 {
        print(id)
        exit(0)
    }
}

exit(1)
