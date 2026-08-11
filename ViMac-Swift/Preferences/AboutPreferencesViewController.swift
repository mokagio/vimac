//
//  AboutPreferencesViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 3/3/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import Preferences

class AboutPreferencesViewController: NSViewController, PreferencePane {
    let preferencePaneIdentifier = Preferences.PaneIdentifier.about
    let preferencePaneTitle = "About"
    let toolbarItemIcon: NSImage
    
    init() {
        if #available(OSX 11.0, *) {
            self.toolbarItemIcon = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)!
        } else {
            self.toolbarItemIcon = NSImage(named: NSImage.infoName)!
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        self.view = NSView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewDidLoad() {
        let iconImage = NSApp.applicationIconImage!
        iconImage.size = .init(width: 80, height: 80)
        let iconView = NSImageView(image: iconImage)
        
        let appNameLabel = NSTextField(labelWithString: "Vimac")
        appNameLabel.font = .boldSystemFont(ofSize: 18)

        let shortBundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
        let versionLabel = NSTextField(labelWithString: "Version \(shortBundleVersion) (\(bundleVersion))")
        versionLabel.font = .labelFont(ofSize: 13)
        versionLabel.textColor = .secondaryLabelColor

        let copyrightNoticeLabel = NSTextField(labelWithString: "Copyright © 2026 Gio Lodi")
        copyrightNoticeLabel.font = .labelFont(ofSize: 11)
        copyrightNoticeLabel.textColor = .secondaryLabelColor

        // An `.link` attribute would be repainted system blue by the field
        // editor a selectable label hands its text to, so the click is handled
        // here instead and the styling is left alone.
        let attributionLabel = NSTextField(labelWithAttributedString: originalVersionAttributedString())
        attributionLabel.addGestureRecognizer(
            NSClickGestureRecognizer(target: self, action: #selector(attributionClicked))
        )

        let sourceCodeButton = NSButton(title: "Source Code", target: self, action: #selector(visitGithubRepo))
        // Otherwise it opens focused, wearing a focus ring nobody asked for.
        sourceCodeButton.refusesFirstResponder = true

        let buttonsStackView = NSStackView(views: [
            sourceCodeButton
        ])
        buttonsStackView.alignment = .leading
        buttonsStackView.orientation = .horizontal
        
        let descriptionStackView = NSStackView(views: [
            appNameLabel,
            versionLabel,
            copyrightNoticeLabel,
            attributionLabel,
            buttonsStackView
        ])
        descriptionStackView.alignment = .leading
        descriptionStackView.orientation = .vertical
        
        let stackView = NSStackView(views: [
            iconView,
            descriptionStackView
        ])
        stackView.orientation = .horizontal
        stackView.spacing = 40
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 600),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private static let originalVersionLinkText = "Original version"

    private func originalVersionAttributedString() -> NSAttributedString {
        let string = NSMutableAttributedString(
            string: Self.originalVersionLinkText,
            attributes: Self.originalVersionLinkAttributes
        )
        string.append(NSAttributedString(
            string: " by Dexter Leng - 2021",
            attributes: [
                .font: NSFont.labelFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        ))
        return string
    }

    private static let originalVersionLinkAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.labelFont(ofSize: 11),
        .foregroundColor: NSColor.secondaryLabelColor,
        .underlineStyle: NSUnderlineStyle.single.rawValue
    ]

    @objc private func attributionClicked(_ recognizer: NSClickGestureRecognizer) {
        guard let label = recognizer.view else { return }

        // Only the leading "Original version" run is a link, so a click past
        // its width lands on Dexter Leng's name and does nothing.
        let linkWidth = NSAttributedString(
            string: Self.originalVersionLinkText,
            attributes: Self.originalVersionLinkAttributes
        ).size().width
        guard recognizer.location(in: label).x <= linkWidth else { return }

        _ = NSWorkspace.shared.open(URL(string: "https://github.com/dexterleng/vimac/")!)
    }

    @objc func visitGithubRepo() {
        let url = URL(string: "https://github.com/mokagio/vimac/")!
        _ = NSWorkspace.shared.open(url)
    }
}
