//
//  CompletionChannel.swift
//  MulticastingStorage
//
//  Created by Hoon H. on 2015/08/17.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

/// Provides a channel to observe completion event.
///
/// This is provided because storage channels cannot provide a completion
/// event. And it's because they does not allow observers to remove themselves 
/// in call. Allowing such behavior is unacceptable due to it's insanity.
/// Completion-queue deregisters observers (callbacks) automatically,
/// so does not have such issue.
///
public class CompletionChannel: CompletionChannelProtocol {

	private init() {
	}
	deinit {
		assert(_callbacks.count == 0, "You haven't `cast`ed this queue, and it seems to be a programmer error. You should always consume all queued callbacks by calling `cast`. Do not use this for optional event.")
	}

	///

	/// Enqueues a completion callback.
	///
	/// You can enqueue a new callback in a callback. Anyway newrly added
	/// callbacked will not be called, and called at next event.
	///
	/// - Parameter callback:
	///	Will be called at completion, and removed automatically
	///	after called.
	/// 	Calling order between callback are **UNDEFINED**. Do not
	/// 	depend on such order.
	///
	public func queue(callback: ()->()) {
		_callbacks.append(callback)
	}

	///

	private var	_callbacks	=	Array<()->()>()
	private var	_isCasted	=	false
}

public class CompletionQueue: CompletionChannel {
	public override init() {
		super.init()
	}

	///

	/// Calls and removes all queued callbacks.
	/// You can call this only once, and cannot call again.
	public func cast() {
		assert(_isCasted == false, "`CompletionQueue` is disposable, and one-time-use-only. You cannot `cast` once casted (so marked to be completed) again.")
		_isCasted	=	true

		let	callbacksCopy	=	_callbacks
		for cb in callbacksCopy {
			cb()
		}
		_callbacks	=	[]
	}
}















