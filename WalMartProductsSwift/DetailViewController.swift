//
//  DetailViewController.swift
//  WalMartProductsSwift
//
//  Created by Michael Billard on 12/8/17.
//  Copyright © 2017 Sympathetic Software. All rights reserved.
//

import UIKit
import WebKit
import CoreData

protocol DetailNavigationDelegate {
    func getNextListItem() -> Product?
    func getPreviousListItem() -> Product?
}

class DetailViewController: UIViewController, UIGestureRecognizerDelegate {

    static let FONT_STYLE = "style=\"font-size:32px\""
    static let H1_STYLE = "style=\"font-size:64px\""
    
    var navigationDelegate: DetailNavigationDelegate?

    //Outlets
    @IBOutlet weak var webView: WKWebView!
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let webView = self.webView {
                webView.loadHTMLString(self.buildProductPage(forProduct: detail), baseURL: nil)
            }
        }
    }
    
    func buildProductPage(forProduct detail: Product) -> String {
        var htmlString = "<body>"
        
        //Product Name
        if let productName = detail.productName {
            htmlString += "<h1 \(DetailViewController.H1_STYLE)>\(productName)</h1>"
        }
        
        //In Stock
        if detail.inStock {
            htmlString += "<p \(DetailViewController.FONT_STYLE)><b>In Stock</b></p>"
        } else {
            htmlString += "<p \(DetailViewController.FONT_STYLE)>Sorry, we're out of stock</p>"
        }
        
        //Price
        if let price = detail.price {
            htmlString += "<p \(DetailViewController.FONT_STYLE)><b>Cost:</b> \(price)</p>"
        }
        
        //Review rating
        htmlString += "<p \(DetailViewController.FONT_STYLE)><b>Rating:</b> \(detail.reviewRating), \(detail.reviewCount) reviews</p>"
        
        //Short description
        //This might be empty, some entries don't have a short description
        if let shortDescription = detail.shortDesc {
            if shortDescription != Product.EMPTY_ITEM {
                htmlString += "<p>" + shortDescription + "</p>"
            }
        }
        
        //Image
        //This might be empty
        if let imageURL = detail.productImage {
            if imageURL != Product.EMPTY_ITEM {
                htmlString += "<img src = \"\(imageURL)\">"
            }
        }
        
        //Long description
        //This might be empty
        if let longDescription = detail.longDesc {
            if longDescription != Product.EMPTY_ITEM{
                htmlString += "<p>" + longDescription + "</p>"
            }
        }
        
        return htmlString + "</body>"
    }
    
    @objc func swipeRight() {
        print("swipe right")
        if let delegate = self.navigationDelegate {
            if let product = delegate.getNextListItem() {
                self.detailItem = product
            }
        }
    }
    
    @objc func swipeLeft() {
        print("swipe left")
        if let delegate = self.navigationDelegate {
            if let product = delegate.getPreviousListItem() {
                self.detailItem = product
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let webView = self.webView {
            webView.allowsBackForwardNavigationGestures = false
            
            //Gestures
            let rightGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
            rightGesture.isEnabled = true
            rightGesture.numberOfTouchesRequired = 1
            rightGesture.direction = UISwipeGestureRecognizerDirection.right
            rightGesture.delegate = self
            webView.addGestureRecognizer(rightGesture)
            
            let leftGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft))
            leftGesture.isEnabled = true
            leftGesture.numberOfTouchesRequired = 1
            leftGesture.direction = UISwipeGestureRecognizerDirection.left
            leftGesture.delegate = self
            webView.addGestureRecognizer(leftGesture)
        }
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var detailItem: Product? {
        didSet {
            // Update the view.
            configureView()
        }
    }
}

