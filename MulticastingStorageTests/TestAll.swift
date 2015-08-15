//
//  TestAll.swift
//  MulticastingStorage
//
//  Created by Hoon H. on 2015/08/15.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation
@testable import MulticastingStorage

func testAll() {

	final class V1: ValueStorageDelegate {
		func willSet() {
			print("A")
		}
		func didSet() {
			print("B")
		}
	}

	let	v	=	MutableValueStorage<Int>(111)
	let	v1	=	V1()
	v.register(v1)
	v.value		=	222
	v.deregister(v1)
	

}