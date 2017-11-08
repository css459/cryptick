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

    // MARK: - Constants
    
    let UPDATE_TIME_SECONDS = 30.0
    let COMMODITIES = ["BTC-USD", "ETH-USD"]
    
    // MARK: - Class Properties
    
    var statusBar = NSStatusBar.system
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItem : NSMenuItem = NSMenuItem()
    
    var ticker: Ticker!
    
    var priceBTC = "Loading"
    var priceETH = "Loading"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Init references to stats tickers
        var stats: [String: [NSMenuItem]] = [:]
        for c in COMMODITIES {
            let header = NSMenuItem(title: c + " (24HR)", action: nil, keyEquivalent: "")
            let open = NSMenuItem(title: "Open: Loading", action: nil, keyEquivalent: "")
            let high = NSMenuItem(title: "High: Loading", action: nil, keyEquivalent: "")
            let low = NSMenuItem(title: "Low: Loading", action: nil, keyEquivalent: "")
            
            stats[c] = [open, high, low]
            
            // Add to menu items
            self.menu.addItem(header)
            self.menu.addItem(NSMenuItem.separator())
            for i in stats[c]! { self.menu.addItem(i) }
            self.menu.addItem(NSMenuItem.separator())
        }
        
        // Init ticker and designate callback behavior
        ticker = Ticker(secInterval: UPDATE_TIME_SECONDS, commodities: COMMODITIES) {
            
            // Price Tickers
            if let btc = self.ticker.prices["BTC-USD"] {
                self.priceBTC = "₿ " + btc
            }
            if let eth = self.ticker.prices["ETH-USD"] {
                self.priceETH = "Ξ " + eth
            }
            
            // Stats Tickers
            for k in self.ticker.stats.keys {
                if let d = self.ticker.stats[k], let o = d["open"], let h = d["high"], let l = d["low"] {
                    if let menuItems = stats[k] {
                        menuItems[0].title = "Open: " + o
                        menuItems[1].title = "High: " + h
                        menuItems[2].title = "Low: " + l
                    }
                }
            }
            
            // Update UI
            DispatchQueue.main.async {
                self.statusBarItem.title = self.priceBTC + " | " + self.priceETH
                self.menu.update()
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

