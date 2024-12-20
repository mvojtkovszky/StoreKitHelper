//
//  PurchaseHelper.swift
//  StoreKitHelper
//
//  Created by Marcel Vojtkovszky on 2024-10-17.
//

import Foundation
import StoreKit
import Combine

@MainActor
public class PurchaseHelper: ObservableObject {
    
    /// Indicated if products have been fetched (if `fetchProducts` or `fetchAndSync` has been called yet)
    @Published private(set) public var productsFetched: Bool = false
    /// Indicated if purchases have been synced (if `syncPurchases` or `fetchAndSync` has been called yet)
    @Published private(set) public var purchasesSynced: Bool = false
    /// Indicates if we have all products and purchases fetched, in practice meaning we can safely use all the methods
    public var purchasesReady: Bool {
        return productsFetched && purchasesSynced
    }
    /// Is `true` whenever products are fetching, syncyng purchases is in progress, or purchase is in progress - but only one of those at once
    @Published private(set) public var loadingInProgress: Bool = false
    
    @Published private var purchasedProductIds: [String] = [] // active purchases
    @Published private var products: [Product] = [] // StoreKit products
    
    private let allProductIds: [String]
    private let storeKitCommunicator: StoreKitCommunicator
    
    
    /// Initialize helper
    /// - Parameters:
    ///   - products: all product ids supported by the app.
    ///   - autoFinishTransactions: call `Transaction.finish()` on verified transactions. `true` by default. Let it be unless you verify your transaction on own backend.
    ///   - grantExternalEntitlements: will mark product as purchased if it originated from transaction updates for verified transactions
    public init(
        products: [ProductRepresentable],
        autoFinishTransactions: Bool = true,
        grantExternalEntitlements: Bool = true
    ) {
        self.allProductIds = products.map { $0.getId() }
        self.storeKitCommunicator = StoreKitCommunicator(autoFinishTransactions: autoFinishTransactions)
        
        Task {
            // listen for updates outside of the app
            for productId in await storeKitCommunicator.listenForTransactionUpdatesAsync() {
                updateUI { [weak self] in
                    guard let self else { return }
                    if grantExternalEntitlements && !self.purchasedProductIds.contains(productId) {
                        self.purchasedProductIds.append(productId)
                    }
                }
            }
        }
    }
    
    /// Determine if a given product has been purchased.
    public func isPurchased(_ product: ProductRepresentable) -> Bool {
        guard purchasesSynced else {
            print("PurchaseHelper purchases not synced yet. Call syncPurchases() first")
            return false
        }
        return purchasedProductIds.contains(product.getId())
    }
    
    /// Get `StoreKit`product for given app product.
    /// Make sure `fetchAndSync` or `fetchProducts` is called before that
    public func getProduct(_ product: ProductRepresentable) -> Product? {
        guard productsFetched else {
            print("PurchaseHelper products not fetched yet. Call fetchProducts() first")
            return nil
        }
        return products.first { $0.id == product.getId() }
    }
    
    /// Will initialize and handle fetching products and syncing purchases.
    /// Suggested to call this when view appears as it will guarantee as it will result in `productsFetched` and `purchasesSynced` being true.
    /// Note: Products will not be fetched if already fetched before, but purchases will always be re-evaluated.
    public func fetchAndSync() {
        guard !loadingInProgress else {
            print("PurchaseHelper loading is in progress, fetchAndSync() ignored")
            return
        }
        
        print("PurchaseHelper fetchAndSync()")
        self.loadingInProgress = true
        let willFetchProducts = !self.productsFetched
        let productIds = self.allProductIds
        
        Task {
            async let fetchTask: [Product]? = willFetchProducts ? storeKitCommunicator.fetchProductsAsync(productIds: productIds) : nil
            async let syncTask: [String] = storeKitCommunicator.syncPurchasesAsync()
            
            let fetchedProducts = await fetchTask
            let syncedIds = await syncTask
            
            updateUI { [weak self] in
                guard let self = self else { return }
                if let products = fetchedProducts {
                    self.products = products
                    self.productsFetched = true
                }
                self.purchasedProductIds = syncedIds
                self.purchasesSynced = true
                self.loadingInProgress = false
            }
        }
    }
    
    /// Fetches products from the store. You can then retrieve a product by calling `getProduct()`
    /// - While the process is in progress, `loadingInProgress` will be `true`
    public func fetchProducts() {
        guard !loadingInProgress else {
            print("PurchaseHelper loading is in progress, fetchProducts() ignored")
            return
        }
        
        print("PurchaseHelper fetchProducts()")
        self.loadingInProgress = true
        let productIds = self.allProductIds
        
        Task {
            let products = await storeKitCommunicator.fetchProductsAsync(productIds: productIds)
            updateUI { [weak self] in
                guard let self = self else { return }
                self.products = products ?? []
                self.productsFetched = true
                self.loadingInProgress = false
            }
        }
    }
    
    /// Synch owned purchases (entitlements) from the store
    /// - While the process is in progress, `loadingInProgress` will be `true`
    public func syncPurchases() {
        guard !loadingInProgress else {
            print("PurchaseHelper loading is in progress, syncPurchases() ignored")
            return
        }
        
        print("PurchaseHelper syncPurchases()")
        self.loadingInProgress = true
        
        Task {
            let purchasedProductIds = await storeKitCommunicator.syncPurchasesAsync()
            updateUI { [weak self] in
                guard let self = self else { return }
                self.purchasedProductIds = purchasedProductIds
                self.purchasesSynced = true
                self.loadingInProgress = false
            }
        }
    }
    
    /// Init purchase of a given product, with optionally provided `options`
    /// - While the process is in progress, `loadingInProgress` will be `true`
    public func purchase(_ product: ProductRepresentable, options: Set<Product.PurchaseOption> = []) {
        guard !loadingInProgress else {
            print("PurchaseHelper loading is in progress, purchase() ignored")
            return
        }
        
        print("PurchaseHelper purchase \(product.getId())")
        self.loadingInProgress = true
        
        if let storeProduct = getProduct(product) {
            Task {
                let productId = await storeKitCommunicator.purchaseAsync(product: storeProduct, options: options)
                updateUI { [weak self] in
                    guard let self = self else { return }
                    if let productId, !self.purchasedProductIds.contains(productId) {
                        self.purchasedProductIds.append(productId)
                    }
                    self.loadingInProgress = false
                }
            }
        } else {
            print("PurchaseHelper no product found with id \(product.getId())")
        }
    }

    private func updateUI(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
}
