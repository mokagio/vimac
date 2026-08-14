//
//  StatusItemManager.swift
//  ViMac-Swift
//
//  Created by Dexter Leng on 19/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

@MainActor
class StatusItemManager: NSObject {
    let menu: NSMenu
    let statusItem: NSStatusItem
    let settingsWindowController: SettingsWindowController
    
    init(settingsWindowController: SettingsWindowController) {
        self.menu = NSMenu()
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusItem.button!.image = NSImage(named: "StatusBarButtonImage")
        self.settingsWindowController = settingsWindowController
        
        super.init()
        
        self.statusItem.menu = self.menu
        self.menu.delegate = self
    }
}

extension StatusItemManager : NSMenuDelegate {
    func menuWillOpen(_ _menu: NSMenu) {
        if let menu = statusItem.menu {
            menu.removeAllItems()
            menu.addItem(withTitle: "Report bugs / Suggest features", action: #selector(openGithubIssues), keyEquivalent: "").target = self
            menu.addItem(NSMenuItem.separator())
            
            menu.addItem(withTitle: "About", action: #selector(aboutClick), keyEquivalent: "").target = self
            menu.addItem(withTitle: "Settings…", action: #selector(settingsClick), keyEquivalent: "").target = self
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Quit", action: #selector(quitClick), keyEquivalent: "").target = self
        }
    }
    
    @objc func settingsClick() {
        settingsWindowController.show()
    }
    
    @objc func aboutClick() {
        settingsWindowController.show(pane: .about)
    }

    @objc func openGithubIssues() {
        let url = URL(string: "https://github.com/mokagio/vimac/issues")!
        _ = NSWorkspace.shared.open(url)
    }

    @objc func quitClick() {
        NSApplication.shared.terminate(self)
    }
}
