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
    let COMMODITIES = [("BTC", "₿"), ("ETH", "Ξ"), ("XRP", "XRP")]
    
    // MARK: - Class Properties
    
    var statusBar = NSStatusBar.system
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItem : NSMenuItem = NSMenuItem()
    var colored_ticker = false
    var baseCurrency = BaseCurrency.usd
    
    var ticker: Ticker!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Init Last Update
        let lastUpdate = NSMenuItem(title: "Last Update: ", action: nil, keyEquivalent: "")
        menu.addItem(lastUpdate)
        menu.addItem(NSMenuItem.separator())
        
        // Init references to stats tickers
        var menuStats = [[NSMenuItem]]()
        for c in COMMODITIES {
            let header = NSMenuItem(title: c.0 + " (24HR)", action: nil, keyEquivalent: "")
            let open = NSMenuItem(title: "Open: Loading" , action: nil, keyEquivalent: "")
            let high = NSMenuItem(title: "High: Loading", action: nil, keyEquivalent: "")
            let low = NSMenuItem(title: "Low: Loading", action: nil, keyEquivalent: "")
            
            menuStats.append([header, open, high, low])
            
            // Check for ripple
            if c.1 == "XRP" { continue }
            
            // Add to menu items
            menu.addItem(header)
            menu.addItem(NSMenuItem.separator())
            menu.addItem(open)
            menu.addItem(high)
            menu.addItem(low)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Init ticker and designate callback behavior
        ticker = Ticker(secInterval: UPDATE_TIME_SECONDS, commodities: COMMODITIES, baseCurrency: baseCurrency) {
            // Update UI
            DispatchQueue.main.async {
                
                // Update "Last Update"
                lastUpdate.title = "Last Update: " + self.ticker.getLastUpdate()  + self.ticker.baseCurrency.rawValue
                
                // Update stats menu
                for i in 0..<menuStats.count {
                    let c = self.ticker.commodities[i]
                    let m = menuStats[i]
                    m[0].title = c.name + " (24HR)"
                    m[1].title = "Open: " + c.open
                    m[2].title = "High: " + c.high
                    m[3].title = "Low: " + c.low
                }
                
                // Update menu bar ticker
                if self.colored_ticker {
                    self.statusBarItem.attributedTitle = self.ticker.getAttributedLabel()
                } else {
                    self.statusBarItem.title = self.ticker.getLabel()
                }
            }
        }

        // Start ticker, and make initial tick (using Timer to avoid race condition)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in self.ticker.tick() }
        ticker.start()
        
        // Add statusBarItem
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.title = ticker.getLabel()
        statusBarItem.menu = menu
        
        // Add Menu Item (Update Now)
        let updateNow = NSMenuItem(title: "Update Now", action: #selector(AppDelegate.update), keyEquivalent: "")
        menu.addItem(updateNow)
        
        // Add Menu Item (Switch ticker type)
        let switchTicker = NSMenuItem(title: "Switch Ticker Style", action: #selector(AppDelegate.switchTicker), keyEquivalent: "")
        menu.addItem(switchTicker)
        
        // Add Menu Item (Switch Base Currency)
        let switchBase = NSMenuItem(title: "Switch Base Currency", action: #selector(AppDelegate.switchBaseCurrency), keyEquivalent: "")
        menu.addItem(switchBase)
        
        // Add Menu Item (Quit and Open GDAX)
        let quitItem = NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit), keyEquivalent: "")
        let gdaxItem = NSMenuItem(title: "Open GDAX", action: #selector(AppDelegate.openGDAX), keyEquivalent: "")
        menu.addItem(gdaxItem)
        menu.addItem(quitItem)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        ticker.stop()
    }
    
    // MARK: - Button Callbacks
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func openGDAX() {
        var b = BaseCurrency.usd
        if baseCurrency == .eur { b = .eur }
        if let url = URL(string: "https://www.gdax.com/trade/" + "BTC" + b.rawValue) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func update() {
        ticker.tick()
    }
    
    @objc func switchTicker() {
        colored_ticker = !colored_ticker
        ticker.tick()
    }
    
    @objc func switchBaseCurrency() {
        let i = (ticker.baseCurrency.asInt() + 1) % 2 // Only use USD and EUR for now (for BTC: % 3)
        let n = BaseCurrency.withInt(i: i)
        ticker.setBaseCurrency(base: n)
    }
}
