//
//  StoreKitProducts.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 06/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

public struct StoreKitProducts {

  public static let DataInsights = "com.javierdemartin.bici.purchases.unlock_data_insights"

  private static let productIdentifiers: Set<ProductIdentifier> = [StoreKitProducts.DataInsights]

  public static let store = IAPHelper(productIds: StoreKitProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
  return productIdentifier.components(separatedBy: ".").last
}

