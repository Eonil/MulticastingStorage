//
//  ArrayStorage.swift
//  G6
//
//  Created by Hoon H. on 2015/07/30.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

import Foundation

/// Value vector storage.
///
/// -	parameter T:
/// 	Vector element value type.
///
public class ArrayStorage<T>: ArrayStorageType {

	private init(_ initialArray: [T], queue: dispatch_queue_t = dispatch_get_main_queue()) {
		_queueCheck	=	QueueChecker(queue: queue)
		_array		=	initialArray
	}
	deinit {
		assert(_queueCheck.check())
		assert(_delegates.count == 0, "You must `deregister` all delegates from this storage before this storage object dies.")
	}

	///

	public var array: [T] {
		get {
			assert(_queueCheck.check())
			return	_array
		}
	}

	/// You're responsible to keep the `delegate` alive while
	/// that is registered to this object.
	public func register(@autoclosure delegate: ()->ArrayStorageDelegate, file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
		assert(_queueCheck.check())
		_executeWithChecks {
			_delegates.insert(_ArrayStorageDelegateWeakBox(delegate: delegate()))

			assert(_callSiteInfoMap[ObjectIdentifier(delegate())] == nil)
			_callSiteInfoMap[ObjectIdentifier(delegate())]	=	_CallSiteInfo(file: file, line: line, function: function)
		}
	}
	public func deregister(delegate: ArrayStorageDelegate) {
		assert(_queueCheck.check())
		_executeWithChecks {
			_delegates.remove(_ArrayStorageDelegateWeakBox(delegate: delegate))

			assert(_callSiteInfoMap[ObjectIdentifier(delegate)] != nil)
			_callSiteInfoMap[ObjectIdentifier(delegate)]	=	nil
		}
	}

	///

	private var	_array		:	[T]
	private var	_delegates	=	OrderingSet<_ArrayStorageDelegateWeakBox>()

	///

	private func _executeWithChecks(@noescape run: ()->()) {
		_precheck()
		run()
		_postcheck()
	}

	///	Debuggig supports.

	private let	_queueCheck		:	QueueChecker
	private var	_isCasting		=	false
	private var	_callSiteInfoMap	=	[ObjectIdentifier:_CallSiteInfo]()
	private var	_serialAccessCheckFlag	=	AtomicBool(false)

	private func _precheck() {
		assert(_queueCheck.check(), "You can access this object only from specified queue. And the queue must be a serial queue.")

		assert(_serialAccessCheckFlag.state == false, "You are accessing this storage from multiple threads simultaneously. That is prohibited.")
		_serialAccessCheckFlag.state	=	true

		assert(_isCasting == false, "You cannot mutate this storage while a mutation event is on casting.")
		_isCasting			=	true
	}
	private func _postcheck() {
		_isCasting			=	false

		_serialAccessCheckFlag.state	=	false
	}
}

private struct _CallSiteInfo {
	var file	:	String
	var line	:	Int
	var function	:	String
}



public class MutableArrayStorage<T>: ArrayStorage<T>, MutableArrayStorageType {

	/// Instantiates with default queue that is the main serial queue.
	public convenience init(_ initialArray: [T]) {
		self.init(initialArray, queue: dispatch_get_main_queue())
	}

	/// Instantiates a mutable array storage.
	///
	/// -	parameter queue:
	///
	///	Defines a queue that is allowed to perform I/O on this storage.
	///	This queue must be a serial queue or you must guarantee serial
	///	execution.
	///
	///	Even "reading" requires exclusive access to storage because
	///	underlying store `Swift.Array` does not provide any explicit
	///	guarantee of mutation-free-ness for internal memory on reading.
	///	This restriction can be relaxed later if the guarantee to be
	///	provided.
	///
	///	This object will debug-assert current execution queue to prevent
	///	programmer error.
	///
	public override init(_ initialArray: [T], queue: dispatch_queue_t) {
		super.init(initialArray, queue: queue)
	}

	///

	public func insert<C : CollectionType where C.Generator.Element == T, C.Index.Distance == Int>(newElements: C, atIndex index: Int) {
		assert(index <= _array.count)
		_executeWithChecks {
			let	range	=	index..<(index + newElements.count)
			_delegates.map { $0.getOrCrash().willInsertRange(range) }
			_array.insertContentsOf(newElements, at: index)
			_delegates.map { $0.getOrCrash().didInsertRange(range) }
		}
	}
	public func update<C : CollectionType where C.Generator.Element == T, C.Index.Distance == Int>(range: Range<Int>, with newElements: C) {
		assert(range.startIndex.distanceTo(range.endIndex) == newElements.count, "Number of `newElements` must be equal with number of elements in replacing range.")
		_executeWithChecks {
			_delegates.map { $0.getOrCrash().willUpdateRange(range) }
			_array.replaceRange(range, with: newElements)
			_delegates.map { $0.getOrCrash().didUpdateRange(range) }
		}
	}
	public func delete(range: Range<Int>) {
		assert(range.startIndex >= _array.startIndex)
		assert(range.endIndex <= _array.endIndex)
		_executeWithChecks {
			_delegates.map { $0.getOrCrash().willDeleteRange(range) }
			_array.removeRange(range)
			_delegates.map { $0.getOrCrash().didDeleteRange(range) }
		}
	}

}










private struct _ArrayStorageDelegateWeakBox: Hashable {
	weak var delegate: ArrayStorageDelegate?
	var hashValue: Int {
		get {
			return	ObjectIdentifier(delegate!).hashValue
		}
	}
	func getOrCrash() -> ArrayStorageDelegate {
		if let delegate = delegate {
			return	delegate
		}
		else {
			fatalError("The delegate has already been gone away...")
		}
	}
}
private func == (a: _ArrayStorageDelegateWeakBox, b: _ArrayStorageDelegateWeakBox) -> Bool {
	let	a1	=	a.getOrCrash()
	let	b1	=	b.getOrCrash()
	return	a1 === b1
}




