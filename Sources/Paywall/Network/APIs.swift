//
//  SuperwallAPI.swift
//  Paywall
//
//  Created by Yusuf Tör on 04/03/2022.
//

import Foundation

enum Api {
  static let version1 = "/api/v1/"
  static let scheme = "https"

  static var hostDomain: String {
    switch Paywall.options.networkEnvironment {
    case .release:
      return "superwall.me"
    case .releaseCandidate:
      return "superwallcanary.com"
    case .developer:
      return "superwall.dev"
    }
  }

  enum Base {
    static var host: String {
      return "api.\(hostDomain)"
    }
  }

  enum Collector {
    static var host: String {
      return "collector.\(hostDomain)"
    }
  }
}
