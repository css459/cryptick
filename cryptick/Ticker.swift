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
    
    private var tickTimer: Timer?
    private let inter: Double!
    private let callback: () -> Void!
    private let commodities: [String]
    
    var prices: [String: String]
    var stats: [String : Dictionary<String, String>]
    
    // MARK: - Initializers
    
    init(secInterval: Double, commodities: [String], tickCallback: @escaping () -> Void) {
        self.prices = [:]
        self.stats = [:]
        self.commodities = commodities
        self.inter = secInterval
        self.callback = tickCallback
        super.init()
    }
    
    // MARK: - Public Control Methods
    
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
    }
    
    // MARK: - Timer Methods
    
    @objc func tick() {
        // Use a semaphore to know when all data for all commods is in
        let semaphore = DispatchSemaphore(value: self.commodities.count)
        for c in commodities {
            self.updatePrices(commodity: c) {
                self.updateStats(commodity: c) {
                    semaphore.signal()
                }
            }
        }
        semaphore.wait()
        callback()
    }
    
    // MARK: - HTTP Methods
    
    private func updatePrices(commodity: String, completion: @escaping () -> Void) {
        let url = URL(string: "https://api.gdax.com/products/" + commodity + "/ticker")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard let data = data, error == nil else {
                self.prices[commodity] = "Error"
                completion()
                return
            }
            
            do {
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let price = dict?["price"] as? String, let p = Float(price) {
                    self.prices[commodity] = String(format: "%.2f", p)
                    completion()
                }
            } catch {
                print(error.localizedDescription)
                self.prices[commodity] = "Error"
                completion()
            }
        }
        
        task.resume()
    }
    
    private func updateStats(commodity: String, completion: @escaping () -> Void) {
        let url = URL(string: "https://api.gdax.com/products/" + commodity + "/stats")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard let data = data, error == nil else {
                self.prices[commodity] = "Error"
                completion()
                return
            }
            
            do {
                if var dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    for (k, v) in dict {
                        if let p = Float(v) {
                            dict[k]! = String(format: "%.2f", p)
                        }
                    }
                    self.stats[commodity] = dict
                }
                completion()
            } catch {
                print(error.localizedDescription)
                self.prices[commodity] = "Error"
                completion()
            }
        }
        
        task.resume()
    }
}
