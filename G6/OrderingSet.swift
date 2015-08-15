//
//  OrderingSet.swift
//  MulticastingStorage
//
//  Created by Hoon H. on 2015/08/15.
//  Copyright © 2015 Eonil. All rights reserved.
//

struct OrderingSet<T: Equatable>: SequenceType {
	var count: Int {
		get {
			return	_list.count
		}
	}
	func generate() -> AnyGenerator<T> {
		return	anyGenerator(_list.generate())
	}
	mutating func insert(value: T) {
		assert(_list.filter({ $0 == value }).count == 0)
		_list.append(value)
	}
	mutating func remove(value: T) {
		assert(_list.filter({ $0 == value }).count == 1)
		_list	=	_list.filter({ $0 != value })
	}

	///

	private var	_list	=	[T]()
}
