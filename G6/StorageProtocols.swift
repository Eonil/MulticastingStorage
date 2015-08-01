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







///	Casting order is undefined between delegates.
///	NEVER rely on the casting order.
public protocol Multicastable {
	typealias	Delegate
	func register(delegate: Delegate)
	func deregister(delegate: Delegate)
}













public protocol ValueStorageType: class, Multicastable {
	typealias	Element
	var value: Element { get }
}
public protocol ArrayStorageType: class, Multicastable {
	typealias	Element
	var array: [Element] { get }
}
//public protocol SetStorageType: class, Multicastable {
//	typealias	Key		:	Hashable
//	var set: Set<Key> { get }
//}
//public protocol DictionaryStorageType: class, Multicastable {
//	typealias	Key		:	Hashable
//	typealias	Value
//	var dictionary: [Key: Value] { get }
//}







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
//public protocol MutableSetStorageType: SetStorageType {
//	func insert(keys: Set<Key>)
//	func delete(keys: Set<Key>)
//}
//public protocol MutableDictionaryStorageType: DictionaryStorageType {
//	func insert(pairs: [Key: Value])
//	///	Replaces values for keys.
//	///	All keys must alreay be exist in this object.
//	func update(pairs: [Key: Value])
//	func delete(keys: Set<Key>)
//}


















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
//public protocol KeyGeneratorType: GeneratorType {
//	typealias	Element		:	Hashable
//}
//public protocol KeyCollectionType: CollectionType {
//	typealias	Generator	:	KeyGeneratorType
//}
//public protocol SetStorageDelegate: class, StorageDelegate {
//	typealias	KeyCollection	:	KeyCollectionType
//	func willInsertKeys(keys: KeyCollection)
//	func didInsertKeys(keys: KeyCollection)
//
//	func willDeleteKeys(keys: KeyCollection)
//	func didDeleteKeys(keys: KeyCollection)
//}
//public protocol DictionaryStorageDelegate: class, StorageDelegate {
//	typealias	KeyCollection	:	KeyCollectionType
//	func willInsertKeys(keys: KeyCollection)
//	func didInsertKeys(keys: KeyCollection)
//
//	func willUpdateKeys(keys: KeyCollection)
//	func didUpdateKeys(keys: KeyCollection)
//
//	func willDeleteKeys(keys: KeyCollection)
//	func didDeleteKeys(keys: KeyCollection)
//}



















public final class ArrayMonitor<T: AnyObject> {
	public var didAdd	:	((Range<Int>)->())?
	public var willRemove	:	((Range<Int>)->())?
}
public final class ArrayStorageAgent<T: AnyObject> {
	public var didInitiateSession		:	(()->())?
	public var willInsertRange		:	(Range<Int>->())?
	public var didInsertRange		:	(Range<Int>->())?
	public var willUpdateRange		:	(Range<Int>->())?
	public var didUpdateRange		:	(Range<Int>->())?
	public var willDeleteRange		:	(Range<Int>->())?
	public var didDeleteRange		:	(Range<Int>->())?
	public var willTerminateSession		:	(()->())?

	public init() {
		_impl.owner		=	self
	}
	deinit {
	}

	///

	internal var implementation: ArrayStorageDelegate {
		get {
			return	_impl
		}
	}

	///

	private let	_impl		=	_ArrayStorageDelegateImpl<T>()
}


private final class _ArrayStorageDelegateImpl<T: AnyObject>: ArrayStorageDelegate {
	weak var owner: ArrayStorageAgent<T>?
	func didInitiateSession() {
		owner?.didInitiateSession?()
	}
	func willInsertRange(range: Range<Int>) {
		owner?.willInsertRange?(range)
	}
	func didInsertRange(range: Range<Int>) {
		owner?.didInsertRange?(range)
	}

	func willUpdateRange(range: Range<Int>) {
		owner?.willUpdateRange?(range)
	}
	func didUpdateRange(range: Range<Int>) {
		owner?.didUpdateRange?(range)
	}

	func willDeleteRange(range: Range<Int>) {
		owner?.willDeleteRange?(range)
	}
	func didDeleteRange(range: Range<Int>) {
		owner?.didDeleteRange?(range)
	}
	func willTerminateSession() {
		owner?.willTerminateSession?()
	}
}


















