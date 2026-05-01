//
//  xiaozhiApp.swift
//  xiaozhi
//
//  Created by cpq on 2026/4/23.
//

import SwiftUI

@main
struct xiaozhiApp: App {
    init() {
        // 启动时禁用自动锁屏，保持屏幕常亮，方便语音交互
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
