//
//  ValueStorage.swift
//  G6
//
//  Created by Hoon H. on 2015/07/30.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

import Foundation

//public enum ValueSignal {
//	case WillSet
//	case DidSet
//
//	func handleWillSet(@noescape handler: ()->()) {
//
//	}
//	func handleDidSet(@noescape handler: ()->()) {
//
//	}
//}

///	Scalar value storage.
public class ValueStorage<T>: ValueStorageType {

	private init(_ initialValue: T, queue: dispatch_queue_t) {
		_queueChecker	=	QueueChecker(queue: queue)
		_value		=	initialValue
	}
	deinit {
		assert(_handlers.onWillSet.count == 0, "You must `deregister` all delegates from this storage before this storage object dies.")
		assert(_handlers.onDidSet.count == 0, "You must `deregister` all delegates from this storage before this storage object dies.")
	}

	///

	public var value: T {
		get {
			return	_value
		}
	}

	///

	public typealias	Handler		=	()->()

	public func registerWillSet(identifier: ObjectIdentifier, handler: Handler) {
		_executeWithThreadAndCastingCheck {
			assert(_handlers.onWillSet[identifier] == nil)
			_handlers.onWillSet[identifier]	=	handler
		}
	}
	public func registerDidSet(identifier: ObjectIdentifier, handler: Handler) {
		_executeWithThreadAndCastingCheck {
			assert(_handlers.onDidSet[identifier] == nil)
			_handlers.onDidSet[identifier]	=	handler
		}
	}
	public func deregisterWillSet(identifier: ObjectIdentifier) {
		_executeWithThreadAndCastingCheck {
			assert(_handlers.onWillSet[identifier] != nil)
			_handlers.onWillSet[identifier]	=	nil
		}
	}
	public func deregisterDidSet(identifier: ObjectIdentifier) {
		_executeWithThreadAndCastingCheck {
			assert(_handlers.onDidSet[identifier] != nil)
			_handlers.onDidSet[identifier]	=	nil
		}
	}

	///

	private let	_queueChecker	:	QueueChecker
	private var	_isCasting	=	false

	private var	_handlers	=	(onWillSet: [ObjectIdentifier: Handler](), onDidSet: [ObjectIdentifier: Handler]())
	private var	_value		:	T

	private func _executeWithThreadAndCastingCheck(@noescape run: ()->()) {
		assert(_queueChecker.check())
		assert(_isCasting == false, "You cannot mutate this storage while a mutation event is on casting.")
		_isCasting	=	true
		run()
		_isCasting	=	false
	}
}
public extension ValueStorage {
	public func register(delegate: ValueStorageDelegate) {
		registerWillSet(ObjectIdentifier(delegate)) { [weak delegate] in assert(delegate != nil); delegate!.willSet() }
		registerDidSet(ObjectIdentifier(delegate)) { [weak delegate] in assert(delegate != nil); delegate!.didSet() }
	}
	public func deregister(delegate: ValueStorageDelegate) {
		deregisterWillSet(ObjectIdentifier(delegate))
		deregisterDidSet(ObjectIdentifier(delegate))
	}
}


public class MutableValueStorage<T>: ValueStorage<T>, MutableValueStorageType {

	/// Instantiates with default queue that is the main serial queue.
	public convenience init(_ initialValue: T) {
		self.init(initialValue, queue: dispatch_get_main_queue())
	}

	/// Instantiates a mutable value storage.
	///
	/// -	parameter queue:
	///
	///	Defines a queue that is allowed to perform I/O on this storage.
	///	This queue must be a serial queue or you must guarantee serial
	///	execution.
	///
	///	This object will debug-assert current execution queue to prevent
	///	programmer error.
	///
	public override init(_ initialValue: T, queue: dispatch_queue_t) {
		super.init(initialValue, queue: queue)
	}
	public override var value: T {
		get {
			return	_value
		}
		set {
			_executeWithThreadAndCastingCheck {

				//	`Dictionary.values.map` has a bug that does not iterate any value.
				//	Do not use it.

				for handler in _handlers.onWillSet.values {
					handler()
				}
				_value	=	newValue
				for handler in _handlers.onDidSet.values {
					handler()
				}
			}
		}
	}

}














