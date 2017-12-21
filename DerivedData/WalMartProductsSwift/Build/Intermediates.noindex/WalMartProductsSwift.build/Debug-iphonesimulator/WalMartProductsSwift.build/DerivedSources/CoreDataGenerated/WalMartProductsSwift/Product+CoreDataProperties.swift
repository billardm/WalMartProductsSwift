//
//  Product+CoreDataProperties.swift
//  
//
//  Created by Michael Billard on 12/21/17.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Product {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        return NSFetchRequest<Product>(entityName: "Product")
    }

    @NSManaged public var inStock: Bool
    @NSManaged public var longDesc: String?
    @NSManaged public var pageID: Int32
    @NSManaged public var price: String?
    @NSManaged public var productId: String?
    @NSManaged public var productImage: String?
    @NSManaged public var productName: String?
    @NSManaged public var reviewCount: Int32
    @NSManaged public var reviewRating: Double
    @NSManaged public var shortDesc: String?

}
