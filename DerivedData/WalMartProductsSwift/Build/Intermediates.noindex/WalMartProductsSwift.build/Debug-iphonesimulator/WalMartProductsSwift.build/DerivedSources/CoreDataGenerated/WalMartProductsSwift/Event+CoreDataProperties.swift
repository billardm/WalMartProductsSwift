//
//  Event+CoreDataProperties.swift
//  
//
//  Created by Michael Billard on 12/21/17.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Event {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }

    @NSManaged public var timestamp: Date?

}
