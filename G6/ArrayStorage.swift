//
//  ArrayStorage.swift
//  G6
//
//  Created by Hoon H. on 2015/07/30.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

import Foundation

///	Value vector storage.
///
///	:param:		T
///			Vector element value type.
///
public class ArrayStorage<T>: ArrayStorageType {

	///	:param:		queue
	///
	///			Defines a queue that is allowed to perform I/O on this storage.
	///			This queue must be a serial queue or you must guarantee serial
	///			execution. Because "barriers" cannot be used on some global queues,
	///			it is regarded as dangerous, and will not be allowed.
	///
	///			Even "reading" requires exclusive access to storage because
	///			underlying store `Swift.Array` does not provide any explicit
	///			guarantee of mutation-free-ness for internal memory on reading.
	///			This restriction can be relaxed later if the guarantee to be
	///			provided.
	///
	///			This object will debug-assert current execution queue to prevent
	///			programmer error.
	///
	///			Default value is the main serial queue.
	///
	///
	///
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

	///	You're responsible to keep the `delegate` alive while
	///	that is registered to this object.
	public func register(@autoclosure delegate: ()->ArrayStorageDelegate, file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
		assert(_queueCheck.check())
		_executeWithChecks {
			_delegates.insert(delegate())

			assert(_callSiteInfoMap[ObjectIdentifier(delegate())] == nil)
			_callSiteInfoMap[ObjectIdentifier(delegate())]	=	_CallSiteInfo(file: file, line: line, function: function)
		}
	}
	public func deregister(delegate: ArrayStorageDelegate) {
		assert(_queueCheck.check())
		_executeWithChecks {
			_delegates.remove(delegate)

			assert(_callSiteInfoMap[ObjectIdentifier(delegate)] != nil)
			_callSiteInfoMap[ObjectIdentifier(delegate)]	=	nil
		}
	}

	///

	private var	_array		:	[T]
	private let	_delegates	=	WeakObjectSet<ArrayStorageDelegate>()

	///

	private func _executeWithChecks(@noescape run: ()->()) {
		assert(_queueCheck.check(), "You can access this object only from specified queue. And the queue must be a serial queue.")
		assert(_serialAccessCheckFlag.state == false, "You are accessing this storage from multiple threads simultaneously. That is prohibited.")
		_serialAccessCheckFlag.state	=	true
		assert(_isCasting == false, "You cannot mutate this storage while a mutation event is on casting.")
		_isCasting	=	true
		run()
		_isCasting	=	false
		_serialAccessCheckFlag.state	=	false
	}

	///	Debuggig supports.

	private let	_queueCheck		:	QueueChecker
	private var	_isCasting		=	false
	private var	_callSiteInfoMap	=	[ObjectIdentifier:_CallSiteInfo]()
	private var	_serialAccessCheckFlag	=	AtomicBool(false)
}

private struct _CallSiteInfo {
	var file	:	String
	var line	:	Int
	var function	:	String
}



public class MutableArrayStorage<T>: ArrayStorage<T>, MutableArrayStorageType {

	public init(_ initialArray: [T]) {
		super.init(initialArray)
	}

	///

	public func insert<C : CollectionType where C.Generator.Element == T, C.Index.Distance == Int>(newElements: C, atIndex index: Int) {
		assert(index < _array.count)
		_executeWithChecks {
			let	range	=	index..<(index + count(newElements))
			_delegates.map { $0.willInsertRange(range) }
			_array.splice(newElements, atIndex: index)
			_delegates.map { $0.didInsertRange(range) }
		}
	}
	public func update<C : CollectionType where C.Generator.Element == T, C.Index.Distance == Int>(range: Range<Int>, with newElements: C) {
		assert(distance(range.startIndex, range.endIndex) == count(newElements), "Number of `newElements` must be equal with number of elements in replacing range.")
		_executeWithChecks {
			_delegates.map { $0.willUpdateRange(range) }
			_array.replaceRange(range, with: newElements)
			_delegates.map { $0.didUpdateRange(range) }
		}
	}
	public func delete(range: Range<Int>) {
		assert(range.startIndex >= _array.startIndex)
		assert(range.endIndex <= _array.endIndex)
		_executeWithChecks {
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


















class ThreadSafeMutableArrayStorage<T>: MutableArrayStorage<T> {
	override func insert<C : CollectionType where C.Generator.Element == T, C.Index.Distance == Int>(newElements: C, atIndex index: Int) {

	}
	override func update<C : CollectionType where C.Generator.Element == T, C.Index.Distance == Int>(range: Range<Int>, with newElements: C) {

	}
	override func delete(range: Range<Int>) {

	}
}


//
//
/////	An `ArrayStorage` that replicates data from an `ArrayStorage` that
/////	is running in an another thread asynchrnously.
/////
/////	You must call `process` to run queued mutation messages in a specific
/////	thread. Because there's no good way to inject code into a specific
/////	thread in FIFO order. You MUST call this method on the thread that
/////	created this object. This object does not use extra synchronization
/////	devices, so it's your responsibility to provide thread safety.
/////
/////	This object must run in single thread, and should not be accessed from
/////	multiple threads. That means this object doesn't play well with GCD.
/////	You need to make a new thread if you want to use this object in non-main
/////	thread.
/////
/////
//public class ReplicatingArrayStorage<T>: ArrayStorage<T> {
//	///	Processes queued mutations.
//	public func process() {
//
//	}
//}
//private final class _Replicator<T>: ArrayStorageDelegate {
//	init(_ queue: dispatch_queue_t) {
//		self.targetQueue	=	queue
//	}
//
//	weak var	sourceStorage	:	ArrayStorage<T>?
//	let		targetQueue	:	dispatch_queue_t
//
//	var		srcThreadMCQ	=	Array<()->()>()
//	var		dstThreadMCQ	=	Array<()->()>()
//
//	///
//
//	private func willInsertRange(range: Range<Int>) {
//		let	newElements	=	sourceStorage!.array[range]
//		dispatch_async(targetQueue) { [weak self] in
//
//		}
//		dispatch_async(targetQueue) { [weak self] in
//			self!.targetStorage!._array.insert(self!.sourceStorage!.array[range], atIndex: range.startIndex)
//			return
//		}
//	}
//	private func didInsertRange(range: Range<Int>) {
//	}
//	private func willUpdateRange(range: Range<Int>) {
//	}
//	private func didUpdateRange(range: Range<Int>) {
//	}
//	private func willDeleteRange(range: Range<Int>) {
//	}
//	private func didDeleteRange(range: Range<Int>) {
//	}
//}
//











