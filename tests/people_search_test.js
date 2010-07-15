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
	peopleDirectoryButton = mainWindow.buttons()["People Directory"];
	peopleDirectoryButton.tap();
}

function navigateBack()
{
	mainWindow.navigationBar().elements()[0].buttons()["People Directory"].tap();
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
		errorText = "Couldn't find the cell for " + fieldName + " and " + fieldValue;
		UIALogger.logError(errorText);
		//target.captureScreenWithName(errorText);
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
	resultTableView.waitForInvalid(); 
	
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

// searchTerm_to_expectedSearchResultValues_map is a dictionary. Its keys are search terms.
// Its values are a dictionary mapping expected result fields (e.g. email) to their expected values (e.g. jim.kang@modolabs.com).
function runSearchTestSuite(testNameBase, searchTerm_to_expectedSearchResultValues_map)
{
	for (searchTerm in searchTerm_to_expectedSearchResultValues_map)
	{
		runSearch(searchTerm);
		searchResult = verifySearchResultInfoPairs(searchTerm_to_expectedSearchResultValues_map[searchTerm]);
		logTestResult(searchResult, "" + testNameBase + " search for " + searchTerm);
		navigateBack();
	}
}

function testSuite1()
{	
	var expectedSearchResultValues = {
		"email": "amy@hillel.harvard.edu",
		"phone": "+1-617-495-4695-x241",
		"fax": "+1-617-864-1637"
	};
	
	var termsToExpectedValues = {
		"Mercure": expectedSearchResultValues, // Search for just the last name.
		"Amy Mercure": expectedSearchResultValues // Search for the full name.
	};

	runSearchTestSuite("Test suite 1", termsToExpectedValues);
}

function testSuite2()
{	
	var expectedSearchResultValues = {
		"email": "filipe_campante@harvard.edu",
		"phone": "+1-617-384-7958",
		"dept": "KSG^Faculty Members",
		"title": "Assistant Professor in Public Policy at the John F. Kennedy School of Government"
	};
	
	var termsToExpectedValues = {
		"4795": expectedSearchResultValues // Search for part of the phone number.
	};

	runSearchTestSuite("Test suite 2", termsToExpectedValues);
}

function testSuite3()
{	
	var expectedSearchResultValues = {
		"email": "lwisniewski@iq.harvard.edu",
		"phone": "+1-617-496-7971",
		"dept": "FAS^FCOR^Inst Quant SocSci-Stf",
		"title": "IQSS Director of Technology Services"
	};
	
	var termsToExpectedValues = {
		"Wisniewski": expectedSearchResultValues, // Search for the last name
		"Leonard Wisniewski": expectedSearchResultValues, // Search for the full name
		"496 7971": expectedSearchResultValues, // Search for the phone number
	};

	runSearchTestSuite("Test suite 3", termsToExpectedValues);			
}

// "Main" block.

// Provide a default grace period of 0.25 seconds for each action to complete.
target.setTimeout(0.25);
navigateToPeopleView();

testSuite1();
testSuite2();
testSuite3();
