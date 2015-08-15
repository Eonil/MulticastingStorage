//
//  ValueStorage.swift
//  G6
//
//  Created by Hoon H. on 2015/07/30.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

import Foundation

///	Scalar value storage.
public class ValueStorage<T>: ValueStorageType {

	private init(_ initialValue: T, queue: dispatch_queue_t) {
		_queueChecker	=	QueueChecker(queue: queue)
		_value		=	initialValue
	}
	deinit {
		assert(_delegates.count == 0, "You must `deregister` all delegates from this storage before this storage object dies.")
	}

	///

	public var value: T {
		get {
			return	_value
		}
	}

	///

	public func register(delegate: ValueStorageDelegate) {
		_executeWithThreadAndCastingCheck {
			_delegates.insert(_ValueStorageDelegateWeakBox(delegate: delegate))
		}
	}
	public func deregister(delegate: ValueStorageDelegate) {
		_executeWithThreadAndCastingCheck {
			_delegates.remove(_ValueStorageDelegateWeakBox(delegate: delegate))
		}
	}

	///

	private let	_queueChecker	:	QueueChecker
	private var	_isCasting	=	false

	private var	_delegates	=	OrderingSet<_ValueStorageDelegateWeakBox>()
	private var	_value		:	T

	private func _executeWithThreadAndCastingCheck(@noescape run: ()->()) {
		assert(_queueChecker.check())
		assert(_isCasting == false, "You cannot mutate this storage while a mutation event is on casting.")
		_isCasting	=	true
		run()
		_isCasting	=	false
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
				_delegates.map { $0.getOrCrash().willSet() }
				_value	=	newValue
				_delegates.map { $0.getOrCrash().didSet() }
			}
		}
	}

}
















private struct _ValueStorageDelegateWeakBox: Hashable {
	weak var delegate: ValueStorageDelegate?
	var hashValue: Int {
		get {
			return	ObjectIdentifier(delegate!).hashValue
		}
	}
	func getOrCrash() -> ValueStorageDelegate {
		if let delegate = delegate {
			return	delegate
		}
		else {
			fatalError("The delegate has already been gone away...")
		}
	}
}
private func == (a: _ValueStorageDelegateWeakBox, b: _ValueStorageDelegateWeakBox) -> Bool {
	let	a1	=	a.getOrCrash()
	let	b1	=	b.getOrCrash()
	return	a1 === b1
}

