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
    public static let FirstDonation = "com.javierdemartin.bici.donation_level_1"
    public static let SecondDonation = "com.javierdemartin.bici.donation_level_2"
    public static let ThirdDonation = "com.javierdemartin.bici.donation_level_3"
    
    private static let productIdentifiers: Set<ProductIdentifier> = [StoreKitProducts.FirstDonation, StoreKitProducts.SecondDonation, StoreKitProducts.ThirdDonation]
    
    public static let store = IAPHelper(productIds: StoreKitProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
