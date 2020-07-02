//
//  IAPHelper.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 06/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import StoreKit

struct ReceiptData: Codable {
    let receipt: String
    let sandbox: Bool
}

struct AppStoreValidationResult: Codable {
    let status: Int
    let environment: String
}

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

extension Notification.Name {
    static let IAPHelperPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
}

protocol IAPHelperDelegate: class {
    
    func didFail(with error: String)
    func previouslyPurchased(status: Bool)
}

open class IAPHelper: NSObject {
    
    private let productIdentifiers: Set<ProductIdentifier>
    private var purchasedProductIdentifiers: Set<ProductIdentifier> = []
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    
    weak var delegate: IAPHelperDelegate?
    
    public init(productIds: Set<ProductIdentifier>) {
        
        productIdentifiers = productIds
        for productIdentifier in productIds {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                print("Previously purchased: \(productIdentifier)")
            } else {
                print("Not purchased: \(productIdentifier)")
            }
            
            delegate?.previouslyPurchased(status: purchased)
        }
        super.init()
        
        SKPaymentQueue.default().add(self)
        
        if let receiptUrl = Bundle.main.appStoreReceiptURL {
            
            let receiptData = try! Data(contentsOf: receiptUrl, options: .alwaysMapped)
        
            verifyIfPurchasedBeforeFreemium(productionStoreURL!, receiptData)
        }
            
        
        
    }
    
    private let productionStoreURL = URL(string: "https://buy.itunes.apple.com/verifyReceipt")
    private let sandboxStoreURL = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")

    private func verifyIfPurchasedBeforeFreemium(_ storeURL: URL, _ receipt: Data) {
        do {
            let requestContents:Dictionary = ["receipt-data": receipt.base64EncodedString()]
            let requestData = try JSONSerialization.data(withJSONObject: requestContents, options: [])

            var storeRequest = URLRequest(url: storeURL)
            storeRequest.httpMethod = "POST"
            storeRequest.httpBody = requestData

            URLSession.shared.dataTask(with: storeRequest) { (data, response, error) in
                DispatchQueue.main.async {
                    if data != nil {
                        do {
                            let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any?]

                            if let statusCode = jsonResponse["status"] as? Int {
                                if statusCode == 21007 {
                                    print("Switching to test against sandbox")
                                    self.verifyIfPurchasedBeforeFreemium(self.sandboxStoreURL!, receipt)
                                }
                            }

                            if let receiptResponse = jsonResponse["receipt"] as? [String: Any?], let originalVersion = receiptResponse["original_application_version"] as? String {
                                if self.isPaidVersionNumber(originalVersion) {
                                    // Update to full paid version of app
                                    print("HEHE")
//                                    UserDefaults.standard.set(true, forKey: upgradeKeys.isUpgraded)
//                                    NotificationCenter.default.post(name: .UpgradedVersionNotification, object: nil)
                                }
                            }
                        } catch {
                            print("Error: " + error.localizedDescription)
                        }
                    }
                }
                }.resume()
        } catch {
            print("Error: " + error.localizedDescription)
        }
    }

    private func isPaidVersionNumber(_ originalVersion: String) -> Bool {
        let pattern:String = "^\\d+\\.\\d+"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let results = regex.matches(in: originalVersion, options: [], range: NSMakeRange(0, originalVersion.count))

            let original = results.map {
                Double(originalVersion[Range($0.range, in: originalVersion)!])
            }
            
            print("HEHE")
            
            return true

//            if original.count > 0, original[0]! < firstFreemiumVersion {
//                print("App purchased prior to Freemium model")
//                return true
//            }
        } catch {
            print("Paid Version RegEx Error.")
        }
        return false
    }
}

extension IAPHelper: SKRequestDelegate {
    
    public func requestDidFinish(_ request: SKRequest) {
        dump(request)
    }
}

// MARK: - StoreKit API

extension IAPHelper {
    
    public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(_ product: SKProduct) {
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        
        let defaults = UserDefaults(suiteName: Constants.appGroupsBundleID)!
        
        return defaults.bool(forKey: StoreKitProducts.DataInsights)
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Loaded list of products...")
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                complete(transaction: transaction)
            case .failed:
                fail(transaction: transaction)
            case .restored:
                restore(transaction: transaction)
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
    }
    
//    func validateReceipt() {
//
//        guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
//            return
//        }
//
//
//        do {
//
//            let receiptURL = Bundle.main.appStoreReceiptURL!
//
//            // We are running in sandbox when receipt URL ends with 'sandboxReceipt'
//            let isSandbox = receiptURL.absoluteString.hasSuffix("sandboxReceipt")
//            let receiptData = try Data(contentsOf: receiptURL)
//
//
//
//        } catch {
//            print("errorrrr \(error)")
//        }
//    }
    
    private func complete(transaction: SKPaymentTransaction) {
        print("complete...")
        deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        // Get the receipt if it's available
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
            FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                print(receiptData)
                
                let receiptString = receiptData.base64EncodedString(options: [])
                
                // Read receiptData
                print(receiptString)
                
            }
            catch { print("Couldn't read receipt data with error: " + error.localizedDescription) }
        }
        
        
        print("restore... \(productIdentifier)")
        deliverPurchaseNotificationFor(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("fail...")
        if let transactionError = transaction.error as NSError?,
            let localizedDescription = transaction.error?.localizedDescription,
            transactionError.code != SKError.paymentCancelled.rawValue {
            print("Transaction Error: \(localizedDescription)")
            delegate?.didFail(with: localizedDescription)
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
        
        purchasedProductIdentifiers.insert(identifier)
        let defaults = UserDefaults(suiteName: Constants.appGroupsBundleID)!
        
        defaults.set(true, forKey: StoreKitProducts.DataInsights)
        NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: identifier)
    }
}
