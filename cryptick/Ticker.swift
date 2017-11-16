//
//  Ticker.swift
//  cryptick
//
//  Created by Cole Smith on 11/7/17.
//  Copyright © 2017 Cole Smith. All rights reserved.
//

import Cocoa

class Ticker: NSObject {
    
    // MARK: - Class Properties
    
    var commodities: [Commodity]
    
    private var tickTimer: Timer?
    private let inter: Double!
    private let callback: () -> Void!
    private var lastUpdate: Date?
    private var rapidUpdating: Bool = false
    // MARK: - Initializers
    
    init(secInterval: Double, commodities: [(String, String)], tickCallback: @escaping () -> Void) {
        self.inter = secInterval
        self.callback = tickCallback
        self.lastUpdate = nil
        
        self.commodities = []
        for c in commodities {
            self.commodities.append(Commodity(name: c.0, symbol: Character(c.1)))
        }
        
        super.init()
    }
    
    // MARK: - Timer Control Methods
    
    func start() {
        tickTimer = Timer.scheduledTimer(timeInterval: TimeInterval(inter),
                          target: self,
                          selector: #selector(tick),
                          userInfo: nil,
                          repeats: true
        )
        tickTimer?.fire()
    }
    
    func stop() {
        guard let t = tickTimer else { return }
        t.invalidate()
        tickTimer = nil
    }
    
    private func startRapidUpdate() {
        rapidUpdating = true
        stop()
        tickTimer = Timer.scheduledTimer(timeInterval: TimeInterval(1.0),
                                         target: self,
                                         selector: #selector(tick),
                                         userInfo: nil,
                                         repeats: true
        )
        tickTimer?.fire()
    }
    
    private func stopRapidUpdate() {
        rapidUpdating = false
        stop()
        start()
    }
    
    // MARK: - Getter Methods
    
    func getLastUpdate() -> String {
        if let d = lastUpdate {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: d)
            let minutes = calendar.component(.minute, from: d)
            let seconds = calendar.component(.second, from: d)
            return String(format: "%02d:%02d:%02d", hour, minutes, seconds)
        }
        return ""
    }
    
    func getLabel() -> String {
        var label = ""
        for c in commodities {
            label += c.getLabel() + " | "
        }
        return String(label.prefix(label.count-3))
    }
    
    func getAttributedLabel() -> NSAttributedString {
        let label = NSMutableAttributedString(string: "")
        let separator = NSAttributedString(string: "  |  ")
        for c in commodities {
            label.append(c.getAttributedLabel())
            label.append(separator)
        }
        
        return label.attributedSubstring(from: NSMakeRange(0, label.length - separator.length))
    }
    
    // MARK: - Timer Methods
    
    @objc func tick() {
        
        // Use a dispatch group to know when all data for all commods is in
        let g = DispatchGroup()
        
        // Error detection
        var e = false
        
        for c in commodities {
            g.enter()
            c.updatePrice {
                c.updateStats {
                    e = c.price == "Error"
                    g.leave()
                }
            }
        }
        
        g.notify(queue: DispatchQueue.main) {
            
            // If error, start rapid updating to recover quickly
            if e && !self.rapidUpdating {
                self.startRapidUpdate()
            }
            else if !e && self.rapidUpdating {
                self.stopRapidUpdate()
            }
            
            self.lastUpdate = Date()
            self.callback()
        }
    }
}
