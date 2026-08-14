//
//  AppDelegate.swift
//  ViMac-Swift
//
//  Created by Dexter Leng on 6/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import RxSwift
import MASShortcut

@NSApplicationMain
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var welcomeWindowController: NSWindowController?
    
    private lazy var focusedWindowDisturbedObservable: Observable<FrontmostApplicationService.ApplicationNotification> = createFocusedWindowDisturbedObservable()
    private lazy var windowObservable: Observable<Element?> = createFocusedWindowObservable()

    let hintModeShortcutObservable: Observable<Void> = ShortcutMonitor.shared.activation(of: .hintMode)
    let scrollModeShortcutObservable: Observable<Void> = ShortcutMonitor.shared.activation(of: .scrollMode)
    
    var compositeDisposable: CompositeDisposable
    var scrollModeDisposable: CompositeDisposable? = CompositeDisposable()
    
    var modeCoordinator: ModeCoordinator!
    let overlayWindowController: OverlayWindowController
    var settingsWindowController: SettingsWindowController!
    var statusItemManager: StatusItemManager!
    
    let frontmostAppService = FrontmostApplicationService.init()
    
    override init() {
        InputSourceManager.initialize()
        overlayWindowController = OverlayWindowController()
        
        ShortcutMonitor.shared.setUp()

        self.compositeDisposable = CompositeDisposable()
        
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if isDuplicateAppInstance() {
            NSApp.terminate(self)
            return
        }

        setupSettings()
        setupStatusItem()

        if AXIsProcessTrusted() {
            self.onAXPermissionGranted()
        } else {
            pollAccessibility {
                self.onAXPermissionGranted()
            }
            showPermissionRequestingWindow()
        }
    }
        
    func onAXPermissionGranted() {
        closePermissionRequestingWindow()

        UIElement.globalMessagingTimeout = 1

        self.modeCoordinator = ModeCoordinator()
        self.setupWindowEventAndShortcutObservables()
        self.setupAXAttributeObservables()
    }
        
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings(sender)
        return true
    }
        
    func isDuplicateAppInstance() -> Bool {
        let bundleId = Bundle.main.bundleIdentifier
        let instances = NSWorkspace.shared.runningApplications
            .filter({ $0.bundleIdentifier == bundleId })
            .count
        return instances > 1
    }
        
    func setupSettings() {
        if self.settingsWindowController == nil {
            self.settingsWindowController = SettingsWindowController()
            self.settingsWindowController.window?.delegate = self
        }
    }
        
    /// Reached from the main menu's Settings… item, which the storyboard sends
    /// to the first responder.
    @objc func openSettings(_ sender: Any?) {
        setupSettings()
        settingsWindowController.show()
    }
        
    func setupStatusItem() {
        self.statusItemManager = StatusItemManager.init(settingsWindowController: self.settingsWindowController)
    }
    
    func createApplicationObservable() -> Observable<NSRunningApplication?> {
        Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.frontmostAppService.observeFrontmostApp({ app in
                observer.onNext(app)
            })
            return Disposables.create()
        }
    }
    
    func createFocusedWindowDisturbedObservable() -> Observable<FrontmostApplicationService.ApplicationNotification> {
        Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.frontmostAppService.observeFocusedWindowDisturbed({ notification in
                observer.onNext(notification)
            })
            return Disposables.create()
        }
    }
    
    func createFocusedWindowObservable() -> Observable<Element?> {
        Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }

            self.frontmostAppService.observeFocusedWindow({ window in
                observer.onNext(window)
            })
            return Disposables.create()
        }
    }
    
    func showPermissionRequestingWindow() {
        let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
        welcomeWindowController = storyboard.instantiateController(withIdentifier: "WelcomeWindowController") as? NSWindowController
        NSApp.activate(ignoringOtherApps: true)
        welcomeWindowController?.showWindow(nil)
        welcomeWindowController?.window?.makeKeyAndOrderFront(nil)
    }
        
    func closePermissionRequestingWindow() {
        self.welcomeWindowController?.close()
        self.welcomeWindowController = nil
    }
        
    func setupAXAttributeObservables() {
        let axWorker = ConcurrentDispatchQueueScheduler.init(qos: .default)
        let frontmostAppChange = createApplicationObservable().withPrevious().share()

        let isAXManualAccessibilityEnabled = VimacSettings.electronSupport.observe()
        let AXManualAccessibilityDisabled: Observable<Void> = isAXManualAccessibilityEnabled
            .filter({ !$0 })
            .map({ _ in Void() })
        
        _ = self.compositeDisposable.insert(
            AXManualAccessibilityDisabled
                .observeOn(axWorker)
                .subscribe(onNext: {
                    AXManualAccessibilityActivator.deactivateAll()
                })
        )
        
        _ = self.compositeDisposable.insert(
            frontmostAppChange.onlyWhen(isAXManualAccessibilityEnabled)
                .observeOn(axWorker)
                .subscribe(onNext: { (_, currentApp) in
                    if let currentApp = currentApp {
                        AXManualAccessibilityActivator.activate(currentApp)
                    }
                })
        )
        
        let isAXEnhancedUserInterfaceEnabled = VimacSettings.emulateVoiceOver.observe()
        let AXEnhancedUserInterfaceDisabled: Observable<Void> = isAXEnhancedUserInterfaceEnabled
            .filter({ !$0 })
            .map({ _ in Void() })
        
        _ = self.compositeDisposable.insert(
            AXEnhancedUserInterfaceDisabled
                .observeOn(axWorker)
                .subscribe(onNext: {
                    AXEnhancedUserInterfaceActivator.deactivateAll()
                })
        )
        
        _ = self.compositeDisposable.insert(
            frontmostAppChange.onlyWhen(isAXEnhancedUserInterfaceEnabled)
                .observeOn(axWorker)
                .subscribe(onNext: { (_, currentApp) in
                    if let currentApp = currentApp {
                        AXEnhancedUserInterfaceActivator.activate(currentApp)
                    }
                })
        )
    }
    
    func setupWindowEventAndShortcutObservables() {
        _ = self.compositeDisposable.insert(focusedWindowDisturbedObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { notification in
                self.modeCoordinator.deactivate()
            })
        )
        
        _ = self.compositeDisposable.insert(windowObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { windowOptional in
                self.modeCoordinator.deactivate()
            })
        )

        _ = self.compositeDisposable.insert(hintModeShortcutObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }

                if let modeController = self.modeCoordinator.modeController {
                    if let _  = modeController as? HintModeController {
                        self.modeCoordinator.deactivate()
                        return
                    }
                }
                
                self.modeCoordinator.setHintMode()
            })
        )
        
        _ = self.compositeDisposable.insert(scrollModeShortcutObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                if let modeController = self.modeCoordinator.modeController {
                    if let _  = modeController as? ScrollModeController {
                        self.modeCoordinator.deactivate()
                        return
                    }
                }
                
                self.modeCoordinator.setScrollMode()
            })
        )
    }
    
    func pollAccessibility(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if AXIsProcessTrusted() {
                completion()
            } else {
                self.pollAccessibility(completion: completion)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.compositeDisposable.dispose()

        // Both walk every running application over the AX API. Untrusted, each
        // of those calls blocks until the messaging timeout, which is seconds of
        // beachball to undo activations that never happened.
        guard AXIsProcessTrusted() else { return }

        AXEnhancedUserInterfaceActivator.deactivateAll()
        AXManualAccessibilityActivator.deactivateAll()
    }
}

extension AppDelegate : NSWindowDelegate {
    func windowDidBecomeMain(_ notification: Notification) {
        let transformState = ProcessApplicationTransformState(kProcessTransformToForegroundApplication)
        var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
        TransformProcessType(&psn, transformState)
    }
    
    func windowWillClose(_ notification: Notification) {
        let transformState = ProcessApplicationTransformState(kProcessTransformToUIElementApplication)
        var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
        TransformProcessType(&psn, transformState)
    }
}
