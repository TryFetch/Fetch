//
//  FetchUITests.swift
//  FetchUITests
//
//  Created by Stephen Radford on 26/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import XCTest

class FetchUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        let app = XCUIApplication()
        
        // Hide alert
        if app.alerts["“Fetch” Would Like to Send You Notifications"].exists {
            app.alerts["“Fetch” Would Like to Send You Notifications"].collectionViews.buttons["OK"].tap()
        }
        
        sleep(10)
        
        let fetchTvmovieviewNavigationBar = app.navigationBars["Fetch.TVMovieView"]
        
        // Screenshot movies
        fetchTvmovieviewNavigationBar.buttons["Movies"].tap()
        snapshot("01Movies")
        
        // screenshot tv
        fetchTvmovieviewNavigationBar.buttons["TV Shows"].tap()
        snapshot("02TVShows")
        
        // screenshot season
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 2).collectionViews.cells.otherElements.children(matching: .image).element.tap()
        snapshot("03Season")
        
        // screenshot continue playing
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element
        element.tap()
        snapshot("04Continue")
        app.alerts["Continue Playing"].collectionViews.buttons["Yes"].tap()
        let doneButton = app.buttons["Done"]
        doneButton.tap()
        XCUIDevice.shared().orientation = .portrait
        
        
        // screenshot multiple selection
        app.tabBars.buttons["All Files"].tap()
        let allFilesNavigationBar = app.navigationBars["All Files"]
        allFilesNavigationBar.buttons["Edit"].tap()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Public Domain TV"].tap()
        tablesQuery.staticTexts["Images"].tap()
        tablesQuery.staticTexts["Podcasts"].tap()
        allFilesNavigationBar.buttons["Cancel"].tap()
        snapshot("05Multiple")
        
        
        tablesQuery.staticTexts["Public Domain TV"].tap()
        tablesQuery.staticTexts["The Life Of Riley (1949) S01E03"].tap()
        let moreButton = tablesQuery.buttons["More"]
        moreButton.tap()
        let downloadFileButton = app.sheets.collectionViews.buttons["Download File"]
        downloadFileButton.tap()
        tablesQuery.staticTexts["The Life Of Riley (1949) S01E02"].tap()
        moreButton.tap()
        downloadFileButton.tap()
        
        XCUIApplication().tabBars.buttons["More"].tap()
        snapshot("06More")
        
        XCUIApplication().tables.staticTexts["All Downloads"].tap()
        snapshot("07Downloads")
        
    }
    
}
