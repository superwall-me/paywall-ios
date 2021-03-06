//
//  SWProductDiscount.swift
//  Paywall
//
//  Created by Yusuf Tör on 02/03/2022.
//

import StoreKit

struct SWProductDiscount: Codable {
  enum PaymentMode: String, Codable {
    case payAsYouGo
    case payUpFront
    case freeTrial
    case unknown
  }

  enum DiscountType: String, Codable, Equatable {
    case introductory
    case subscription
    case unknown
  }

  var price: Decimal
  var priceLocale: String
  var identifier: String?
  var subscriptionPeriod: SWProductSubscriptionPeriod
  var numberOfPeriods: Int
  var paymentMode: SWProductDiscount.PaymentMode
  var type: SWProductDiscount.DiscountType

  @available(iOS 12.2, *)
  init(discount: SKProductDiscount) {
    price = discount.price as Decimal
    priceLocale = discount.priceLocale.identifier
    identifier = discount.identifier
    subscriptionPeriod = SWProductSubscriptionPeriod(
      period: discount.subscriptionPeriod,
      numberOfPeriods: discount.numberOfPeriods
    )
    numberOfPeriods = discount.numberOfPeriods

    switch discount.paymentMode {
    case .freeTrial:
      self.paymentMode = .freeTrial
    case .payAsYouGo:
      self.paymentMode = .payAsYouGo
    case .payUpFront:
      self.paymentMode = .payUpFront
    @unknown default:
      self.paymentMode = .unknown
    }

    switch discount.type {
    case .introductory:
      self.type = .introductory
    case .subscription:
      self.type = .subscription
    @unknown default:
      self.type = .unknown
    }
  }
}
