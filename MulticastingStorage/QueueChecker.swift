//
//  QueueChecker.swift
//  async_chain
//
//  Created by Hoon H. on 2015/08/12.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

import Foundation

///	Provides checking for queue equality against current caller queue.
///
final class QueueChecker {

	init(queue: dispatch_queue_t) {
		_queue	=	queue
		_idptr	=	UnsafeMutablePointer.alloc(1)
		dispatch_queue_set_specific(_queue, &_KEYMEM, _idptr, nil)
	}
	deinit {
		assert(check())
		dispatch_queue_set_specific(_queue, &_KEYMEM, nil, nil)
		_idptr.dealloc(1)
	}

	///	Can be called from any queue.
	var queue: dispatch_queue_t {
		get {
			return	_queue
		}
	}

	///	Checks current caller queue is an equal queue to a queue specified at initializer.
	///
	///	- returns:	`true` if current calling queue equals to queue that
	///			the queue designated at initialiser.
	func check() -> Bool {
		let	context		=	dispatch_get_specific(&_KEYMEM)
		let	equality	=	context == _idptr
		return	equality
	}

	///

	private let	_queue		:	dispatch_queue_t
	private var	_KEYMEM		=	UInt8(0)
	private let	_idptr		:	UnsafeMutablePointer<Void>	//<	A marker pointer. Content of this pointer shouldn't be dereferenced at all.

}