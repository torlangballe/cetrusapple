//
//  ZInAppPurchases.swift
//  capsulefm
//
//  Created by Tor Langballe on /3/9/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

// test with:
// torlangballe+test1@gmail.com
// tortest@capsule.fm

import Foundation
import StoreKit

struct ZInAppProduct {
    var sid = ""
    var name = ""
    var price = ""
}

class ZInAppPurchases : NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    var allSKProducts = [SKProduct]()
    var saveStoreCountryCodeFunc: ((_ ccode:String)->Void)? = nil
    var handlePurchaseSuccess: ((_ productId: String, _ done:@escaping ()->Void)->Void)? = nil
    //    private var purchasedProductIdentifiers = Set()
    var productsRequest: SKProductsRequest?
    var gotProductsRequestHandler: ((_ products:[ZInAppProduct], _ error:Error?)->Void)?

    func RequestProducts(_ ids:Set<String>, got:@escaping (_ products:[ZInAppProduct], _ error:Error?)->Void) {
        productsRequest?.cancel()
        gotProductsRequestHandler = got
        productsRequest = SKProductsRequest(productIdentifiers:ids)
        productsRequest!.delegate = self
        productsRequest!.start()
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency

        var products = [ZInAppProduct]()
        var first = true
        for skp in response.products {
            var p = ZInAppProduct()
            p.sid = skp.productIdentifier
            formatter.locale = skp.priceLocale
            p.price = formatter.string(from: skp.price) ?? "?"
            p.name = skp.localizedTitle
            products.append(p)
            if first {
                first = false
                if let ccode = (skp.priceLocale as NSLocale).object(forKey: .countryCode) as? String {
                    saveStoreCountryCodeFunc?(ccode.lowercased())
                }
            }
        }
        allSKProducts = response.products
        gotProductsRequestHandler?(products, nil)
        clearRequestAndHandler()
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        ZDebug.Print("Failed to load list of products:", error.localizedDescription)
        gotProductsRequestHandler?([], error)
        clearRequestAndHandler()
    }
    
    fileprivate func clearRequestAndHandler() {
        productsRequest = nil
        gotProductsRequestHandler = nil
    }

    func BuyProduct(sid:String) {
        if !SKPaymentQueue.canMakePayments() {
            ZAlert.Say(ZTS("You are not set up to purchase in-app payments.")) // dialog box when user tries to buy in-app-purchase
            return
        }
        if let i = allSKProducts.index(where:{ $0.productIdentifier == sid }) {
            let product = allSKProducts[i]
            let payment = SKPayment(product:product)
            ZKeyValueStore.SetBool(true, key:"ZInAppPurchasesInProgress")
            SKPaymentQueue.default().add(payment)
        } else {
            ZAlert.Say(ZTS("Couldn't find that product to purchase. Strange error. Maybe restart app.")) // dialog box when user tries to buy in-app-purchase, but something weird happens
        }
    }

    func CheckPurchasedItems() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue:SKPaymentQueue) {
        for transaction in queue.transactions {
            let _ = transaction.payment.productIdentifier
        }
    }
    
    func failedTransaction(_ transaction:SKPaymentTransaction) {
        // https://developer.apple.com/library/content/releasenotes/General/iOS93APIDiffs/Swift/StoreKit.html
        ZDebug.Print("SK.failedTransaction state:", transaction.transactionState, transaction.error)
        finishTransaction(transaction, wasSuccessful:false)
    }

    func finishTransaction(_ transaction:SKPaymentTransaction, wasSuccessful:Bool) {
        ZKeyValueStore.SetBool(false, key:"ZInAppPurchasesInProgress")
        if wasSuccessful {
            let productId = transaction.payment.productIdentifier
            handlePurchaseSuccess?(productId, { () in
                SKPaymentQueue.default().finishTransaction(transaction)
            })
        } else {
            SKPaymentQueue.default().finishTransaction(transaction)
        }
    }
    
    func paymentQueue(_ queue:SKPaymentQueue, updatedTransactions:[SKPaymentTransaction]) {
        for transaction in updatedTransactions {
            switch transaction.transactionState {
                case .purchased, .restored:
                    self.finishTransaction(transaction, wasSuccessful:true)
                case .failed:
                    failedTransaction(transaction)
                case .purchasing:
                    print("Purchasing...")
                default:
                    break
            }
        }
    }
    
    func SetAsObserver() {
        SKPaymentQueue.default().add(self)
        if ZKeyValueStore.BoolForKey("ZInAppPurchasesInProgress") {
            CheckPurchasedItems()
        }
    }
}
