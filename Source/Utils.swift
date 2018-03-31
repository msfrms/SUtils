//
// Created by Radaev Mikhail on 19.09.17.
// Copyright (c) 2017 ListOK. All rights reserved.
//

import Foundation

public extension Optional {

    public var nonEmpty: Bool {
        switch self {
        case .none: return false
        case .some: return true
        }
    }

    public func getOrElse(_ defaultValue: Wrapped) -> Wrapped {
        switch self {
        case .some(let value): return value
        case .none: return defaultValue
        }
    }

    public func foreach(_ f: (Wrapped) -> ()) {
        switch self {
        case .some(let value): f(value)
        case .none: ()
        }
    }
}

public extension Dictionary {

    public func map<T: Hashable, U>( transform: (Key, Value) -> (T, U)) -> [T: U] {
        var result: [T: U] = [:]
        for (key, value) in self {
            let (transformedKey, transformedValue) = transform(key, value)
            result[transformedKey] = transformedValue
        }
        return result
    }
}

public final class CommandWith<T> {

    public typealias Callback = (T) -> ()
    
    private let callback: Callback
    private let id: String
    private let file: StaticString
    private let function: StaticString
    private let line: Int

    public init(id: String = "unnamed",
         file: StaticString = #file,
         function: StaticString = #function,
         line: Int = #line,
         callback: @escaping Callback) {
        self.id = id
        self.file = file
        self.function = function
        self.line = line
        self.callback = callback
    }

    public func execute(value: T) { self.callback(value) }
}

public extension CommandWith where T == Void {

    public static var nop = Command { }

    public func execute() { self.execute(value: ()) }
}

public typealias Command = CommandWith<Void>

public extension CommandWith {

    public func debounce(delay: DispatchTimeInterval, queue: DispatchQueue) -> CommandWith<T> {
        var currentWorkItem: DispatchWorkItem?
        return  CommandWith<T>(id: self.id) { value in
            currentWorkItem?.cancel()
            currentWorkItem = DispatchWorkItem { self.execute(value: value) }
            queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
        }
    }

    public func delay(_ delay: DispatchTimeInterval, queue: DispatchQueue = .main) -> CommandWith<T> {
        return  CommandWith<T>(id: self.id) { value in
            queue.asyncAfter(deadline: .now() + delay) { self.execute(value: value) }
        }
    }

    public func observe(queue: DispatchQueue) -> CommandWith<T> {
        return CommandWith<T>(id: self.id) { value in queue.async { self.execute(value: value) } }
    }
}





