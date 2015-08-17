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
/// Calling order between handlers is undefined. Do not depend on it.
/// This is intentional design to simplify everything.
/// Because the order is undefined, these behaviors are prohibited.
///
/// -	You **cannot** register/deregister a handler while mutation events are
///	being cast. Because it's impossible to define whether the newrly added
///	or removed handler should be called or not in the casting session.
///	The only exception is deregistering a handler that is being called. 
///	Because we know that the handler is already been called, so it can safely
///	be removed.
///
///	This can be relaxed later if we can define a reasonable rule on those 
///	things.
///
/// This is immutable storage interface, and you cannot
/// instantiate this class directly. Instead, use `MutableValueStorage` class.
///
public class ValueStorage<T>: ValueStorageType {

	private init(_ initialValue: T, queue: dispatch_queue_t) {
		_queueChecker	=	QueueChecker(queue: queue)
		_value		=	initialValue
	}
	deinit {
		assert(_handlerQueues.forRegistering.forWillSet.count == 0)
		assert(_handlerQueues.forRegistering.forDidSet.count == 0)
		assert(_handlerQueues.forDeregistering.forWillSet.count == 0)
		assert(_handlerQueues.forDeregistering.forDidSet.count == 0)
		assert(_handlers.forWillSet.count == 0, "You must `deregister` all delegates from this storage before this storage object dies.")
		assert(_handlers.forDidSet.count == 0, "You must `deregister` all delegates from this storage before this storage object dies.")
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
		_executeWithAllChecks {
			_registrationCallSites.forWillSet[identifier()]	=	CallSiteInfo(file: file, line: line, function: function)
			_registerWillSetImpl(identifier(), handler: handler)
		}
	}
	public func registerDidSet(@autoclosure identifier: ()->ObjectIdentifier, file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__, handler: Handler) {
		_executeWithAllChecks {
			_registrationCallSites.forDidSet[identifier()]	=	CallSiteInfo(file: file, line: line, function: function)
			_registerDidSetImpl(identifier(), handler: handler)
		}
	}

	public func deregisterWillSet(identifier: ObjectIdentifier) {
		_executeWithAllChecks {
			_deregisterWillSetImpl(identifier)
			_registrationCallSites.forWillSet[identifier]	=	nil
		}
	}
	public func deregisterDidSet(identifier: ObjectIdentifier) {
		_executeWithAllChecks {
			_deregisterDidSetImpl(identifier)
			_registrationCallSites.forDidSet[identifier]	=	nil
		}
	}

	/// Queues registering of a will-set handler.
	///
	/// You can use this method to register a handler in a handler.
	/// The handler will be registered after all handlers are executed.
	///
	/// This method can be called only in a handler.
	/// You cannot queue handlers for duplicated identifiers.
	///
	public func queueRegisteringWillSetWhileCastingHandlers(identifier: ObjectIdentifier, handler: Handler) {
		//	Serial-access check shouldn't be performed because it should already be done in caller...
		_executeWithQueueCheck {
			assert(_isCastingMutation.state == true)
			assert(_handlerQueues.forRegistering.forWillSet[identifier] == nil)
			_handlerQueues.forRegistering.forWillSet[identifier]	=	handler
		}
	}
	/// Queues deregistering of a will-set handler.
	///
	/// You can use this method to deregister a handler in a handler.
	/// The handler will be deregistered after all handlers are executed.
	///
	/// This method can be called only in a handler.
	/// You cannot queue handlers for duplicated identifiers.
	///
	public func queueDeregisteringWillSetWhileCastingHandlers(identifier: ObjectIdentifier) {
		//	Serial-access check shouldn't be performed because it should already be done in caller...
		_executeWithQueueCheck {
			assert(_isCastingMutation.state == true)
			assert(_handlerQueues.forDeregistering.forWillSet.contains(identifier) == false)
			_handlerQueues.forDeregistering.forWillSet.insert(identifier)
		}
	}

	/// Queues registering of a did-set handler.
	///
	/// You can use this method to register a handler in a handler.
	/// The handler will be registered after all handlers are executed.
	///
	/// This method can be called only in a handler.
	/// You cannot queue handlers for duplicated identifiers.
	///
	public func queueRegisteringDidSetWhileCastingHandlers(identifier: ObjectIdentifier, handler: Handler) {
		//	Serial-access check shouldn't be performed because it should already be done in caller...
		_executeWithQueueCheck {
			assert(_isCastingMutation.state == true)
			assert(_handlerQueues.forRegistering.forDidSet[identifier] == nil)
			_handlerQueues.forRegistering.forDidSet[identifier]		=	handler
		}
	}
	/// Queues deregistering of a did-set handler.
	///
	/// You can use this method to deregister a handler in a handler.
	/// The handler will be deregistered after all handlers are executed.
	///
	/// This method can be called only in a handler.
	/// You cannot queue handlers for duplicated identifiers.
	///
	public func queueDeregisteringDidSetWhileCastingHandlers(identifier: ObjectIdentifier) {
		//	Serial-access check shouldn't be performed because it should already be done in caller...
		_executeWithQueueCheck {
			assert(_isCastingMutation.state == true)
			assert(_handlerQueues.forDeregistering.forDidSet.contains(identifier) == false)
			_handlerQueues.forDeregistering.forDidSet.insert(identifier)
		}
	}

	///

	private var	_handlers		=	(forWillSet: [ObjectIdentifier: Handler](), forDidSet: [ObjectIdentifier: Handler]())
	private var	_handlerQueues		=	(forRegistering: (forWillSet: [ObjectIdentifier: Handler](), forDidSet: [ObjectIdentifier: Handler]()), forDeregistering: (forWillSet: Set<ObjectIdentifier>(), forDidSet: Set<ObjectIdentifier>()))
	private var	_value			:	T

	///

	private func _registerWillSetImpl(identifier: ObjectIdentifier, handler: Handler) {
		assert(_handlers.forWillSet[identifier] == nil)
		_handlers.forWillSet[identifier]		=	handler
	}
	private func _registerDidSetImpl(identifier: ObjectIdentifier, handler: Handler) {
		assert(_handlers.forDidSet[identifier] == nil)
		_handlers.forDidSet[identifier]			=	handler
	}
	private func _deregisterWillSetImpl(identifier: ObjectIdentifier) {
		assert(_handlers.forWillSet[identifier] != nil)
		_handlers.forWillSet[identifier]		=	nil
	}
	private func _deregisterDidSetImpl(identifier: ObjectIdentifier) {
		assert(_handlers.forDidSet[identifier] != nil)
		_handlers.forDidSet[identifier]			=	nil
	}

	///	Safety check support structures.
	///	Each value serves only one purpose.

	private let	_queueChecker		:	QueueChecker
	private var	_serialAccessChkFlag	=	AtomicBool(false)
	private var	_isCastingMutation	=	AtomicBool(false)
	private var	_registrationCallSites	=	(forWillSet: [ObjectIdentifier: CallSiteInfo](), forDidSet: [ObjectIdentifier: CallSiteInfo]())

	private func _executeWithAllChecks(@noescape code: ()->()) {
		_executeWithQueueCheck {
			_executeWithThreadCheck {
				_executeWithCastingCheck {
					code()
				}
			}
		}
	}
	private func _executeWithQueueCheck(@noescape code: ()->()) {
		assert(_queueChecker.check())
		code()
	}
	private func _executeWithThreadCheck(@noescape code: ()->()) {
		assert(_serialAccessChkFlag.state == false, "You should not access this storage concurrently.")
		_serialAccessChkFlag.state	=	true
		code()
		_serialAccessChkFlag.state	=	false
	}
	private func _executeWithCastingCheck(@noescape code: ()->()) {
		assert(_isCastingMutation.state	 == false, "You cannot mutate value of or /register/deregister " +
			"handlers to this storage while a mutation event is still on casting. However, you can " +
			"use `queueRegistering/Deregistering~` methods to queue immediate registering or deregistering " +
			"handlers at casting finish.")
		_isCastingMutation.state		=	true
		code()
		_isCastingMutation.state		=	false
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
/// -	You **cannot** change `value` while its mutation events are firing.
///	Because the "current state" becomes vague if it is allowed.
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
			_executeWithAllChecks {
				//	`Dictionary.values.map` has a bug that does not iterate any value.
				//	Do not use it.

				for handler in _handlers.forWillSet.values {
					handler()
				}

				_value	=	newValue

				for handler in _handlers.forDidSet.values {
					handler()
				}

				///

				for (id, handler) in _handlerQueues.forRegistering.forWillSet {
					_registerWillSetImpl(id, handler: handler)
				}
				_handlerQueues.forRegistering.forWillSet.removeAll()
				for (id) in _handlerQueues.forDeregistering.forWillSet {
					_deregisterWillSetImpl(id)
				}
				_handlerQueues.forRegistering.forDidSet.removeAll()
				for (id, handler) in _handlerQueues.forRegistering.forDidSet {
					_registerDidSetImpl(id, handler: handler)
				}
				_handlerQueues.forDeregistering.forWillSet.removeAll()
				for (id) in _handlerQueues.forDeregistering.forDidSet {
					_deregisterDidSetImpl(id)
				}
				_handlerQueues.forDeregistering.forDidSet.removeAll()
			}
		}
	}
}














