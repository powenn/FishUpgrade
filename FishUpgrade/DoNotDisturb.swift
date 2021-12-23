//
//  DoNotDisturb.swift
//  FishUpgrade
//
//  Created by Lessica <82flex@gmail.com> on 2021/12/17.
//

import AuxiliaryExecute
import Cocoa

enum DoNotDisturb {
    private static let appId = "com.apple.notificationcenterui" as CFString

    private static func set(_ key: String, value: CFPropertyList?) {
        CFPreferencesSetValue(key as CFString, value, appId, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
    }

    private static func commitChanges() {
        CFPreferencesSynchronize(appId, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        DistributedNotificationCenter.default().postNotificationName(Notification.Name("com.apple.notificationcenterui.dndprefs_changed"), object: nil, deliverImmediately: true)
    }

    private static func restartNotificationCenter() {
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.notificationcenterui").first?.forceTerminate()
    }

    private static func enable() {
        guard !isEnabled else {
            return
        }

        set("doNotDisturb", value: true as CFPropertyList)
        set("doNotDisturbDate", value: Date() as CFPropertyList)
        commitChanges()
        restartNotificationCenter()
    }

    private static func disable() {
        guard isEnabled else {
            return
        }

        set("doNotDisturb", value: false as CFPropertyList)
        set("doNotDisturbDate", value: nil)
        commitChanges()
        restartNotificationCenter()
        restoreMenubarIcon()
    }

    private static func restoreMenubarIcon() {
        set("dndStart", value: 0 as CFPropertyList)
        set("dndEnd", value: 1440 as CFPropertyList)

        // We need to sleep for a little bit, otherwise it doesn't take effect.
        // It works with 0.3, but not with 0.2, so we're using 0.4 just to be sure.
        usleep(useconds_t(0.4 * Double(USEC_PER_SEC)))

        set("dndStart", value: nil)
        set("dndEnd", value: nil)
        commitChanges()
    }

    static func installShortcutIfNeeded(in window: NSWindow, completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil) {
        if #available(macOS 12.0, *) {
            let shortcutTest = AuxiliaryExecute.local.bash(command: "shortcuts run macos-focus-mode <<< off", timeout: 1.0)
            if shortcutTest.stderr.contains("not found") {
                NSWorkspace.shared.open(Bundle.main.url(forResource: "macos-focus-mode", withExtension: "shortcut")!)
                let installAlert = NSAlert()
                installAlert.messageText = "勿擾模式"
                installAlert.informativeText = "請點擊“加入捷徑”以允許本程式控制勿擾模式。"
                installAlert.addButton(withTitle: "加入了")
                installAlert.beginSheetModal(for: window, completionHandler: handler)
                return
            }
        }
        handler?(.OK)
    }

    static var isEnabled: Bool {
        get {
            if #available(macOS 12.0, *) {
                return false
            } else if #available(macOS 11.0, *) {
                let scriptURL = Bundle.main.url(forResource: "check_dnd_status_big_sur", withExtension: "sh")!
                return AuxiliaryExecute.local.bash(command: "sh \'\(scriptURL.path)\'").stdout.contains("true")
            } else {
                return CFPreferencesGetAppBooleanValue("doNotDisturb" as CFString, appId, nil)
            }
        }
        set {
            if #available(macOS 12.0, *) {
                if newValue {
                    AuxiliaryExecute.local.bash(command: "shortcuts run macos-focus-mode <<< on", timeout: 3.0)
                } else {
                    AuxiliaryExecute.local.bash(command: "shortcuts run macos-focus-mode <<< off", timeout: 3.0)
                }
            } else if #available(macOS 11.0, *) {
                if newValue {
                    let scriptURL = Bundle.main.url(forResource: "enable_dnd_big_sur", withExtension: "sh")!
                    AuxiliaryExecute.local.bash(command: "sh \'\(scriptURL.path)\'")
                } else {
                    let scriptURL = Bundle.main.url(forResource: "disable_dnd_big_sur", withExtension: "sh")!
                    AuxiliaryExecute.local.bash(command: "sh \'\(scriptURL.path)\'")
                }
            } else {
                if newValue {
                    enable()
                } else {
                    disable()
                }
            }
        }
    }
}
