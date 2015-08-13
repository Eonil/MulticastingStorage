//
//  QueueChecker.swift
//  async_chain
//
//  Created by Hoon H. on 2015/08/12.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

import Foundation

///	Provides checking for queue equality against current queue.
///
final class QueueChecker {

	init(queue: dispatch_queue_t) {
		_queue	=	queue
		_idptr	=	UnsafeMutablePointer.alloc(1)
		dispatch_queue_set_specific(_queue, &_KEYMEM, _idptr, nil)
	}
	deinit {
		dispatch_queue_set_specific(_queue, &_KEYMEM, nil, nil)
		_idptr.dealloc(1)
	}

	var queue: dispatch_queue_t {
		get {
			return	_queue
		}
	}
	
	///	:returns:	`true` if current calling queue equals to queue that
	///			the queue designated at initialiser.
	func check() -> Bool {
		let	context		=	dispatch_get_specific(&_KEYMEM)
		let	equality	=	context == _idptr
		return	equality
	}

	///

	private let	_queue		:	dispatch_queue_t
	private var	_KEYMEM		=	UInt8(0)
	private let	_idptr		:	UnsafeMutablePointer<UInt8>	//<	A marker pointer. Content of this pointer shouldn't be dereferenced at all.

}