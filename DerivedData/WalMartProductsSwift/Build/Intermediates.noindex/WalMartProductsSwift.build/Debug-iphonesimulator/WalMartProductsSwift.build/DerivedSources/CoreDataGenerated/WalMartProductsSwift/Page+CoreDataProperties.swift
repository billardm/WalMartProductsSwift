//
//  Page+CoreDataProperties.swift
//  
//
//  Created by Michael Billard on 12/21/17.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Page {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Page> {
        return NSFetchRequest<Page>(entityName: "Page")
    }

    @NSManaged public var pageID: Int32

}
