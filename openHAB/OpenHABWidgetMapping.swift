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

import Foundation
#if !os(watchOS)
import Fuzi
#endif

class OpenHABWidgetMapping: NSObject, Decodable {
    var command = ""
    var label = ""
}

extension OpenHABWidgetMapping {
    convenience init(command: String, label: String) {
        self.init()
        self.command = command
        self.label = label
    }

    #if !os(watchOS)
    convenience init(xml xmlElement: XMLElement) {
        self.init()
        for child in xmlElement.children {
            switch child.tag {
            case "command": command = child.stringValue
            case "label": label = child.stringValue
            default:
                break
            }
        }
    }
    #endif
}
