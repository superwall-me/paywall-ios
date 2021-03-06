import XCTest
@testable import Paywall
import CoreMedia

// swiftlint:disable all

let response = #"""
{
  "triggers": [
    {
      "trigger_version": "V2",
      "event_name": "opened_application",
      "rules": [
        {
          "experiment_group_id": "1",
          "experiment_id": "2",
          "expression": "name == jake",
          "assigned": false,
          "variant": {
            "variant_id": "7",
            "variant_type": "HOLDOUT"
          }
        },
        {
          "experiment_group_id": "1",
          "experiment_id": "2",
          "expression": null,
          "assigned": false,
          "variant": {
            "variant_id": "6",
            "variant_type": "TREATMENT",
            "paywall_identifier": "omnis-id-ab"
          }
        }
      ]
    }
  ],
  "product_identifier_groups": [],
  "paywalls": [],
  "log_level": 10,
  "postback": {
    "delay": 5000,
    "products": []
  },
  "localization": {
    "locales": [{
      "locale": "en_US"
    }]
  },
  "app_session_timeout_ms": 3600000,
  "tests": {
    "dns_resolution": []
  }
}
"""#

final class ConfigTypeTests: XCTestCase {
  func testParseConfig() throws {
    let parsedResponse = try! JSONDecoder.fromSnakeCase.decode(
      Config.self,
      from: response.data(using: .utf8)!
    )
    print(parsedResponse)

    guard let trigger = parsedResponse.triggers.filter({ $0.eventName == "opened_application" }).first
    else {
      return XCTFail("opened_application trigger not found")
    }

    let firstRule = trigger.rules[0]
    XCTAssertEqual(firstRule.isAssigned, false)
    XCTAssertEqual(firstRule.expression, "name == jake")
    XCTAssertEqual(firstRule.experiment.id, "2")

    switch firstRule.experiment.variant.type {
    case .treatment:
      throw TestError.init("Expecting Holdout")
    case .holdout:
      XCTAssertEqual(firstRule.experiment.variant.id, "7")
    }
    let secondRule = trigger.rules[1]

    switch secondRule.experiment.variant.type {
    case .holdout:
      throw TestError.init("Expecting holdout")
    case .treatment:
      XCTAssertEqual(secondRule.experiment.variant.paywallId, "omnis-id-ab")
      XCTAssertEqual(secondRule.experiment.variant.id, "6")
    }
  }
}
