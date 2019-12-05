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

struct Pattern<Value> {
    let closure: (Value) -> Bool
}

extension Pattern where Value: Hashable {
    static func any(of candidates: Set<Value>) -> Pattern {
        Pattern { candidates.contains($0) }
    }
}

func ~= <T>(lhs: Pattern<T>, rhs: T) -> Bool {
    lhs.closure(rhs)
}

extension Pattern where Value: Comparable {
    static func lessThan(_ value: Value) -> Pattern {
        Pattern { $0 < value }
    }

    static func greaterThan(_ value: Value) -> Pattern {
        Pattern { $0 > value }
    }
}

func ~= <T>(lhs: KeyPath<T, Bool>, rhs: T?) -> Bool {
    rhs?[keyPath: lhs] ?? false
}

func == <T, V: Equatable>(lhs: KeyPath<T, V>, rhs: V) -> Pattern<T> {
    return Pattern { $0[keyPath: lhs] == rhs }
}

func > <T, V: Comparable>(lhs: KeyPath<T, V>, rhs: V) -> Pattern<T> {
    return Pattern { $0[keyPath: lhs] > rhs }
}

// func combine <T,V> (pt: Pattern<T>, pv: Pattern<V>) -> Pattern {
//    return pt.closure
// }

extension Collection {
    public var isNotEmpty: Bool {

        return !isEmpty
    }
}

extension Optional where Wrapped: Collection {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
    var isNeitherNilNorEmpty: Bool {
        return !isNilOrEmpty
    }
}
