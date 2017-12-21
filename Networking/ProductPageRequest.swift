//
//  ProductPageRequest.swift
//  WalMartProductsSwift
//
//  Created by Michael Billard on 12/8/17.
//  Copyright © 2017 Sympathetic Software. All rights reserved.
//

import Foundation
import CoreData

/**
 This error provides cases for things that can go wrong when making a product page request.
*/
enum ProductRequestError: Error {
    case invalidAPIKey
    case invalidServerURL
    case responseError(description: String)
}

/**
 This class performs a JSON request to get a list of products by page number.
*/
class ProductPageRequest {
    // Path to the walmart products. Correct format is {URL}/walmartproducts/{apiKey}/{pageNumber}/{pageSize}
    let PRODUCT_REQUEST_PATH = "/walmartproducts/"
    
    /// Max number of products that can be returned
    let MAX_PAGE_SIZE = 30
    
    /// API key needed to access the server
    var apiKey : String
    
    // URL to the server
    var serverURL: String
    
    /// Number of products to return. Max size is 30
    var pageSize: Int
    
    /// Total number of products returned by the server
    var totalProducts: Int
    
    /// URLSession object that's used to create tasks
    let urlSession = URLSession(configuration: .default)
    
    /**
     Default constructor
    */
    init() {
        apiKey = "DEADBEEF"
        serverURL = "DEADBEEF"
        pageSize = -1
        totalProducts = -1
    }
    
    /**
     Constructor that specifies the url, key, and page size
    */
    init(url: String, key: String, pageSize: Int) throws {
        
        //Sanity checks
        if key == "" {
            throw ProductRequestError.invalidAPIKey
        }
        if url == "" {
            throw ProductRequestError.invalidServerURL
        }
        
        apiKey = key
        serverURL = url
        totalProducts = -1
        if (pageSize < MAX_PAGE_SIZE) {
            self.pageSize = pageSize
        } else {
            self.pageSize = MAX_PAGE_SIZE
        }
    }
    
    
    /**
     This method requests a specific page from the server. If the API key or server URL hasn't been set up,
     then it will generate a ProductRequestError.
     - Parameter pageID: an Int containing the page ID to request.
     - Parameter withMoc: An NSManagedObjectContext.
     - completionHandler: A closure to execute after the request completes or has an error.
     */
    func requestPage(pageID: Int, withMoc moc: NSManagedObjectContext, completionHandler: @escaping (Int, NSError?, [NSManagedObject]?) -> Void) throws {
        //Sanity checks
        if self.apiKey == "" {
            throw ProductRequestError.invalidAPIKey
        }
        if self.serverURL == "" {
            throw ProductRequestError.invalidServerURL
        }
        
        //Formulate the request
        let urlRequestString = self.serverURL + PRODUCT_REQUEST_PATH + self.apiKey + "/\(pageID)/\(self.pageSize)"
        print("URL request: \(urlRequestString)")
        let url = URL(string: urlRequestString)
        let urlRequest = URLRequest(url: url!)
        
        //Create the task
        let task = self.urlSession.dataTask(with: urlRequest, completionHandler: { (data, response, urlError) in
            //Handle and request errors
            if let error = urlError as NSError? {
                print("Error while executing data task: \(error.localizedDescription)")
                //Run completion handler and provide the error
                completionHandler(0, error, nil)
                return
            }
            
            //Check the status code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    //Process the response into managed objects
                    do {
                        let productList = try self.getProductsFromData(data: data, withMoc: moc, forPage: pageID)
                        completionHandler(200, nil, productList)
                    }
                    catch let error as NSError {
                        //Run completion handler and pass the error
                        completionHandler(0, error, nil)
                    }
                    //Run completion handler
                } else {
                    //Run completion handler and provide the status code
                    completionHandler(httpResponse.statusCode, nil, nil)
                }
            }
        })
        task.resume()
    }
    
    /**
     This method parses the supplied data and tries to build Product objects from the expected JSON.
     - Parameter data: A Data object containing JSON to parse.
     - Parameter withMoc: An NSManagedObjectContext to create the managed objects from.
     - Returns: An array of NSManagedObject objects
     */
    func getProductsFromData(data: Data?, withMoc moc: NSManagedObjectContext, forPage pageID: Int) throws -> [NSManagedObject] {
        var productArray = [NSManagedObject]()
        
        if let data = data {
            do {
                //Try to parse the JSON
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue:0)) as! [String: AnyObject]
                
                //We should see status, pageSize, pageNumber, totalProducts, and products.
                //We're primarily interested in the products
                //Total products
                if let totalProducts = jsonResponse["totalProducts"] as? Int {
                    self.totalProducts = totalProducts
                }
                
                //products
                var product: NSManagedObject
                if let productList = jsonResponse["products"] as? [AnyObject] {
                    for productItem in productList {
                        if let productJSON = productItem as? [String: Any] {
                            do {
                                product = try Product.createFromJSON(json: productJSON, withMoc: moc)
                                product.setValue(pageID, forKey: "pageID")
                                productArray.append(product)
                            }
                            //Let's be graceful. If we get any errors, just skip the product entry.
                            catch let addEntryError as NSError {
                                print("Error while trying to parse a JSON entry: \(addEntryError.localizedDescription)")
                                print("JSON: \(productJSON)")
                            }
                        }
                    }
                    print("total products retrieved: \(productArray.count) for page: \(pageID)")
                }
                try moc.save()
            }
            catch let error as NSError {
                throw error
            }
        }

        return productArray
    }
}
