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

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: UserData

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(viewModel.sitemap) { item in
                SwitchRow(item: item)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()

        return Group {
            ContentView()
                .environmentObject(userData)
                .previewDevice("Apple Watch Series 4 - 44mm")

            ContentView()
                .environmentObject(userData)
                .previewDevice("Apple Watch Series 2 - 38mm")
        }
    }
}
