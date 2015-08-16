//
//  main.swift
//  MulticastingStorageWorkbench
//
//  Created by Hoon H. on 2015/08/15.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation
//@testable import MulticastingStorage

public func testAllMuticastingStorageTests() {

	func run(f: ()->()) {
		f()
	}

	run {
		let	v	=	MutableValueStorage<Int>(111)
		var	ok	=	false
		v.registerDidSet(ObjectIdentifier(v)) {
			ok	=	true
		}
		v.value		=	222
		v.deregisterDidSet(ObjectIdentifier(v))
		assert(ok)
	}

	run {

		final class V1: ValueStorageDelegate {
			var	markers	=	[Int]()
			func willSet() {
				markers.append(1)
			}
			func didSet() {
				markers.append(2)
			}
		}

		let	v	=	MutableValueStorage<Int>(111)
		let	v1	=	V1()
		v.register(v1)
		v.value		=	222
		v.deregister(v1)
		assert(v1.markers == [1,2])
	}
}

testAllMuticastingStorageTests()








