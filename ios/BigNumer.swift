//
//  BigNumer.swift
//  zilpayMobile
//
//  Created by Alexander Batalov on 10/20/20.
//

import Foundation

@objc(BigNumber)
class BigNumber: NSObject, RCTBridgeModule {
  
  static func moduleName() -> String! {
    return "BigNumber"
  }
  
  
  @objc(test:)
  func test(text: String) -> bignum256 {
    print("call test function wuth big Nnumber", text, bignum256.init(val: (1, 1, 1, 1, 1, 1, 1, 1, 1)))
    return bignum256.init(val: (1, 1, 1, 1, 1, 1, 1, 1, 1))
  }
}
