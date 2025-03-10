//
//  User.swift
//  TOTP
//
//  Created by Taras Markevych on 3/24/17.
//  Copyright © 2017 Taras Markevych. All rights reserved.
//

import UIKit
import RealmSwift
import CloudKit
import IceCream

public class User: Object {
    dynamic var name: String?
    dynamic var issuer: String?
    dynamic var token: String?
    
    override public static func primaryKey() -> String? {
        return "token"
    }
}


extension User: CKRecordConvertible {
    public var isDeleted: Bool { return false }    
}

extension User: CKRecordRecoverable {
    
}
