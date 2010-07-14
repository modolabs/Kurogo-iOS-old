// Globals.
target = UIATarget.localTarget();
application = target.frontMostApp();
mainWindow = application.mainWindow();

// Utility functions.
function msg(message)
{
	UIALogger.logMessage(message);
}

// Test helpers.

function logTestResult(result, testname)
{
	if (result)
	{
		UIALogger.logPass(testname);
	}
	else
	{
		UIALogger.logFail(testname);
	}	
}

// From http://alexvollmer.com/posts/2010/07/03/working-with-uiautomation/

function assertEquals(expected, received, message) {
  if (received != expected) {
    if (! message) message = "Expected " + expected + " but received " + received;
    throw message;
  }
}

function assertTrue(expression, message) {
  if (! expression) {
    if (! message) message = "Assertion failed";
    throw message;
  }
}

function assertFalse(expression, message) {
  assertTrue(! expression, message);
}

function assertNotNull(thingie, message) {
  if (thingie == null || thingie.toString() == "[object UIAElementNil]") {
    if (message == null) message = "Expected not null object";
    throw message;
  }
}

// Navigation functions.
function navigateToPeopleView()
{
	tabbar = mainWindow.tabBar();
	buttons = tabbar.buttons();	
	moreButton = buttons.More;
	moreButton.tap();
	tableView = mainWindow.tableViews()[0];
	peopleDirectoryCell = tableView.cells()["People Directory"];
	peopleDirectoryCell.tap();
}

function navigateBack()
{
	mainWindow.navigationBar().leftButton().tap();
}

// Test helpers.
function verifySearchTargetInfo(fieldName, fieldValue)
{
	// Assumes current view is the people details view.
	// The cells in the details view are labeled in the format "email, [the person's email]".
	cell = mainWindow.tableViews()[0].cells().firstWithName(fieldName + ", " + fieldValue);
	
	if (cell.checkIsValid())
	{
		msg("Found the cell for " + fieldName + " and " + fieldValue);
	}
	else
	{
		UIALogger.logError("Couldn't find the cell for " + fieldName + " and " + fieldValue);		
	}
	
	return (cell.isValid());
	
	// TODO: Get at the actual text of the cells, not just the accessibility label. Using valueForKey?
	
	//msg("Number of elements: " + cell.elements().length);
	//msg("cell contents: " + cell.elements()[0].value());
	//cell.elements()[0].logElementTree();
}

// Tests.

// After this runs, you should end up at the people details view for the first search result.
function runSearch(searchTerm)
{	
	// Type Mercure into the search field and run the search.
	tableView = mainWindow.tableViews()[0];
	searchBar = tableView.searchBars()[0];
	searchBar.tap();
	searchBar.setValue(searchTerm); 
	keyboard = application.keyboard();
	buttons = keyboard.buttons();	
	searchButton = buttons["search"];
	searchButton.tap();
	
	// Follow the search result.
	
	// Will wait up to five seconds for the search button to go invalid.
	target.pushTimeout(5);
	
	searchButton.waitForInvalid(); 
	msg("Number of table views: " + application.mainWindow().tableViews().length);
	resultTableView = application.mainWindow().tableViews()[0];
	assertNotNull(resultTableView);
	
	//resultCells = resultTableView.cells();
	//resultCell = resultCells[searchResultToPursue];
	//resultCell.tap(); // Why doesn't this work? Most likely, another view is in front of this cell.
	// TODO: Get this to tap the cell containing a desired result directly instead of hitting the location 
	// containing the first result's cell.

	// Tap the spot containing the result cell.
	target.tap({ x:120, y:120 }); 
	resultCell.waitForInvalid(); 
	
	target.popTimeout();
}

// Assumes you are in the people details view.
function verifySearchResultInfoPairs(expectedResultsDict)
{
	var result = true;
	for (key in expectedResultsDict)
	{
		result &= verifySearchTargetInfo(key, expectedResultsDict[key]);
	}
	return result;
}

function testSuite1()
{	
	var expectedSearchResultValues = {
		"email": "amy@hillel.harvard.edu",
		"phone": "+1-617-495-4695-x241",
		"fax": "+1-617-864-1637"
	};
	
	// When searching for just the last name, this person should be found, and that person's details 
	// should match the ones in expectedSearchResultValues.
	runSearch("Mercure");
	logTestResult(verifySearchResultInfoPairs(expectedSearchResultValues), "Test Last Name Search");
	navigateBack();

	// When searching for the full name, this person should be found, and that person's details 
	// should match the ones in expectedSearchResultValues.
	runSearch("Amy Mercure");
	logTestResult(verifySearchResultInfoPairs(expectedSearchResultValues), "Test Full Name Search");
	navigateBack();

	var expectedSearchResultValuesForPhoneSearch = {
		"email": "filipe_campante@harvard.edu",
		"phone": "+1-617-384-7958",
		"dept": "KSG^Faculty Members",
		"title": "Assistant Professor in Public Policy at the John F. Kennedy School of Government"
	};

	// When searching for just the last name, this person should be found, and that person's details 
	// should match the ones in expectedSearchResultValues.
	runSearch("4795");
	logTestResult(verifySearchResultInfoPairs(expectedSearchResultValuesForPhoneSearch), "Test Partial Phone Number Search");	
}


// "Main" block.

// Provide a default grace period of 0.25 seconds for each action to complete.
target.setTimeout(0.25);
navigateToPeopleView();
testSuite1();
