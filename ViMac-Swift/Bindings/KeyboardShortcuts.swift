//
//  KeyboardShortcuts.swift
//  Vimac
//
//  Created by Dexter Leng on 27/2/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

class KeyboardShortcuts {
    static let shared = KeyboardShortcuts.init()

    let hintModeShortcutKey = "HintModeShortcut"
    let scrollModeShortcutKey = "ScrollModeShortcut"
    let defaultHintShortcut = MASShortcut.init(keyCode: kVK_ANSI_F, modifierFlags: [.control])
    let defaultScrollShortcut = MASShortcut.init(keyCode: kVK_ANSI_J, modifierFlags: [.control])

    /// Configures shortcut storage and registers defaults.
    ///
    /// Storage uses `MASDictionaryTransformer`, which represents a cleared
    /// shortcut as an empty dictionary and an unset shortcut as an absent key.
    /// `NSUserDefaults.registerDefaults` only fills absent keys, so users who
    /// explicitly clear a shortcut keep it cleared across launches.
    func setUp() {
        migrateLegacyShortcutStorage()

        MASShortcutBinder.shared().bindingOptions = [
            NSBindingOption.valueTransformerName.rawValue: MASDictionaryTransformerName
        ]

        MASShortcutBinder.shared().registerDefaultShortcuts([
            hintModeShortcutKey: defaultHintShortcut,
            scrollModeShortcutKey: defaultScrollShortcut,
        ])
    }

    func hintModeShortcutActivation() -> Observable<Void> {
        Observable.create { observer in
            MASShortcutBinder.shared()
                .bindShortcut(withDefaultsKey: self.hintModeShortcutKey, toAction: {
                    observer.onNext(Void())
                })
            return Disposables.create()
        }
    }

    func scrollModeShortcutActivation() -> Observable<Void> {
        Observable.create { observer in
            MASShortcutBinder.shared()
                .bindShortcut(withDefaultsKey: self.scrollModeShortcutKey, toAction: {
                    observer.onNext(Void())
                })
            return Disposables.create()
        }
    }

    /// Convert pre-existing `NSData` (NSKeyedArchive) shortcut values to the
    /// dictionary form expected by `MASDictionaryTransformer`. Without this,
    /// users who upgrade would silently lose their custom shortcuts on first
    /// launch after the storage-format switch.
    private func migrateLegacyShortcutStorage() {
        for key in [hintModeShortcutKey, scrollModeShortcutKey] {
            let value = UserDefaults.standard.object(forKey: key)
            if value == nil || value is [String: Any] { continue }
            guard
                let data = value as? Data,
                let shortcut = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MASShortcut.self, from: data)
            else {
                UserDefaults.standard.removeObject(forKey: key)
                continue
            }
            UserDefaults.standard.set(
                ["keyCode": shortcut.keyCode, "modifierFlags": shortcut.modifierFlags.rawValue],
                forKey: key
            )
        }
    }
}
