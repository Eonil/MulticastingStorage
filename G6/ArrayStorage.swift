//
//  ArrayStorage.swift
//  G6
//
//  Created by Hoon H. on 2015/07/30.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

public class ArrayStorage<T>: ArrayStorageType {

	private init(_ initialArray: [T]) {
		_array	=	initialArray
	}
	deinit {
		assert(_delegates.count == 0, "You must `deregister` all delegates from this storage before this storage object dies.")
	}

	///

	public var array: [T] {
		get {
			return	_array
		}
	}

	///	You're responsible to keep the `delegate` alive while
	///	that is registered to this object.
	public func register(delegate: ArrayStorageDelegate) {
		_executeWithThreadAndCastingCheck {
			_delegates.insert(delegate)
		}
	}
	public func deregister(delegate: ArrayStorageDelegate) {
		_executeWithThreadAndCastingCheck {
			_delegates.remove(delegate)
		}
	}

	///

	private let	_threadChecker	=	ThreadChecker()
	private var	_isCasting	=	false

	private let	_delegates	=	WeakObjectSet<ArrayStorageDelegate>()
	private var	_array		:	[T]

	private func _executeWithThreadAndCastingCheck(@noescape run: ()->()) {
		_threadChecker.assert()
		assert(_isCasting == false, "You cannot mutate this storage while a mutation event is on casting.")
		_isCasting	=	true
		run()
		_isCasting	=	false
	}
}



public class MutableArrayStorage<T>: ArrayStorage<T>, MutableArrayStorageType {

	public override init(_ initialArray: [T]) {
		super.init(initialArray)
	}

	///

	public func insert<C : CollectionType where C.Generator.Element == T, C.Index.Distance == Int>(newElements: C, atIndex index: Int) {
		assert(index < _array.count)
		_executeWithThreadAndCastingCheck {
			let	range	=	index..<(index + count(newElements))
			_delegates.map { $0.willInsertRange(range) }
			_array.splice(newElements, atIndex: index)
			_delegates.map { $0.didInsertRange(range) }
		}
	}
	public func update<C : CollectionType where C.Generator.Element == T, C.Index.Distance == Int>(range: Range<Int>, with newElements: C) {
		assert(distance(range.startIndex, range.endIndex) == count(newElements), "Number of `newElements` must be equal with number of elements in replacing range.")
		_executeWithThreadAndCastingCheck {
			_delegates.map { $0.willUpdateRange(range) }
			_array.replaceRange(range, with: newElements)
			_delegates.map { $0.didUpdateRange(range) }
		}
	}
	public func delete(range: Range<Int>) {
		assert(range.startIndex >= _array.startIndex)
		assert(range.endIndex <= _array.endIndex)
		_executeWithThreadAndCastingCheck {
			_delegates.map { $0.willDeleteRange(range) }
			_array.removeRange(range)
			_delegates.map { $0.didDeleteRange(range) }
		}
	}

}
//public extension MutableArrayStorage {
//	public func insert<C : CollectionType where C.Generator.Element == T>(newElements: C, atIndex index: Int) {
//		insert(index..<count(newElements), newElements)
//	}
//}


