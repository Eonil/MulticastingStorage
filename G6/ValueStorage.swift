//
//  ValueStorage.swift
//  G6
//
//  Created by Hoon H. on 2015/07/30.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

///	Scalar value storage.
public class ValueStorage<T>: ValueStorageType {

	private init(_ initialValue: T) {
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
			_delegates.insert(delegate)
		}
	}
	public func deregister(delegate: ValueStorageDelegate) {
		_executeWithThreadAndCastingCheck {
			_delegates.remove(delegate)
		}
	}

	///

	private let	_threadChecker	=	ThreadChecker()
	private var	_isCasting	=	false

	private let	_delegates	=	WeakObjectSet<ValueStorageDelegate>()
	private var	_value		:	T

	private func _executeWithThreadAndCastingCheck(@noescape run: ()->()) {
		_threadChecker.assert()
		assert(_isCasting == false, "You cannot mutate this storage while a mutation event is on casting.")
		_isCasting	=	true
		run()
		_isCasting	=	false
	}
}



public class MutableValueStorage<T>: ValueStorage<T>, MutableValueStorageType {

	public override init(_ initialValue: T) {
		super.init(initialValue)
	}
	public override var value: T {
		get {
			return	_value
		}
		set {
			_executeWithThreadAndCastingCheck {
				_delegates.map({ $0.willSet() })
				_value	=	newValue
				_delegates.map({ $0.didSet() })
			}
		}
	}

}





