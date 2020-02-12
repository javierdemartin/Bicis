//
//  String.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 03/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

extension String {

    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }

    func localize(file: String) -> String {
        return NSLocalizedString(self, tableName: file, bundle: Bundle.main, value: "", comment: "")
    }

    func stringClassFromString() -> AnyClass? {

        /// get namespace
        guard let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String else { return nil }

        /// get 'anyClass' with classname and namespace
        let cls: AnyClass = NSClassFromString("\(namespace).\(self)")!;

        // return AnyClass!
        return cls;
    }
}
