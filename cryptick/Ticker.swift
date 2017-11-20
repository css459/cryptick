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
    
    private var rawCommodities: [(String, String)]
    private var tickTimer: Timer?
    private let inter: Double!
    private let callback: () -> Void!
    private var lastUpdate: Date?
    private var rapidUpdating: Bool = false
    
    private(set) var baseCurrency: BaseCurrency
    private var fallbackBaseCurrency: BaseCurrency
    
    // MARK: - Initializers
    
    init(secInterval: Double, commodities: [(String, String)], baseCurrency: BaseCurrency, tickCallback: @escaping () -> Void) {
        self.inter = secInterval
        self.callback = tickCallback
        self.lastUpdate = nil
        
        self.baseCurrency = baseCurrency
        
        if baseCurrency != .usd || baseCurrency != .eur {
            self.fallbackBaseCurrency = .usd
        } else {
            self.fallbackBaseCurrency = baseCurrency
        }
        
        self.rawCommodities = commodities
        self.commodities = []
        for c in commodities {
            let name = BaseCurrency.commodityWithBaseCurrency(commodity: c.0, base: baseCurrency, fallback: fallbackBaseCurrency)
            self.commodities.append(Commodity(name: name , symbol: c.1))
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
    
    // MARK: - Setter Methods
    
    func setBaseCurrency(base: BaseCurrency) {
        
        // Handle case that BTC can be a commodity and
        // also a base currency. Leverage fallback if
        // base-commodity pair is BTC-BTC
        
        // We need a fallback
        if base == .btc {
            if baseCurrency != .btc {
                fallbackBaseCurrency = baseCurrency
            } else {
                // Absolute Fallback: USD
                fallbackBaseCurrency = .usd
            }
        }
        
        baseCurrency = base
        
        var newCommodities = [Commodity]()
        for c in rawCommodities {
            let name = BaseCurrency.commodityWithBaseCurrency(commodity: c.0, base: baseCurrency, fallback: fallbackBaseCurrency)
            newCommodities.append(Commodity(name: name , symbol: c.1))
        }
        commodities = newCommodities
        
        tick()
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

enum BaseCurrency: String {
    case usd = "-USD"
    case eur = "-EUR"
    case btc = "-BTC"
    
    func asInt() -> UInt {
        switch self {
        case .usd:
            return 0
        case .eur:
            return 1
        case .btc:
            return 2
        }
    }
    
    static func withInt(i: UInt) -> BaseCurrency {
        switch i {
        case 0:
            return .usd
        case 1:
            return .eur
        case 2:
            return .btc
        default:
            return .usd
        }
    }
    
    static func commodityWithBaseCurrency(commodity: String, base: BaseCurrency, fallback: BaseCurrency) -> String {
        switch base {
        case .usd:
            return commodity + "-USD"
        case .eur:
            return commodity + "-EUR"
        case .btc:
            // Cannot have BTC-BTC, use fallback
            if commodity == "BTC" {
                return commodity + "-" + fallback.rawValue
            } else {
                return commodity + "-BTC"
            }
        }
    }
}
