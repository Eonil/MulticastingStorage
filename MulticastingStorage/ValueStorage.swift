//
//  ValueStorage.swift
//  G6
//
//  Created by Hoon H. on 2015/07/30.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

import Foundation





/// Scalar value storage.
///
/// - You **cannot** register/deregister event handlers in the event handlers.
///   For example, you can deregister a handler on a did-set handler.
///
/// This is immutable storage interface, and you cannot
/// instantiate this class directly. Instead use `MutableValueStorage` class.
///
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
			assert(_queueChecker.check())
			return	_value
		}
	}

	///

	public typealias	Handler		=	()->()


	public func registerWillSet(@autoclosure identifier: ()->ObjectIdentifier, file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__, handler: Handler) {
		_executeWithChecks {
			_callSiteInfo.forWillSet[identifier()]	=	CallSiteInfo(file: file, line: line, function: function)
			_registerWillSetImpl(identifier(), handler: handler)
		}
	}
	public func registerDidSet(@autoclosure identifier: ()->ObjectIdentifier, file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__, handler: Handler) {
		_executeWithChecks {
			_callSiteInfo.forDidSet[identifier()]	=	CallSiteInfo(file: file, line: line, function: function)
			_registerDidSetImpl(identifier(), handler: handler)
		}
	}

	public func deregisterWillSet(identifier: ObjectIdentifier) {
		_executeWithChecks {
			_deregisterWillSetImpl(identifier)
			_callSiteInfo.forWillSet[identifier]	=	nil
		}
	}
	public func deregisterDidSet(identifier: ObjectIdentifier) {
		_executeWithChecks {
			_deregisterDidSetImpl(identifier)
			_callSiteInfo.forDidSet[identifier]	=	nil
		}
	}

	///

	private var	_handlers		=	(onWillSet: [ObjectIdentifier: Handler](), onDidSet: [ObjectIdentifier: Handler]())
	private var	_value			:	T

	///

	private func _registerWillSetImpl(identifier: ObjectIdentifier, handler: Handler) {
		assert(_handlers.onWillSet[identifier] == nil)
		_handlers.onWillSet[identifier]	=	handler
	}
	private func _deregisterWillSetImpl(identifier: ObjectIdentifier) {
		assert(_handlers.onWillSet[identifier] != nil)
		_handlers.onWillSet[identifier]	=	nil
	}

	private func _registerDidSetImpl(identifier: ObjectIdentifier, handler: Handler) {
		assert(_handlers.onDidSet[identifier] == nil)
		_handlers.onDidSet[identifier]	=	handler
	}
	private func _deregisterDidSetImpl(identifier: ObjectIdentifier) {
		assert(_handlers.onDidSet[identifier] != nil)
		_handlers.onDidSet[identifier]	=	nil
	}

	///

	private func _executeWithChecks(@noescape code: ()->()) {
		_precheck()
		code()
		_postcheck()
	}

	///	Debugging support structures. Must be stripped away in optimized build.
	///	Stripping is not yet implemented.
	///	Each value serves only one purpose.

	private let	_queueChecker		:	QueueChecker
	private var	_isCastingMutation	=	AtomicBool(false)
	private var	_callSiteInfo		=	(forWillSet: [ObjectIdentifier: CallSiteInfo](), forDidSet: [ObjectIdentifier: CallSiteInfo]())
	private var	_serialAccessChkFlag	=	AtomicBool(false)

	private func _precheck() {
		assert(_queueChecker.check())

		assert(_serialAccessChkFlag.state == false, "You cannot mutate this storage while a mutation event is still on casting.")
		_serialAccessChkFlag.state	=	true

		assert(_isCastingMutation.state == false, "You cannot mutate this storage while a mutation event is still on casting.")
		_isCastingMutation.state	=	true
	}
	private func _postcheck() {
		_isCastingMutation.state	=	false

		_serialAccessChkFlag.state	=	false
	}
}





public extension ValueStorage {
	/// Registers a delegate.
	///
	/// - Parameters:
	///
	/// 	- delegate:	A delegate to be registered.
	///			This will be referenced weakly. You're responsible to
	///			make it alive until to `deregister` it.
	///
	public func register(delegate: ValueStorageDelegate) {
		registerWillSet(ObjectIdentifier(delegate)) { [weak delegate] in assert(delegate != nil); delegate!.willSet() }
		registerDidSet(ObjectIdentifier(delegate)) { [weak delegate] in assert(delegate != nil); delegate!.didSet() }
	}

	/// Deregisteres a delegate.
	///
	/// - Parameters:
	///
	///	- delegate:	A delegate to be deregistered.
	///
	public func deregister(delegate: ValueStorageDelegate) {
		deregisterWillSet(ObjectIdentifier(delegate))
		deregisterDidSet(ObjectIdentifier(delegate))
	}
}





/// Scalar value storage.
///
/// Follows all the attributes of `ValueStorage`. Also,
///
/// - You **cannot** change `value` while its mutation events are firing.
///
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
			_executeWithChecks {
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














