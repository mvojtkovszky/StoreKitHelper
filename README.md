# StoreKitHelper

A lightweight StoreKit2 wrapper designed to simplify purchases with SwiftUI.

## How do I get started

1. Define your in-app purchases (IAPs) or subscriptions by conforming to the `ProductRepresentable` protocol, for example:

```swift
enum AppProduct: String, CaseIterable, ProductRepresentable {
    case iap1 = "yourApp.purchase1"
    case iap2 = "yourApp.purchase2"
    case subscription1 = "yourApp.subscription1"
    case subscription2 = "yourApp.subscription2"
    
    // ProductRepresentable requires this
    func getId() -> String {
        rawValue
    }
}
```

2. Initialize `PurchaseHelper`, your MainView may look something like this:

```swift
struct MainView: View {
    @StateObject private var purchaseHelper = PurchaseHelper(products: AppProduct.allCases)
    
    var body: some View {
        VStack {
            ...
        }
        .environmentObject(purchaseHelper)
        .onAppear {
            // this will handle fetching purchases and syncing owned purchases
            purchaseHelper.fetchAndSync()
        }
        .onChange(of: purchaseHelper.purchasesReady) { newValue in
            // do something when products are fetched and purchases synced. That's when it's safe to definitively evaluate if user actually has any entitlements
        }
    }
}
```

3. Display and handle product purchases anywhere in the app.

```swift
struct PaywallView: View {
    @EnvironmentObject purchaseHelper: PurchaseHelper
    
    var body: some View {
        VStack {
            if let product = purchaseHelper.getProduct(AppProduct.subscription1) {
                VStack {
                    // title and price
                    Text(product.displayName)
                    Text(product.displayPrice)
                    // subscribe button
                    Button("Subscribe") {
                        // init purchase flow
                        purchaseHelper.purchase(AppProduct.subscription1)
                    }
                    .disabled(purchaseHelper.loadingInProgress)
                }
            }
        }
        .onChange(of: purchaseHelper.isPurchased(AppProduct.subscription1)) { isPurchased in
            if isPurchased {
                // Success!
            }
        }
    }
}
```

Since `PurchaseHelper` is an `ObservableObject`, any change will automatically propagate to the views utilizing any of the public properties or getters using those properties, as demonstrated in the example above.


## Is That All?

Yes, that’s all you need to get started! There’s no unnecessary boilerplate or overcomplicated abstractions. Everything runs smoothly behind the scenes.

For more advanced configurations and details, check out the public properties and functions in the `PurchaseHelper` class.


## Installation

To integrate it into your project, add it via Swift Package Manager or manually.

### Swift Package Manager
1. In Xcode, select `File > Add Packages`.
2. Enter the URL of the StoreKitHelper repository.
3. Choose the latest version and install.


## Contributing

Missing something or have suggestions? Feel free to open a PR, and we’ll take a look!
