# StoreKitHelper

A lightweight StoreKit2 wrapper designed to simplify purchases with SwiftUI.

## How do I get started

1. Define your in-app purchases (IAPs) or subscriptions by conforming to the `ProductRepresentable` protocol, as shown below:

```swift
enum AppProduct: String, CaseIterable, ProductRepresentable {

    case iap1 = "yourApp.purchase1"
    case iap2 = "yourApp.purchase2"
    case subscription1 = "yourApp.subscription1"
    case subscription2 = "yourApp.subscription2"
    
    func getId() -> String {
        rawValue
    }
}
```

2. Initialize `PurchaseHelper`

```swift
import StoreKitHelper

struct MainView: View {
    @StateObject private var purchaseHelper = PurchaseHelper(products: AppProduct.allCases)
    
    var body: some View {
        VStack {
            ...
        }
        .environmentObject(purchaseHelper)
        .onAppear {
            // this will handle fetching purchases and sync owned purchases
            purchaseHelper.fetchAndSync()
        }
    }
}
```

3. Display and handle purchases anywhere in the app.

```swift
struct PaywallView: View {
    @EnvironmentObject purchaseHelper: PurchaseHelper
    
    var body: some View {
        VStack {
            // get purchase info with all the product data
            let purchase = purchaseHelper.getProduct(AppProduct.subscription1)
            
            // your view presenting the product data
            PurchaseInfoView(purchase)
                .onTapGesture {
                    purchaseHelper.purchase(AppProduct.subscription1)
                }
            }
        }
        .onChange(of: purchaseHelper.loadingInProgress) { newValue in
            if purchaseHelper.isPurchased(AppProduct.subscription1) {
                // Success!
            }
        }
    }
}
```

Since `PurchaseHelper` is an `ObservableObject`, any change will automatically propagate to the views utilizing any of the public properties.


## Is That All?

Yes, that’s all you need to get started! There’s no unnecessary boilerplate or overcomplicated abstractions. Everything runs smoothly behind the scenes.

For more advanced configurations and details, check out the public properties and functions in the `PurchaseHelper` class.


## Installation

To integrate `StoreKitHelper` into your project, add it via Swift Package Manager or manually.

### Swift Package Manager
1. In Xcode, select `File > Add Packages`.
2. Enter the URL of the StoreKitHelper repository.
3. Choose the latest version and install.


## Contributing

Missing something or have suggestions? Feel free to open a PR, and we’ll take a look!
