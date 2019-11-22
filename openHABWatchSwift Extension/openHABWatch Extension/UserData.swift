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

import Alamofire
import Combine
import Foundation
import OpenHABCoreWatch
import os.log
import SwiftUI

final class UserData: ObservableObject {
    @Published var widgets: [ObservableOpenHABWidget] = []

    let decoder = JSONDecoder()

    var openHABSitemapPage: ObservableOpenHABSitemapPage?

    private var commandOperation: Alamofire.Request?
    private var currentPageOperation: Alamofire.Request?

    var pageURL: URL?

    init() {
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)

        let data = PreviewConstants.sitemapJson

        do {
            // Self-executing closure
            // Inspired by https://www.swiftbysundell.com/posts/inline-types-and-functions-in-swift
            openHABSitemapPage = try {
                let sitemapPageCodingData = try data.decoded() as ObservableOpenHABSitemapPage.CodingData
                return sitemapPageCodingData.openHABSitemapPage
            }()
        } catch {
            os_log("Should not throw %{PUBLIC}@", log: OSLog.remoteAccess, type: .error, error.localizedDescription)
        }

        widgets = openHABSitemapPage?.widgets ?? []

        openHABSitemapPage?.sendCommand = { [weak self] item, command in
            self?.sendCommand(item, commandToSend: command)
        }
    }

    init(urlString: String, refresh: Bool) {
        pageURL = Endpoint.watchSitemap(openHABRootUrl: urlString, sitemapName: "watch").url
        loadPage(longPolling: false, refresh: refresh)
    }

    func loadPage(longPolling: Bool, refresh: Bool) {
        if currentPageOperation != nil {
            currentPageOperation?.cancel()
            currentPageOperation = nil
        }

        guard let pageURL = pageURL else { return }
        os_log("pageURL = %{PUBLIC}@", log: OSLog.remoteAccess, type: .info, pageURL.absoluteString)

        currentPageOperation = NetworkConnection.page(url: pageURL,
                                                      longPolling: longPolling,
                                                      openHABVersion: 2) { [weak self] response in
            guard let self = self else { return }

            switch response.result {
            case .success:

                self.openHABSitemapPage?.sendCommand = { [weak self] item, command in
                    self?.sendCommand(item, commandToSend: command)
                }

                self.widgets = self.openHABSitemapPage?.widgets ?? []

                let headers = response.response?.allHeaderFields

                NetworkConnection.atmosphereTrackingId = headers?["X-Atmosphere-tracking-id"] as? String ?? ""
                if !NetworkConnection.atmosphereTrackingId.isEmpty {
                    os_log("Found X-Atmosphere-tracking-id: %{PUBLIC}@", log: .remoteAccess, type: .info, NetworkConnection.atmosphereTrackingId)
                }
                if let data = response.result.value {
                    // Newer versions talk JSON!
                    os_log("openHAB 2", log: OSLog.remoteAccess, type: .info)
                    do {
                        // Self-executing closure
                        // Inspired by https://www.swiftbysundell.com/posts/inline-types-and-functions-in-swift
                        self.openHABSitemapPage = try {
                            let sitemapPageCodingData = try data.decoded() as ObservableOpenHABSitemapPage.CodingData
                            return sitemapPageCodingData.openHABSitemapPage
                        }()
                    } catch {
                        os_log("Should not throw %{PUBLIC}@", log: OSLog.remoteAccess, type: .error, error.localizedDescription)
                    }
                }

                self.openHABSitemapPage?.sendCommand = { [weak self] item, command in
                    self?.sendCommand(item, commandToSend: command)
                }
                self.widgets = self.openHABSitemapPage?.widgets ?? []

                if refresh { self.loadPage(longPolling: true, refresh: true) }
            case let .failure(error):
                os_log("On LoadPage %{PUBLIC}@ code: %d ", log: .remoteAccess, type: .error, error.localizedDescription, response.response?.statusCode ?? 0)

                NetworkConnection.atmosphereTrackingId = ""
                if (error as NSError?)?.code == -1001, longPolling {
                    os_log("Timeout, restarting requests", log: OSLog.remoteAccess, type: .error)
                    self.loadPage(longPolling: false, refresh: true)
                } else if (error as NSError?)?.code == -999 {
                    os_log("Request was cancelled", log: OSLog.remoteAccess, type: .error)
                } else {
                    // Error
                    DispatchQueue.main.async {
                        if (error as NSError?)?.code == -1012 {
                            #warning("to be transferred to SwiftUI")
                        } else {
                            #warning("to be transferred to SwiftUI")
                        }
                    }
                }
            }
        }
        currentPageOperation?.resume()

        os_log("OpenHABViewController request sent", log: .remoteAccess, type: .error)
    }

    func sendCommand(_ item: OpenHABItem?, commandToSend command: String?) {
        if commandOperation != nil {
            commandOperation?.cancel()
            commandOperation = nil
        }
        if let item = item, let command = command {
            commandOperation = NetworkConnection.sendCommand(item: item, commandToSend: command)
            commandOperation?.resume()
        }
    }
}
