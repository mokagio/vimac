//
//  BindingsRepository.swift
//  Vimac
//
//  Created by Dexter Leng on 16/1/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import RxSwift

class BindingsRepository {
    private let store = AppSettings.store

    func read() -> BindingsConfig {
        BindingsConfig(
            holdSpaceHintModeActivationEnabled: store.value(for: VimacSettings.holdSpaceForHintMode),
            hintModeKeySequenceEnabled: store.value(for: VimacSettings.hintModeKeySequenceEnabled),
            hintModeKeySequence: store.value(for: VimacSettings.hintModeKeySequence),
            scrollModeKeySequenceEnabled: store.value(for: VimacSettings.scrollModeKeySequenceEnabled),
            scrollModeKeySequence: store.value(for: VimacSettings.scrollModeKeySequence),
            resetDelay: ResetDelay.seconds(from: store.value(for: VimacSettings.keySequenceResetDelay))
        )
    }

    func readLive() -> Observable<BindingsConfig> {
        Observable.combineLatest(
            VimacSettings.holdSpaceForHintMode.observe(),
            VimacSettings.hintModeKeySequenceEnabled.observe(),
            VimacSettings.hintModeKeySequence.observe(),
            VimacSettings.scrollModeKeySequenceEnabled.observe(),
            VimacSettings.scrollModeKeySequence.observe(),
            VimacSettings.keySequenceResetDelay.observe()
        ).map({ _ in self.read() })
    }
}
