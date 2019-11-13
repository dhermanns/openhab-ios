// Copyright (c) 2010-2019 Contributors to the openHAB project
//
// See the NOTICE file(s) distributed with this work for additional
// information.
//
// This program and the accompanying materials are made available under the
// terms of the Eclipse Public License 2.0 which is available at
// http://www.eclipse.org/legal/epl-2.0
//
// SPDX-License-Identifier: EPL-2.0

import Kingfisher
import WatchConnectivity
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    static var extensionDelegate: ExtensionDelegate!

    var appData = OpenHABDataObject()

    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = AppMessageService.singleton
                session.activate()
            }
        }
    }

    override init() {
        appData = OpenHABDataObject()
        super.init()
        ExtensionDelegate.extensionDelegate = self

        ImageDownloader.default.authenticationChallengeResponder = self
    }

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        activateWatchConnectivity()

        NetworkConnection.initialize(ignoreSSL: Preferences.ignoreSSL, adapter: OpenHABAccessTokenAdapter())

        NetworkConnection.shared.assignDelegates(serverDelegate: self, clientDelegate: self)

        KingfisherManager.shared.defaultOptions = [.requestModifier(OpenHABAccessTokenAdapter())]
    }

    func activateWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
        }
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AppState.singleton.active = true
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        AppState.singleton.active = false
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}

// MARK: Kingfisher authentication with NSURLCredential

extension ExtensionDelegate: AuthenticationChallengeResponsable {
    // sessionDelegate.onReceiveSessionTaskChallenge
    func downloader(_ downloader: ImageDownloader,
                    task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let (disposition, credential) = onReceiveSessionTaskChallenge(URLSession(configuration: .default), task, challenge)
        completionHandler(disposition, credential)
    }

    // sessionDelegate.onReceiveSessionChallenge
    func downloader(_ downloader: ImageDownloader,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let (disposition, credential) = onReceiveSessionChallenge(URLSession(configuration: .default), challenge)
        completionHandler(disposition, credential)
    }
}

// MARK: - ServerCertificateManagerDelegate

extension ExtensionDelegate: ServerCertificateManagerDelegate {
    // delegate should ask user for a decision on what to do with invalid certificate
    func evaluateServerTrust(_ policy: ServerCertificateManager?, summary certificateSummary: String?, forDomain domain: String?) {
        policy?.evaluateResult = .permitAlways

//            let alertView = UIAlertController(title: "SSL Certificate Warning", message: "SSL Certificate presented by \(certificateSummary ?? "") for \(domain ?? "") is invalid. Do you want to proceed?", preferredStyle: .alert)
//            alertView.addAction(UIAlertAction(title: "Abort", style: .default) { _ in policy?.evaluateResult = .deny })
//            alertView.addAction(UIAlertAction(title: "Once", style: .default) { _ in policy?.evaluateResult = .permitOnce })
//            alertView.addAction(UIAlertAction(title: "Always", style: .default) { _ in policy?.evaluateResult = .permitAlways })
//            self.present(alertView, animated: true) {}
//        }
    }

    // certificate received from openHAB doesn't match our record, ask user for a decision
    func evaluateCertificateMismatch(_ policy: ServerCertificateManager?, summary certificateSummary: String?, forDomain domain: String?) {
        policy?.evaluateResult = .permitAlways
//        DispatchQueue.main.async {
//            let alertView = UIAlertController(title: "SSL Certificate Warning", message: "SSL Certificate presented by \(certificateSummary ?? "") for \(domain ?? "") doesn't match the record. Do you want to proceed?", preferredStyle: .alert)
//            alertView.addAction(UIAlertAction(title: "Abort", style: .default) { _ in policy?.evaluateResult = .deny })
//            alertView.addAction(UIAlertAction(title: "Once", style: .default) { _ in policy?.evaluateResult = .permitOnce })
//            alertView.addAction(UIAlertAction(title: "Always", style: .default) { _ in policy?.evaluateResult = .permitAlways })
//            self.present(alertView, animated: true) {}
//        }
    }
}

// MARK: - ClientCertificateManagerDelegate

extension ExtensionDelegate: ClientCertificateManagerDelegate {
    // delegate should ask user for a decision on whether to import the client certificate into the keychain
    func askForClientCertificateImport(_ clientCertificateManager: ClientCertificateManager?) {
        clientCertificateManager!.clientCertificateAccepted(password: nil)
//        DispatchQueue.main.async {
//            let alertController = UIAlertController(title: "Client Certificate Import", message: "Import client certificate into the keychain?", preferredStyle: .alert)
//            let okay = UIAlertAction(title: "Okay", style: .default) { (_: UIAlertAction) in
//                clientCertificateManager!.clientCertificateAccepted(password: nil)
//            }
//            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_: UIAlertAction) in
//                clientCertificateManager!.clientCertificateRejected()
//            }
//            alertController.addAction(okay)
//            alertController.addAction(cancel)
//            self.present(alertController, animated: true, completion: nil)
//        }
    }

    // delegate should ask user for the export password used to decode the PKCS#12
    func askForCertificatePassword(_ clientCertificateManager: ClientCertificateManager?) {
//        clientCertificateManager!.clientCertificateAccepted(password: password)

//        DispatchQueue.main.async {
//            let alertController = UIAlertController(title: "Client Certificate Import", message: "Password required for import.", preferredStyle: .alert)
//            let okay = UIAlertAction(title: "Okay", style: .default) { (_: UIAlertAction) in
//                let txtField = alertController.textFields?.first
//                let password = txtField?.text
//                clientCertificateManager!.clientCertificateAccepted(password: password)
//            }
//            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_: UIAlertAction) in
//                clientCertificateManager!.clientCertificateRejected()
//            }
//            alertController.addTextField { textField in
//                textField.placeholder = "Password"
//                textField.isSecureTextEntry = true
//            }
//            alertController.addAction(okay)
//            alertController.addAction(cancel)
//            self.present(alertController, animated: true, completion: nil)
//        }
    }

    // delegate should alert the user that an error occured importing the certificate
    func alertClientCertificateError(_ clientCertificateManager: ClientCertificateManager?, errMsg: String) {
//        DispatchQueue.main.async {
//            let alertController = UIAlertController(title: "Client Certificate Import", message: errMsg, preferredStyle: .alert)
//            let okay = UIAlertAction(title: "Okay", style: .default)
//            alertController.addAction(okay)
//            self.present(alertController, animated: true, completion: nil)
//        }
    }
}
