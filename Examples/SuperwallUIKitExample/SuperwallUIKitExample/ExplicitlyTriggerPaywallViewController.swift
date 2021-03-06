//
//  ExplicitlyTriggerPaywallViewController.swift
//  SuperwallUIKitExample
//
//  Created by Yusuf Tör on 05/04/2022.
//

import UIKit
import Paywall
import Combine

final class ExplicitlyTriggerPaywallViewController: UIViewController {
  @IBOutlet private var subscriptionLabel: UILabel!
  private var cancellables: Set<AnyCancellable> = []

  static func fromStoryboard() -> ExplicitlyTriggerPaywallViewController {
    let storyboard = UIStoryboard(
      name: "Main",
      bundle: nil
    )
    let controller = storyboard.instantiateViewController(
      withIdentifier: "ExplicitlyTriggerPaywallViewController"
    ) as! ExplicitlyTriggerPaywallViewController
    // swiftlint:disable:previous force_cast

    return controller
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    StoreKitService.shared.isSubscribed
      .sink { [weak self] isSubscribed in
        if isSubscribed {
          self?.subscriptionLabel.text = "You currently have an active subscription. Therefore, the paywall will never show. For the purposes of this app, delete and reinstall the app to clear subscriptions."
        } else {
          self?.subscriptionLabel.text = "You do not have an active subscription so the paywall will show when clicking the button."
        }
      }
      .store(in: &cancellables)
  }

  @IBAction private func explicitlyTriggerPaywall() {
    Paywall.trigger(event: "MyEvent") { error in
      if error?.code == 4000 {
        print("The user did not match any rules")
      } else if error?.code == 4001 {
        print("The user is in a holdout group")
      } else {
        print("did fail", error)
      }
    } onPresent: { paywallInfo in
      print("paywall info is", paywallInfo)
    } onDismiss: { didPurchase, productId, paywallInfo in
      if didPurchase {
        print("The purchased product ID is", productId)
      } else {
        print("The info of the paywall is", paywallInfo)
      }
    }
  }
}
