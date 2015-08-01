//
//  ThreadChecker.swift
//  G6
//
//  Created by Hoon H. on 2015/08/01.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

import Foundation

///	Checks thread equality by thread ID.
///	
///	CAVEAT
///	------
///	`check` may produce false positive if thread ID has been re-used by system.
///	I don't think there's a reliable way to detect re-used thread ID.
///
///	Anyway, this guarantees to produce correct result for main-thread.
///
final class ThreadChecker {
	init() {
		_startingThreadIsMainThread	=	NSThread.isMainThread()
		_startingThreadID		=	pthread_self()
	}
	deinit {
		precondition(check(), "This object must die in same thread that created this object.")
	}

	///

	func check() -> Bool {
		if _startingThreadIsMainThread == true {
			return	NSThread.isMainThread()
		}
		let	currentThreadID	=	pthread_self()
		let	equality	=	pthread_equal(_startingThreadID, currentThreadID) != 0
		return	equality
	}
	func assert() {
		Swift.assert(check(), "Current thread must be a thread that created this object.")
	}

	///

	private let	_startingThreadIsMainThread	:	Bool
	private let	_startingThreadID		:	pthread_t
}