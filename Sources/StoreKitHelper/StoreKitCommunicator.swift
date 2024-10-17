//
//  StoreKitCommunicator.swift
//  StoreKitHelper
//
//  Created by Marcel Vojtkovszky on 2024-10-17.
//

import Foundation
import StoreKit

internal class StoreKitCommunicator {
    
    func fetchProductsAsync(productIds: [String], callback: ([Product]?, Error?) -> Void) async {
        do {
            let products = try await Product.products(for: productIds)
            print("PurchaseHelper products have been fetched \(products.map({ $0.id }))")
            callback(products, nil)
        } catch {
            print("PurchaseHelper Error fetching products: \(error)")
            callback(nil, error)
        }
    }
    
    func syncPurchasesAsync(callback: ([String]) -> Void) async {
        var newPurchasedProductIds: [String] = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                newPurchasedProductIds.append(transaction.productID)
                await transaction.finish()
            }
        }
        print("PurchaseHelper syncPurchases complete, purchased products: \(newPurchasedProductIds)")
        callback(newPurchasedProductIds)
    }
    
    func purchaseAsync(product: Product, options: Set<Product.PurchaseOption> = [], callback: (String?) -> Void) async {
        do {
            let result = try await product.purchase(options: options)
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    print("PurchaseHelper transaction verified for \(transaction.productID)")
                    await transaction.finish()
                    callback(transaction.productID)
                case .unverified:
                    print("PurchaseHelper transaction unverified")
                    callback(nil)
                }
            case .userCancelled:
                print("PurchaseHelper user canceled the purchase")
                callback(nil)
            case .pending:
                print("PurchaseHelper purchase pending")
                callback(nil)
            @unknown default:
                print("PurchaseHelper encountered an unknown purchase result")
                callback(nil)
            }
        } catch {
            print("PurchaseHelper failed: \(error)")
            callback(nil)
        }
    }
    
    func listenForTransactionUpdatesAsync(callback: (String) -> Void) async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                print("PurchaseHelper transaction updated outside the app: \(transaction.productID)")
                callback(transaction.productID)
                await transaction.finish()
            }
        }
    }
}
