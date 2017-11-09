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
    
    let UPDATE_TIME_SECONDS = 3.0
    let COMMODITIES = [("BTC-USD", "₿"), ("ETH-USD", "Ξ")]
    let COLORED_TICKER = true
    
    // MARK: - Class Properties
    
    var statusBar = NSStatusBar.system
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItem : NSMenuItem = NSMenuItem()
    
    var ticker: Ticker!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        var menuStats = [[NSMenuItem]]()
        
        // Init references to stats tickers
        for c in COMMODITIES {
            let header = NSMenuItem(title: c.0 + " (24HR)", action: nil, keyEquivalent: "")
            let open = NSMenuItem(title: "Open: Loading" , action: nil, keyEquivalent: "")
            let high = NSMenuItem(title: "High: Loading", action: nil, keyEquivalent: "")
            let low = NSMenuItem(title: "Low: Loading", action: nil, keyEquivalent: "")
            
            menuStats.append([open, high, low])
            
            // Add to menu items
            self.menu.addItem(header)
            self.menu.addItem(NSMenuItem.separator())
            self.menu.addItem(open)
            self.menu.addItem(high)
            self.menu.addItem(low)
            self.menu.addItem(NSMenuItem.separator())
        }
        
        // Init ticker and designate callback behavior
        ticker = Ticker(secInterval: UPDATE_TIME_SECONDS, commodities: COMMODITIES) {
            
            // Update UI
            DispatchQueue.main.async {
                for m in menuStats {
                    // TODO
                }
                if self.COLORED_TICKER {
                    self.statusBarItem.attributedTitle = self.ticker.getAttributedLabel()
                } else {
                    self.statusBarItem.title = self.ticker.getLabel()
                }
            }
        }
        
        // Init Last Update
        let lastUpdate = NSMenuItem(title: "Last Update: " + ticker.getLastUpdate(), action: nil, keyEquivalent: "")
        menu.addItem(lastUpdate)
        menu.addItem(NSMenuItem.separator())

        // Start ticker
        ticker.start()
        ticker.tick()
        
        // Add statusBarItem
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.title = ticker.getLabel()
        statusBarItem.menu = menu
        
        // Add Menu Item (Quit and Open GDAX)
        let quitItem = NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit), keyEquivalent: "")
        let gdaxItem = NSMenuItem(title: "Open GDAX", action: #selector(AppDelegate.openGDAX), keyEquivalent: "")
        menu.addItem(gdaxItem)
        menu.addItem(quitItem)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        ticker.stop()
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

