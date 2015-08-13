//
//  StorageProtocols.swift
//  EditorCommon
//
//  Created by Hoon H. on 2015/08/01.
//  Copyright (c) 2015 Eonil. All rights reserved.
//



///	DESIGN GOALS
///	------------
///
///	-	Simple intuitive as much as possible.
///	-	Least encoding/decoding efforts.
///	-	Prohibit mutating in event casting.
///	-	Prohibit mutating from different threads.






///	If everything is configured with coroutines, there's no need for
///	state-less signaling.





















public protocol ValueStorageType: class {
	typealias	Element
	var value: Element { get }
}
public protocol ArrayStorageType: class {
	typealias	Element
	var array: [Element] { get }
}







public protocol MutableValueStorageType: ValueStorageType {
	var value: Element { get set }
}
public protocol MutableArrayStorageType: ArrayStorageType {
	func insert<C : CollectionType where C.Generator.Element == Element, C.Index.Distance == Int>(newElements: C, atIndex index: Int)
	///	Replaces elements in consecutive range.
	///	Count of `newElements` must be equal to count of `range`.
	func update<C : CollectionType where C.Generator.Element == Element, C.Index.Distance == Int>(range: Range<Int>, with newElements: C)
	func delete(range: Range<Int>)
}

















public protocol StorageDelegate: class {
//	func didInitiateSession()
//	func willTerminateSession()
}
public protocol ValueStorageDelegate: class, StorageDelegate {
	func willSet()
	func didSet()
}
public protocol ArrayStorageDelegate: class, StorageDelegate {
	func willInsertRange(range: Range<Int>)
	func didInsertRange(range: Range<Int>)

	func willUpdateRange(range: Range<Int>)
	func didUpdateRange(range: Range<Int>)

	func willDeleteRange(range: Range<Int>)
	func didDeleteRange(range: Range<Int>)
}


































