//
//  AppDelegate.swift
//  cryptick
//
//  Created by Cole Smith on 11/7/17.
//  Copyright © 2017 Cole Smith. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBar = NSStatusBar.system
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItem : NSMenuItem = NSMenuItem()
    
    var ticker: Ticker!
    
    var priceBTC = "Loading"
    var priceETH = "Loading"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        ticker = Ticker(secInterval: 30) {
            if let btc = self.ticker.prices["BTC-USD"] {
                self.priceBTC = "₿ " + btc
            }
            if let eth = self.ticker.prices["ETH-USD"] {
                self.priceETH = "Ξ " + eth
            }
            DispatchQueue.main.async {
                self.statusBarItem.title = self.priceBTC + " | " + self.priceETH
            }
        }
        ticker.start()
        
        // Add statusBarItem
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = menu
        statusBarItem.title = self.priceBTC + " | " + self.priceETH
        
        // Add Menu Item (Quit and Open GDAX)
        let quitItem = NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit), keyEquivalent: "")
        let gdaxItem = NSMenuItem(title: "Open GDAX", action: #selector(AppDelegate.openGDAX), keyEquivalent: "")
        menu.addItem(gdaxItem)
        menu.addItem(quitItem)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.ticker.stop()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func openGDAX() {
        if let url = URL(string: "https://www.gdax.com/trade/BTC-USD") {
            NSWorkspace.shared.open(url)
        }
    }
}

