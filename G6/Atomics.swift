//
//  AtomicInt.swift
//  MulticastingStorage
//
//  Created by Hoon H. on 2015/08/06.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

import Foundation

struct AtomicInt {
	init(_ state: Int) {
		self.state	=	state
	}
	var state: Int {
		get {
			return	_state
		}
		set {
			let	ok	=	OSAtomicCompareAndSwapLongBarrier(_state, newValue, &_state)
			precondition(ok, "Atomic set operation failed. WTF?")
		}
	}

	private var	_state	=	0 as Int
}

struct AtomicBool {
	init(_ state: Bool) {
		self.state	=	state
	}
	var state: Bool {
		get {
			return	_int.state != 0
		}
		set {
			_int.state	=	newValue ? 1 : 0
		}
	}

	private var	_int	=	AtomicInt(0)
}