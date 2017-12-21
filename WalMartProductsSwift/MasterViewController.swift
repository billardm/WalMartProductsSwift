//
//  MasterViewController.swift
//  WalMartProductsSwift
//
//  Created by Michael Billard on 12/8/17.
//  Copyright © 2017 Sympathetic Software. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate, DetailNavigationDelegate {
    /// Number of items to fetch at one time
    let ITEMS_PER_PAGE = 15
    
    /// Current page number of the items we're viewing. Starts from 1 according to the documentation.
    let START_PAGE = 1
    var currentPageID = 1
    
    /// Total number of items returned from the fetch request
    var totalProducts = 0
    
    /// Page request object
    var productPageRequest: ProductPageRequest? = nil
    
    //Flag to indicate that we have a fetch request in progress
    var fetchInProgress = false

    /// View controller for showing details
    var detailViewController: DetailViewController? = nil
    
    /// Database object
    var managedObjectContext: NSManagedObjectContext? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Refresh button
        let addButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshPage))
        navigationItem.rightBarButtonItem = addButton
        
        //Detail view
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
            detailViewController?.navigationDelegate = self
        }
        
        //Current page
        currentPageID = self.getCurrentPage()
        print("currentPageID: \(currentPageID)")
        
        //Network request object
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        do {
            try self.productPageRequest = ProductPageRequest(url: appDelegate.serverURL,
                                                             key: appDelegate.apiKey,
                                                             pageSize: ITEMS_PER_PAGE)
        }
        catch {
            let error = error as! ProductRequestError
            switch error {
            case ProductRequestError.invalidServerURL:
                print("Unable to create the ProductPageRequest. Server URL appears to be nil or invalid.")
            case ProductRequestError.invalidAPIKey:
                print("Unable to create the ProductPageRequest. API key appears to be nil or invalid.")
            default:
                print ("Unable to create the ProductPageRequest due to an error: \(error.localizedDescription)")
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    func refreshPage() {
        fetchProducts()
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
            let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationDelegate = self
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        totalProducts = sectionInfo.numberOfObjects
        return totalProducts
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let product = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withProduct: product)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    func configureCell(_ cell: UITableViewCell, withProduct product: Product) {
        cell.textLabel!.text = product.productName!
    }
    
    // MARK: - DetailNavigationDelegate
    func getNextListItem() -> Product? {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            if indexPath.row + 1 <= self.totalProducts {
                let nextIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                tableView.selectRow(at: nextIndexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
                let product = fetchedResultsController.object(at: nextIndexPath)
                return product
            }
        }
        return nil
    }
    
    func getPreviousListItem() -> Product? {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            if indexPath.row - 1 >= 0 {
                let prevIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
                tableView.selectRow(at: prevIndexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
                let product = fetchedResultsController.object(at: prevIndexPath)
                return product
            }
        }
        return nil
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<Product> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        //Fetch the current page
        
        //Fetch the products
        let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "productId", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
            let sectionInfo = _fetchedResultsController!.sections![0]
            totalProducts = sectionInfo.numberOfObjects
            print("Database has \(totalProducts) products.")
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController<Product>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                if let tableCell = tableView.cellForRow(at: indexPath!) {
                    configureCell(tableCell, withProduct: anObject as! Product)
                }
            case .move:
                if let tableCell = tableView.cellForRow(at: indexPath!) {
                    configureCell(tableCell, withProduct: anObject as! Product)
                    tableView.moveRow(at: indexPath!, to: newIndexPath!)
                }
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    // MARK: - Scroll view
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.fetchInProgress {
            return
        }
        
        //Get scroll position and max possible scroll
        let scrollPos = scrollView.contentOffset.y
        let frameHeight = scrollView.frame.size.height
        let contentHeight = scrollView.contentSize.height
        
        //A bit of a hack but when we first start the scroll position is negative
        //We don't want to trigger a fetch at this point.
        if scrollPos < 0 || contentHeight <= 0 {
            return
        }

        //If we scroll near our trigger height then initiate a fetch
        if scrollPos + frameHeight >= contentHeight {
            self.fetchInProgress = true
            if totalProducts > 0 {
                currentPageID += 1
                self.setCurrentPage(pageID: currentPageID)
            }
            
            //Do the fetch
            self.fetchProducts()
        }
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         tableView.reloadData()
     }
     */
    
    // Mark: - Helpers
    
    /**
     Sets the current page in the database
     - Parameter pageID: An Int containing the new page number
    */
    func setCurrentPage(pageID: Int) {
        do {
            //Get the MOC
            let moc = self.managedObjectContext!
            
            //Fetch the products
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Page")
            fetchRequest.fetchBatchSize = 1
            
            //Make the fetch request.
            let fetchResult = try moc.fetch(fetchRequest)
            
            //Set the page ID
            if let fetchResult = fetchResult as? [Page] {
                //Update the page ID
                if fetchResult.count > 0 {
                    let pageObject = fetchResult[0]
                    pageObject.pageID = Int32(pageID)
                    try moc.save()
                }
                //Add new entry
                else {
                    let entity = NSEntityDescription.entity(forEntityName: "Page", in: moc)!
                    let currenPage = Page(entity: entity, insertInto: moc)
                    currenPage.pageID = Int32(self.START_PAGE)
                    try moc.save()
                }
            }
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    /**
        Returns the current page that we've loaded from the database
        - Returns: an Int containing the current page, or self.START_PAGE if there was an error.
    */
    func getCurrentPage() -> Int {
        do {
            //Get the MOC
            let moc = self.managedObjectContext!
            
            //Fetch the products
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Page")
            fetchRequest.fetchBatchSize = 1
            
            //Make the fetch request.
            let fetchResult = try moc.fetch(fetchRequest)
            
            //If we find something, then return the first entry.
            if let fetchResult = fetchResult as? [Page] {
                if fetchResult.count > 0 {
                    return Int(fetchResult[0].pageID)
                }
                //Add new entry if needed
                else {
                    let entity = NSEntityDescription.entity(forEntityName: "Page", in: moc)!
                    let currenPage = Page(entity: entity, insertInto: moc)
                    currenPage.pageID = Int32(self.START_PAGE)
                    try moc.save()
                    return self.START_PAGE
                }
            }
        } catch {
            return self.START_PAGE
        }
        return self.START_PAGE
    }
    
    /**
     This function fetches products from the server by first setting up a private managed object context.
     This is necessary to avoid tying up the main thread.
    */
    func fetchProducts() {
        //Get the private MOC
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = self.managedObjectContext
        
        //Do the request on the private MOC
        privateMOC.perform {
            do {
                try self.productPageRequest?.requestPage(pageID: self.currentPageID,
                                                         withMoc: privateMOC,
                    completionHandler: { (statusCode, error, products) in
                        //Check error
                        if let error = error {
                            print("fetchProducts - encountered error: \(error.localizedDescription)")
                            //Inform the user...
                            self.fetchInProgress = false
                        }
                        
                        //Check error code
                        if statusCode == 200 {
                            DispatchQueue.main.async {
                                do {
                                    //Save the data in our MOC.
                                    try self.managedObjectContext?.save()
                                    
                                    //Re-fetch the data
                                    try self.fetchedResultsController.performFetch()
                                    
                                    //Reset our flag
                                    self.fetchInProgress = false
                                    
                                    //Reload the table
                                    self.tableView.reloadData()
                                } catch {
                                    self.fetchInProgress = false
                                    let nserror = error as NSError
                                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                                }
                            }
                        } else {
                            //The network request went through but something is wrong.
                            //Inform the user.
                        }
                })
            } catch {
                return
            }
        }
    }
}
