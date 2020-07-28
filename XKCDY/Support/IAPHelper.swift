//
//  IAPHelper.swift
//  XKCDY
//
//  Created by Max Isom on 7/26/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation
import StoreKit
import SwiftyStoreKit
import TPInAppReceipt

enum IAPError: Error {
    case restoreFailed
    case noPreviousValidPurchaseFound
}

public let XKCDYPro = "com.maxisom.XKCDY.pro"
public let SKErrorCodeMapping: [SKError.Code: String] = [
    .unknown: "Unknown error. Please contact support.",
    .clientInvalid: "Not allowed to make the payment.",
    .paymentCancelled: "Unknown error. Please contact support.",
    .paymentInvalid: "The purchase identifier was invalid.",
    .paymentNotAllowed: "The device is not allowed to make the payment.",
    .storeProductNotAvailable: "The product is not available in the current storefront.",
    .cloudServicePermissionDenied: "Access to cloud service information is not allowed.",
    .cloudServiceNetworkConnectionFailed: "Could not connect to the network.",
    .cloudServiceRevoked: "User has revoked permission to use this cloud service."
]

final class IAPHelper {
    private static func hasActiveSubscription() throws -> Bool {
        let receipt = try InAppReceipt.localReceipt()

        return receipt.hasActiveAutoRenewablePurchases
    }

    private static func removeProFeatures() {
        Notifications.unregister()
    }

    static func checkForPurchaseAndUpdate() throws {
        let activeSubscription = try self.hasActiveSubscription()

        UserSettings().isSubscribedToPro = activeSubscription

        if !activeSubscription {
            self.removeProFeatures()
        }
    }

    static func restorePurchases(completion: @escaping (Result<Void, IAPError>) -> Void) {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if results.restoreFailedPurchases.count > 0 {
                completion(.failure(.restoreFailed))
            } else if results.restoredPurchases.count > 0 {
                do {
                    try self.checkForPurchaseAndUpdate()

                    if try self.hasActiveSubscription() {
                        completion(.success(()))
                    } else {
                        completion(.failure(.noPreviousValidPurchaseFound))
                    }
                } catch {
                    completion(.failure(.restoreFailed))
                }
            }
        }
    }

    static func purchasePro(completion: @escaping (PurchaseResult) -> Void) {
        SwiftyStoreKit.purchaseProduct(XKCDYPro, atomically: true) { result in
            do {
                try self.checkForPurchaseAndUpdate()
            } catch {}

            completion(result)
        }
    }
}
