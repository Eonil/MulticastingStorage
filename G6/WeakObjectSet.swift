//
//  WeakObjectSet.swift
//  G6
//
//  Created by Hoon H. on 2015/07/30.
//  Copyright (c) 2015 Eonil. All rights reserved.
//

import Foundation

///	A set contains weak reference to objects.
///
///	You're responsible to keep the objects alive while they're referenced
///	in this set. Otherwise, this set will crash while iteration.
///
final class WeakObjectSet<T: AnyObject>: SequenceType {

	deinit {
		///	Not really required in this design, but to train you a good habbit...
		assert(_delegateMap.count > 0, "You MUST deregister ALL delegates from this object BEFORE this object dies.")
	}

	var count: Int {
		get {
			return	_delegateMap.count
		}
	}
	func generate() -> GeneratorOf<T> {
		var	g	=	_delegateMap.generate()
		return	GeneratorOf { ()->T? in
			if let (k,v) = g.next() {
				if let v = v() {
					return	v
				}
				else {
					fatalError("A delegate for `\(k)` dead too early before it to be `deregister`ed from this object!")
				}
			}
			return	nil
		}
	}
	func map(@noescape f: T->()) {
		for d in self {
			f(d)
		}
	}

	///

	func insert(delegate: T) {
		_delegateMap[ObjectIdentifier(delegate)]	=	{ [weak self, weak delegate] in return delegate }
	}
	func remove(delegate: T) {
		_delegateMap[ObjectIdentifier(delegate)]	=	nil
	}

	///

	private typealias	_Box		=	()->(T?)
	private var		_delegateMap	=	[ObjectIdentifier: _Box]()
}