import StoreKit
import SwiftUI

@MainActor
final class ProStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro = false
    @Published var message = ""

    private let productIDs = [
        "com.timemarkvn.pro.monthly",
        "com.timemarkvn.pro.yearly",
        "com.timemarkvn.pro.lifetime"
    ]

    init() {
        Task {
            await refresh()
            await listenForTransactions()
        }
    }

    func refresh() async {
        do {
            products = try await Product.products(for: productIDs).sorted { $0.price < $1.price }
            await updateEntitlement()
        } catch {
            message = "Không tải được sản phẩm."
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updateEntitlement()
                case .unverified:
                    message = "Không xác minh được giao dịch."
                }
            case .userCancelled:
                break
            case .pending:
                message = "Giao dịch đang chờ xử lý."
            @unknown default:
                break
            }
        } catch {
            message = "Mua Pro thất bại."
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await updateEntitlement()
        } catch {
            message = "Không thể khôi phục giao dịch."
        }
    }

    private func updateEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPro = active
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await updateEntitlement()
            }
        }
    }
}
