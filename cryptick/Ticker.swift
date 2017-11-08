//
//  Ticker.swift
//  cryptick
//
//  Created by Cole Smith on 11/7/17.
//  Copyright © 2017 Cole Smith. All rights reserved.
//

import Cocoa

class Ticker: NSObject {
    
    private var tickTimer: Timer?
    private let inter: Double!
    private let callback: () -> Void!
    var prices: [String: String]
    
    init(secInterval: Double, tickCallback: @escaping () -> Void) {
        self.prices = [:]
        self.inter = secInterval
        self.callback = tickCallback
        super.init()
    }
    
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
    
    @objc private func tick() {
        self.updatePrices(commodity: "BTC-USD") {
            self.updatePrices(commodity: "ETH-USD") {
                self.callback()
            }
        }
    }
    
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
}
