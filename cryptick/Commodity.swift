//
//  Commodity.swift
//  cryptick
//
//  Created by Cole Smith on 11/9/17.
//  Copyright © 2017 Cole Smith. All rights reserved.
//

import Cocoa

class Commodity: NSObject, NSUserNotificationCenterDelegate {
    
    let name: String
    let symbol: String
    
    var price: String
    var open: String
    var high: String
    var low: String
    
    var priceChange: Float
    var lastUpdate: Date?
    
    var priceWatch: (Double, Bool)?
    
    init(name: String, symbol: String) {
        
        self.name = name
        self.symbol = symbol
        
        self.price = "Loading"
        self.open = "Loading"
        self.high = "Loading"
        self.low = "Loading"
        
        self.priceChange = 0
        self.lastUpdate = nil
        
        super.init()
    }
    
    // MARK: - Getter Methods
    
    func getLabel() -> String {
        var label = String(symbol) + " " + price
        if priceChange == 0 {
            label += " -"
        }
        else if priceChange > 0 {
            label += " ▴"
        }
        else {
            label += " ▾"
        }
        return label
    }
    
    func getAttributedLabel() -> NSAttributedString {
        let label = String(symbol) + " " + price
        let attrLabel = NSMutableAttributedString(string: label)
        let range = (label as NSString).range(of: label)
        
        if priceChange >= 0 {
            attrLabel.addAttribute(.foregroundColor, value: NSColor.green, range: range)
        } else {
            attrLabel.addAttribute(.foregroundColor, value: NSColor.red, range: range)
        }
        
        attrLabel.addAttribute(.font, value: NSFont.systemFont(ofSize: 14.0), range: range)
        return attrLabel
    }
    
    // MARK: - Notification Methods
    
    func setPriceWatch(price: Double, isAbove: Bool) {
        self.priceWatch = (price, isAbove)
    }
    
    // TODO
    func checkPriceWatch() {
        if let pw = priceWatch, let currPrice = Double(price) {
            let watchPrice = pw.0
            let isAbove = pw.1
            
            // Check price is above
            if isAbove && currPrice >  watchPrice {
                // TODO: Trigger Notification
            }

            // Check price is below
            else if !isAbove && currPrice < watchPrice {
                // TODO: Trigger Notification
            }
        }
    }
    
    // MARK: - Value Update Methods
    
    func updatePrice(completion: @escaping () -> Void) {
        
        // Check for ripple
        if symbol == "XRP" {
            updatePriceRipple {
                completion()
            }
            return
        }
        
        let url = URL(string: "https://api.gdax.com/products/" + name + "/ticker")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard let data = data, error == nil else {
                self.price = "Error"
                completion()
                return
            }
            
            do {
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let price = dict?["price"] as? String, let p = Float(price) {
                    
                    // Check if price went up or down
                    if self.price != "Loading", let pp = Float(self.price) {
                        self.priceChange = p - pp
                    }
                    
                    // Update Prices and check price watch
                    self.price = String(format: "%.2f", p)
                    self.checkPriceWatch()
                    completion()
                }
            } catch {
                print(error.localizedDescription)
                self.price = "Error"
                completion()
            }
        }
        
        task.resume()
    }
    
    func updateStats(completion: @escaping () -> Void) {
        
        // Check for ripple
        if symbol == "XRP" {
            updateStatsRipple {
                completion()
            }
            return
        }
        
        let url = URL(string: "https://api.gdax.com/products/" + name + "/stats")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard let data = data, error == nil else {
                self.price = "Error"
                completion()
                return
            }
            
            do {
                if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    for (k, v) in dict {
                        if let p = Float(v) {
                            let val = String(format: "%.2f", p)
                            switch k {
                            case "open":
                                self.open = val
                                break
                            case "high":
                                self.high = val
                                break
                            case "low":
                                self.low = val
                                break
                            default:
                                break
                            }
                        }
                    }
                }
                completion()
            } catch {
                print(error.localizedDescription)
                self.price = "Error"
                completion()
            }
        }
        
        task.resume()
    }
    
    // MARK: - Temporary Ripple Support (Until a better method is found)
    
    // Adds Ripple Support
    func updatePriceRipple(completion: @escaping () -> Void) {
        let url = URL(string:"https://api.coinmarketcap.com/v1/ticker/ripple/?convert=USD")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard let data = data, error == nil else {
                self.price = "Error"
                completion()
                return
            }
            
            do {
                let dict = (try JSONSerialization.jsonObject(with: data, options: []) as! [Any])[0] as! [String: Any]
                if let price = dict["price_usd"] as? String, let p = Float(price) {
                    // Check if price went up or down
                    if self.price != "Loading", let pp = Float(self.price) {
                        self.priceChange = p - pp
                    }

                    // Update Prices and check price watch
                    self.price = String(format: "%.4f", p)
                    self.checkPriceWatch()
                    completion()
                }
            } catch {
                print(error.localizedDescription)
                self.price = "Error"
                completion()
            }
        }
        
        task.resume()
    }
    
    func updateStatsRipple(completion: @escaping () -> Void) {
        open = "Not Available"
        high = "Not Available"
        low = "Not Available"
        completion()
    }
}
