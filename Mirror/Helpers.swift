//
//  Helpers.swift
//  Mirror
//
//  Created by Kostiantyn Koval on 05/07/15.
//
//
import Foundation
func findFirst<S : Sequence> (_ s: S, condition: (S.Iterator.Element) -> Bool) -> S.Iterator.Element? {
  
  for value in s {
    if condition(value) {
      return value
    }
  }
  return nil
}

