//
//  WalMartProductsSwiftTests.swift
//  WalMartProductsSwiftTests
//
//  Created by Michael Billard on 12/8/17.
//  Copyright © 2017 Sympathetic Software. All rights reserved.
//

import XCTest
import CoreData
@testable import WalMartProductsSwift

class WalMartProductsSwiftTests: XCTestCase {
    let apiKey = "dd9085cd-80dc-44b9-be08-e6f5bae99b14"
    let serverURL = "https://walmartlabs-test.appspot.com/_ah/api/walmart/v1"
    
    let testValidJSON: [String: Any] = ["productId":"31e1cb21-5504-4f02-885b-8f267131a93f",
                                   "productName":"VIZIO Class Full-Array LED Smart TV",
                                   "shortDescription":"This is a short description",
                                   "longDescription":"This is a long description",
                                   "price":"$878.00",
                                   "productImage":"http://someurl/0084522601078_A",
                                   "reviewRating":0.0,
                                   "reviewCount":0,
                                   "inStock":true
                                   ]
    
    //The only thing different than testValidJSON is that the price is updated.
    let PRICE_UPDATE = "$500.00"
    let testValidJSONDuplicate: [String: Any] = ["productId":"31e1cb21-5504-4f02-885b-8f267131a93f",
                                        "productName":"VIZIO Class Full-Array LED Smart TV",
                                        "shortDescription":"This is a short description",
                                        "longDescription":"This is a long description",
                                        "price":"$500.00",
                                        "productImage":"http://someurl/0084522601078_A",
                                        "reviewRating":0.0,
                                        "reviewCount":0,
                                        "inStock":true
    ]
    
    //Invalid JSON response. Note that price is a number instead of a string.
    let testInvalidJSONPrice: [String: Any] = ["productId":"31e1cb21-5504-4f02-885b-8f267131a93f",
                                        "productName":"VIZIO Class Full-Array LED Smart TV",
                                        "shortDescription":"This is a short description",
                                        "longDescription":"This is a long description",
                                        "price":878.00,
                                        "productImage":"http://someurl/0084522601078_A",
                                        "reviewRating":0.0,
                                        "reviewCount":0,
                                        "inStock":true
    ]
    
    //Network requests can take time, and calling our code blocks can be called asynchronously sometime after
    //the test itself has run. To prevent the test from making the network request and exiting before the
    //operation can complete, we need to set a flag and wait until it's set to true.
    var requestComplete = false
    
    //We also need to make sure that we're not stuck in an infinite loop.
    //this variable gives us a max time to wait for the network request to complete.
    let MAX_REQUEST_SECONDS = 30.0
    
    //Flag to indicate that the timer expired
    var timerExpired = false

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func waitUntilDone() {
        
        //Setup our flags
        self.requestComplete = false
        self.timerExpired = false
        
        //Get our boot time
        let startTime = Date()
        var endTime = Date()
        
        repeat {
            //Check for timer expire
            endTime = Date()
            if endTime.timeIntervalSince(startTime) > MAX_REQUEST_SECONDS {
                self.requestComplete = true
                self.timerExpired = true
            }
        } while self.requestComplete == false
    }
    
    func getMemoryManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            let error = error
            print("Could not create MOC. Error: \(error.localizedDescription)")
            XCTFail()
        }
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        return managedObjectContext
    }
    
    func testValidJSONToProduct() {
        do {
            print("Trying to create a Product object with testValidJSON")
            let moc = getMemoryManagedObjectContext()
            let testProduct = try Product.createFromJSON(json: testValidJSON, withMoc: moc)
            XCTAssertNotNil(testProduct)
            moc.delete(testProduct)
        } catch ProductJSONParsingError.missingField(let missingField) {
            print("Unable to parse JSON into a Product object. Missing field: \(missingField)")
            XCTFail()
        } catch ProductJSONParsingError.invalidJSONField(let field) {
            print("Unable to parse JSON into a Product object. Invalid field: \(field)")
            XCTFail()
        } catch {
            XCTFail()
        }
    }
    
    func testDuplicateJSON() {
        do {
            print("Trying to create a Product object with testValidJSON")
            let moc = getMemoryManagedObjectContext()
            var testProduct = try Product.createFromJSON(json: testValidJSON, withMoc: moc)
            XCTAssertNotNil(testProduct)
            testProduct = try Product.createFromJSON(json: testValidJSONDuplicate, withMoc: moc)
            XCTAssertNotNil(testProduct)
            let priceUpdate = testProduct.value(forKey: Product.PRICE) as! String
            XCTAssertTrue(priceUpdate == PRICE_UPDATE)
            moc.delete(testProduct)
        } catch ProductJSONParsingError.missingField(let missingField) {
            print("Unable to parse JSON into a Product object. Missing field: \(missingField)")
            XCTFail()
        } catch ProductJSONParsingError.invalidJSONField(let field) {
            print("Unable to parse JSON into a Product object. Invalid field: \(field)")
            XCTFail()
        } catch {
            XCTFail()
        }
    }
    
    func testInvalidJSONToProduct() {
        do {
            print("Trying to create a Product object with testInvalidJSONPrice")
            let moc = getMemoryManagedObjectContext()
            let testProduct = try Product.createFromJSON(json: testInvalidJSONPrice, withMoc: moc)
            XCTAssertNil(testProduct)
        } catch ProductJSONParsingError.missingField(let missingField) {
            print("Unable to parse JSON into a Product object. Missing field: \(missingField)")
            XCTFail()
        } catch ProductJSONParsingError.invalidJSONField(let field) {
            print("Unable to parse JSON into a Product object. Expecting: \(Product.PRICE) and got: \(field)")
            XCTAssertTrue(field == Product.PRICE)
        } catch {
            XCTFail()
        }
    }
    
    func testNetworkRequest() {
        do {
            //We use an in-memory database to save the data. This is for testing purposes.
            let moc = getMemoryManagedObjectContext()
            let productRequestCount = 1
            let pageRequest = try ProductPageRequest(url: serverURL, key: apiKey, pageSize: productRequestCount)
            
            //NOTE: at runtime, we want to run this as a background task.
            //appDelegate.persistentContainer.performBackgroundTask()...
            //That way we don't block the main thread.
            try pageRequest.requestPage(pageID: 0, withMoc: moc, completionHandler: { (statusCode, error, products) in
                //Check status code
                if statusCode != 200 {
                    self.requestComplete = true
                    print("testNetworkRequest - Server returned status code: \(statusCode)")
                    XCTFail()
                }
                
                //Check error
                if let error = error {
                    print("testNetworkRequest - encountered error: \(error.localizedDescription)")
                    self.requestComplete = true
                    XCTFail()
                }
                
                //Check products
                if let products = products {
                    self.requestComplete = true
                    
                    //Get the number of products returned
                    let productCount = products.count
                    print(" testNetworkRequest - Product Count: \(productCount)")
                    
                    //Clean up the moc
                    for doomed in products {
                        moc.delete(doomed)
                    }
                    
                    //Make sure we got back the requested number of products
                    if productCount != productRequestCount {
                        XCTFail()
                    }
                } else {
                    self.requestComplete = true
                    XCTFail()
                }
            })
        }
        catch {
            self.requestComplete = true
            XCTFail()
        }
        
        //Give us time to complete the task
        self.waitUntilDone()
        if (self.timerExpired) {
            print("testNetworkRequest - Network request timeout.")
            XCTFail()
        }
    }
}
