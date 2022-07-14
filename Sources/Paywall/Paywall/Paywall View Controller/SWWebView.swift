//
//  SWWebView.swift
//  Paywall
//
//  Created by Yusuf Tör on 03/03/2022.
//
// swiftlint:disable implicitly_unwrapped_optional

import Foundation
import WebKit
import WebArchiver

protocol SWWebViewDelegate: AnyObject {
  var paywallInfo: PaywallInfo { get }
}

final class SWWebView: WKWebView {
  lazy var eventHandler = WebEventHandler(delegate: delegate)
  weak var delegate: (SWWebViewDelegate & WebEventHandlerDelegate)?

  private var wkConfig: WKWebViewConfiguration = {
    let config = WKWebViewConfiguration()
    config.allowsInlineMediaPlayback = true
    config.allowsAirPlayForMediaPlayback = true
    config.allowsPictureInPictureMediaPlayback = true
    config.mediaTypesRequiringUserActionForPlayback = []

    let preferences = WKPreferences()
    if #available(iOS 15.0, *) {
      if !DeviceHelper.shared.isMac {
        preferences.isTextInteractionEnabled = false // ignore-xcode-12
      }
    }
    preferences.javaScriptCanOpenWindowsAutomatically = true
    config.preferences = preferences
    return config
  }()

  init(delegate: SWWebViewDelegate & WebEventHandlerDelegate) {
    self.delegate = delegate
    super.init(
      frame: .zero,
      configuration: wkConfig
    )
    wkConfig.userContentController.add(
      PaywallMessageHandler(delegate: eventHandler),
      name: "paywallMessageHandler"
    )
    self.navigationDelegate = self

    translatesAutoresizingMaskIntoConstraints = false
    allowsBackForwardNavigationGestures = true
    allowsLinkPreview = false
    backgroundColor = .clear
    scrollView.maximumZoomScale = 1.0
    scrollView.minimumZoomScale = 1.0
    isOpaque = false

    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.bounces = true
    scrollView.contentInset = .zero
    scrollView.scrollIndicatorInsets = .zero
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.maximumZoomScale = 1.0
    scrollView.minimumZoomScale = 1.0
    scrollView.backgroundColor = .clear
    scrollView.isOpaque = false
  }

  func archiveName(for paywallResponse: PaywallResponse) -> String {
    let key = Data(paywallResponse.url.utf8).base64EncodedString()
    return "archive_\(key)_17.webarchive"
  }

  func loadWebpage(paywallResponse: PaywallResponse) {
    let tempDir = FileManager.default.temporaryDirectory
    let tempUrl = tempDir.appendingPathComponent(self.archiveName(for: paywallResponse)).standardizedFileURL
    let manager = FileManager.default
    if manager.fileExists(atPath: tempUrl.path) {
      print("[!] archive load local", tempUrl)
      loadFileURL(tempUrl, allowingReadAccessTo: URL(fileURLWithPath: ""))
    } else {
      let urlString = paywallResponse.url
      guard let url = URL(string: urlString) else {
        return
      }
      print("[!] archive load remote")
      load(URLRequest(url: url))
    }
  }

  func createArchive(paywallResponse: PaywallResponse) {
    let urlString = paywallResponse.url
    guard let url = URL(string: urlString) else { return }
    let tempDir = FileManager.default.temporaryDirectory
    let tempUrl = tempDir.appendingPathComponent(self.archiveName(for: paywallResponse)).standardizedFileURL
    let manager = FileManager.default
    if !manager.fileExists(atPath: tempUrl.path) {
      WebArchiver.archive(url: url, cookies: [], includeJavascript: true, skipCache: true) { result in
        if let data = result.plistData {
          let manager = FileManager.default
          let tempDir = manager.temporaryDirectory
          let tempUrl = tempDir.appendingPathComponent(self.archiveName(for: paywallResponse))
          if !manager.fileExists(atPath: tempUrl.path) {
            print("[!] archive saved to local")
            try? data.write(to: tempUrl)
          }
        }
      }
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - WKNavigationDelegate
extension SWWebView: WKNavigationDelegate {
  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationResponse: WKNavigationResponse,
    decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
  ) {
    guard let statusCode = (navigationResponse.response as? HTTPURLResponse)?.statusCode else {
      // if there's no http status code to act on, exit and allow navigation
      return decisionHandler(.allow)
    }

    // Track paywall errors
    if statusCode >= 400 {
      trackPaywallError()
      return decisionHandler(.cancel)
    }

    decisionHandler(.allow)
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    if webView.isLoading {
      return decisionHandler(.allow)
    }
    if navigationAction.navigationType == .reload {
      return decisionHandler(.allow)
    }
    decisionHandler(.cancel)
  }

  func webView(
    _ webView: WKWebView,
    didFail navigation: WKNavigation!,
    withError error: Error
  ) {
    trackPaywallError()
  }

  func trackPaywallError() {
    delegate?.paywallResponse.webViewLoadFailTime = Date()

    guard let paywallInfo = delegate?.paywallInfo else {
      return
    }

    SessionEventsManager.shared.triggerSession.trackWebviewLoad(
      forPaywallId: paywallInfo.id,
      state: .fail
    )

    let trackedEvent = SuperwallEvent.PaywallWebviewLoad(
      state: .fail,
      paywallInfo: paywallInfo
    )
    Paywall.track(trackedEvent)
  }
}
