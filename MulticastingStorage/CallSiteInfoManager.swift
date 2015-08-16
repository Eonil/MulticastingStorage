//
//  CallSiteInfoManager.swift
//  MulticastingStorage
//
//  Created by Hoon H. on 2015/08/16.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

struct CallSiteInfo {
	var	file		:	String
	var	line		:	Int
	var	function	:	String

	init(file: String, line: Int, function: String) {
		self.file	=	file
		self.line	=	line
		self.function	=	function
	}
}
