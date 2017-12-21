//
//  Product.swift
//  WalMartProductsSwift
//
//  Created by Michael Billard on 12/8/17.
//  Copyright © 2017 Sympathetic Software. All rights reserved.
//

import Foundation
import CoreData

/**
 This is a custom error used to provide feedback when parsing JSON strings into Product objects.
*/
enum ProductJSONParsingError: Error {
    case missingField(missingField: String)
    case invalidJSONField(field: String)
}

/**
 This extension to the Product Core Data object describes a product from Wal-Mart's product data server.
 It's an object-oriented representation of the JSON string returned by a product request.
*/
extension Product {
    //Empty item constant
    static let EMPTY_ITEM = "DEADBEEF"

    //JSON constants
    static let PRODUCT_ID = "productId"
    static let PRODUCT_NAME = "productName"
    static let SHORT_DESCRIPTION = "shortDescription"
    static let LONG_DESCRIPTION = "longDescription"
    static let PRICE = "price"
    static let PRODUCT_IMAGE = "productImage"
    static let REVIEW_RATING = "reviewRating"
    static let REVIEW_COUNT = "reviewCount"
    static let IN_STOCK = "inStock"
    
    //CoreData constants
    static let SHORT_DESC = "shortDesc"
    static let LONG_DESC = "longDesc"

    /**
     Returns a description of the object with the values in its fields.
    */
    override public var description : String {
        var classInfo = "\(type(of: self))\n"
        
        classInfo.append("productId: \(self.productId ?? Product.EMPTY_ITEM)\n")
        classInfo.append("productName: \(self.productName ?? Product.EMPTY_ITEM)\n")
        classInfo.append("shortDesc: \(self.shortDesc ?? Product.EMPTY_ITEM)\n")
        classInfo.append("longDesc: \(self.longDesc ?? Product.EMPTY_ITEM)\n")
        classInfo.append("price: \(self.price ?? Product.EMPTY_ITEM)\n")
        classInfo.append("productImage: \(self.productImage ?? Product.EMPTY_ITEM)\n")
        classInfo.append("reviewRating: \(self.reviewRating)\n")
        classInfo.append("reviewCount: \(self.reviewCount)\n")
        classInfo.append("inStock: \(self.inStock)\n")

        return classInfo
    }
    
    /**
     Static function to generate a Product object from a JSON dictionary.
     - Parameter json: a String: Any dictionary containing the JSON to parse.
     - Returns: A Product object containing the fields parsed from the JSON.
    */
    static func createFromJSON(json: [String: Any]) throws -> Product {
        let productObject = Product()
        
        if json.index(forKey: PRODUCT_ID) != nil {
            guard let productID = json[PRODUCT_ID] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: PRODUCT_ID)
            }
            productObject.productId = productID
        } else {
            throw ProductJSONParsingError.missingField(missingField: PRODUCT_ID)
        }
        
        if json.index(forKey: PRODUCT_NAME) != nil {
            guard let productName = json[PRODUCT_NAME] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: PRODUCT_NAME)
            }
            productObject.productName = productName
        } else {
            throw ProductJSONParsingError.missingField(missingField: PRODUCT_NAME)
        }

        if json.index(forKey: SHORT_DESCRIPTION) != nil {
            guard let shortDescription = json[SHORT_DESCRIPTION] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: SHORT_DESCRIPTION)
            }
            productObject.shortDesc = shortDescription
        } else {
            throw ProductJSONParsingError.missingField(missingField: SHORT_DESCRIPTION)
        }

        if json.index(forKey: LONG_DESCRIPTION) != nil {
            guard let longDescription = json[LONG_DESCRIPTION] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: LONG_DESCRIPTION)
            }
            productObject.longDesc = longDescription
        } else {
            throw ProductJSONParsingError.missingField(missingField: LONG_DESCRIPTION)
        }

        if json.index(forKey: PRICE) != nil {
            guard let price = json[PRICE] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: PRICE)
            }
            productObject.price = price
        } else {
            throw ProductJSONParsingError.missingField(missingField: PRICE)
        }

        if json.index(forKey: PRODUCT_IMAGE) != nil {
            guard let productImage = json[PRODUCT_IMAGE] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: PRODUCT_IMAGE)
            }
            productObject.productImage = productImage
        } else {
            throw ProductJSONParsingError.missingField(missingField: PRODUCT_IMAGE)
        }

        if json.index(forKey: REVIEW_RATING) != nil {
            guard let reviewRating = json[REVIEW_RATING] as? Double else {
                throw ProductJSONParsingError.invalidJSONField(field: REVIEW_RATING)
            }
            productObject.reviewRating = reviewRating
        } else {
            throw ProductJSONParsingError.missingField(missingField: REVIEW_RATING)
        }

        if json.index(forKey: REVIEW_COUNT) != nil {
            guard let reviewCount = json[REVIEW_COUNT] as? Int32 else {
                throw ProductJSONParsingError.invalidJSONField(field: REVIEW_COUNT)
            }
            productObject.reviewCount = reviewCount
        } else {
            throw ProductJSONParsingError.missingField(missingField: REVIEW_COUNT)
        }

        if json.index(forKey: IN_STOCK) != nil {
            guard let inStock = json[IN_STOCK] as? Bool else {
                throw ProductJSONParsingError.invalidJSONField(field: IN_STOCK)
            }
            productObject.inStock = inStock
        } else {
            throw ProductJSONParsingError.missingField(missingField: IN_STOCK)
        }

        return productObject
    }
    
    /**
     Static function to generate a Product object from a JSON dictionary.
     - Parameter json: a String: Any dictionary containing the JSON to parse.
     - Parameter moc: An NSManagedObjectContext to create the managed object from.
     - Returns: An NSManagedObject containing the fields parsed from the JSON.
     */
    static func createFromJSON(json: [String: Any], withMoc moc: NSManagedObjectContext) throws -> NSManagedObject {
        //Get the product ID first. It's our unique identifier.
        var productID: String
        if json.index(forKey: PRODUCT_ID) != nil {
            guard let jsonProductID = json[PRODUCT_ID] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: PRODUCT_ID)
            }
            productID = jsonProductID
        } else {
            throw ProductJSONParsingError.missingField(missingField: PRODUCT_ID)
        }
        //Check for an existing entry. If it exists then retrieve the existing entry and update its fields.
        //Otherwise, create a new entry.
        var productObject: NSManagedObject
        do {
            if let existingProduct = try getProductEntry(withProductID: productID, withMoc: moc) {
                productObject = existingProduct
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "Product", in: moc)!
                let newProduct = NSManagedObject(entity: entity, insertInto: moc)
                productObject = newProduct
                
                //Set our product ID
                productObject.setValue(productID, forKey: PRODUCT_ID)
            }
        }
        
        //Product name
        if json.index(forKey: PRODUCT_NAME) != nil {
            guard let productName = json[PRODUCT_NAME] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: PRODUCT_NAME)
            }
            productObject.setValue(productName, forKey: PRODUCT_NAME)
        } else {
            throw ProductJSONParsingError.missingField(missingField: PRODUCT_NAME)
        }
        
        //Short description
        //Some products might not have a description. Assume the entry is still viable
        //but put in a placeholder.
        if json.index(forKey: SHORT_DESCRIPTION) != nil {
            guard let shortDescription = json[SHORT_DESCRIPTION] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: SHORT_DESCRIPTION)
            }
            productObject.setValue(shortDescription, forKey: SHORT_DESC)
        } else {
            productObject.setValue(Product.EMPTY_ITEM, forKey: SHORT_DESC)
        }
        
        //Long description
        //Some products might not have a description. Assume the entry is still viable
        //but put in a placeholder.
        if json.index(forKey: LONG_DESCRIPTION) != nil {
            guard let longDescription = json[LONG_DESCRIPTION] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: LONG_DESCRIPTION)
            }
            productObject.setValue(longDescription, forKey: LONG_DESC)
        } else {
            productObject.setValue(Product.EMPTY_ITEM, forKey: LONG_DESC)
        }
        
        //Price
        if json.index(forKey: PRICE) != nil {
            guard let price = json[PRICE] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: PRICE)
            }
            productObject.setValue(price, forKey: PRICE)
        } else {
            throw ProductJSONParsingError.missingField(missingField: PRICE)
        }
        
        //Product Image
        //Account for products that might not have an image
        //Put in a placeholder in that case.
        if json.index(forKey: PRODUCT_IMAGE) != nil {
            guard let price = json[PRODUCT_IMAGE] as? String else {
                throw ProductJSONParsingError.invalidJSONField(field: PRODUCT_IMAGE)
            }
            productObject.setValue(price, forKey: PRODUCT_IMAGE)
        } else {
            productObject.setValue(Product.EMPTY_ITEM, forKey: PRODUCT_IMAGE)
        }
        
        //Review Rating
        if json.index(forKey: REVIEW_RATING) != nil {
            guard let reviewRating = json[REVIEW_RATING] as? Double else {
                throw ProductJSONParsingError.invalidJSONField(field: REVIEW_RATING)
            }
            productObject.setValue(reviewRating, forKey: REVIEW_RATING)
        } else {
            throw ProductJSONParsingError.missingField(missingField: REVIEW_RATING)
        }
        
        //Review count
        if json.index(forKey: REVIEW_COUNT) != nil {
            guard let reviewCount = json[REVIEW_COUNT] as? Int else {
                throw ProductJSONParsingError.invalidJSONField(field: REVIEW_COUNT)
            }
            productObject.setValue(reviewCount, forKey: REVIEW_COUNT)
        } else {
            throw ProductJSONParsingError.missingField(missingField: REVIEW_COUNT)
        }
        
        //In stock
        if json.index(forKey: IN_STOCK) != nil {
            guard let inStock = json[IN_STOCK] as? Bool else {
                throw ProductJSONParsingError.invalidJSONField(field: IN_STOCK)
            }
            productObject.setValue(inStock, forKey: IN_STOCK)
        } else {
            throw ProductJSONParsingError.missingField(missingField: IN_STOCK)
        }

        return productObject
    }
    
    static func getProductEntry(withProductID productID: String, withMoc moc: NSManagedObjectContext) throws -> NSManagedObject? {
        //Fetch the products
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Product")
        fetchRequest.fetchBatchSize = 1
        
        //Find the specific product ID
        fetchRequest.predicate = NSPredicate(format: "productId = %@", productID)
        
        //Make the fetch request.
        let fetchResult = try moc.fetch(fetchRequest)
        
        //If we find something, then return the first entry.
        if let fetchResult = fetchResult as? [NSManagedObject] {
            if fetchResult.count > 0 {
                return fetchResult[0]
            }
        }
        
        //Entry not found, don't return anything
        return nil
    }
}
