//
//  StoreKitCommunicator.swift
//  StoreKitHelper
//
//  Created by Marcel Vojtkovszky on 2024-10-17.
//

import Foundation
import StoreKit

final internal class StoreKitCommunicator: Sendable {
    private let autoFinishTransactions: Bool
    
    init(autoFinishTransactions: Bool) {
        self.autoFinishTransactions = autoFinishTransactions
    }
    
    func fetchProductsAsync(productIds: [String]) async -> [Product]? {
        do {
            let products = try await Product.products(for: productIds)
            print("PurchaseHelper products have been fetched \(products.map { $0.id })")
            return products
        } catch {
            print("PurchaseHelper Error fetching products: \(error)")
            return nil
        }
    }
    
    func syncPurchasesAsync() async -> [String] {
        var newPurchasedProductIds: [String] = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if autoFinishTransactions {
                    await transaction.finish()
                }
                newPurchasedProductIds.append(transaction.productID)
            }
        }
        print("PurchaseHelper syncPurchases complete, purchased products: \(newPurchasedProductIds)")
        return newPurchasedProductIds
    }
    
    func purchaseAsync(product: Product, options: Set<Product.PurchaseOption> = []) async -> String? {
        do {
            let result = try await product.purchase(options: options)
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    print("PurchaseHelper transaction verified for \(transaction.productID)")
                    if autoFinishTransactions {
                        await transaction.finish()
                    }
                    return transaction.productID
                case .unverified:
                    print("PurchaseHelper transaction unverified")
                    return nil
                }
            case .userCancelled:
                print("PurchaseHelper user canceled the purchase")
                return nil
            case .pending:
                print("PurchaseHelper purchase pending")
                return nil
            @unknown default:
                print("PurchaseHelper encountered an unknown purchase result")
                return nil
            }
        } catch {
            print("PurchaseHelper failed: \(error)")
            return nil
        }
    }
    
    func listenForTransactionUpdatesAsync() async -> [String] {
        var verifiedProductIdsOutsideTheApp: [String] = []
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                print("PurchaseHelper transaction updated outside the app: \(transaction.productID)")
                if autoFinishTransactions {
                    await transaction.finish()
                }
                verifiedProductIdsOutsideTheApp.append(transaction.productID)
            }
        }
        return verifiedProductIdsOutsideTheApp
    }
}
