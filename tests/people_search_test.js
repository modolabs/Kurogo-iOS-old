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
	//mainWindow.logElementTree();
	scrollView = mainWindow.scrollViews()[0];
	//scrollView.logElementTree();
	peopleDirectoryButton = scrollView.buttons()["people"];
	peopleDirectoryButton.tap();
}

function navigateBack()
{
	mainWindow.navigationBar().elements()[0].buttons()["People Directory"].tap();
}

function hitSearchCancel()
{
	// Surprisingly, it's a child of the table view, not the search bar.	
	mainWindow.tableViews()[0].buttons().Cancel.tap();	
}

function enterSearchTermIntoSearchFieldAndHitGo(searchTerm)
{
	// Type search term into search field and run search.
	tableView = mainWindow.tableViews()[0];
	searchBar = tableView.searchBars()[0];
	searchBar.tap();
	searchBar.setValue(searchTerm); 
	keyboard = application.keyboard();
	buttons = keyboard.buttons();	
	searchButton = buttons["search"];
	searchButton.tap();	
		
	// Will wait up to five seconds for the search button to go invalid before allowing the next thing to happen.
	target.pushTimeout(5);
		
	searchButton.waitForInvalid(); 
	target.popTimeout();	
}

// Test helpers.
function verifySearchTargetInfo(fieldName, fieldValue)
{
	// Assumes current view is the people details view.
	// The cells in the details view are labeled in the format "email, [the person's email]".
	cell = mainWindow.tableViews()[0].cells().firstWithName(fieldName + ", " + fieldValue);
	//mainWindow.tableViews()[0].logElementTree();
	
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
	enterSearchTermIntoSearchFieldAndHitGo(searchTerm);
	
	// Follow the search result.	
	//msg("Number of table views: " + application.mainWindow().tableViews().length);
	resultTableView = application.mainWindow().tableViews()[0];
	assertNotNull(resultTableView);
	
	//resultCells = resultTableView.cells();
	//resultCell = resultCells[searchResultToPursue];
	//resultCell.tap(); // Why doesn't this work? Most likely, another view is in front of this cell.
	// TODO: Get this to tap the cell containing a desired result directly instead of hitting the location 
	// containing the first result's cell.

	// Tap the spot containing the result cell.
	// Will wait up to five seconds for the search button to go invalid.
	target.pushTimeout(5);
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
function runSearchTestSuite(testNameBase, searchTerm_to_expectedSearchResultValues_map, dontNavigateBack)
{
	for (searchTerm in searchTerm_to_expectedSearchResultValues_map)
	{
		runSearch(searchTerm);
		searchResult = verifySearchResultInfoPairs(searchTerm_to_expectedSearchResultValues_map[searchTerm]);
		logTestResult(searchResult, "" + testNameBase + " search for " + searchTerm);
		if (dontNavigateBack !== true)
		{
			navigateBack();			
		}
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
		"unit": "KSG / Faculty Members",
		"title": "Assistant Professor in Public Policy at the John F. Kennedy School of Government"
	};
	
	var termsToExpectedValues = {
		"7958": expectedSearchResultValues // Search for part of the phone number.
	};

	runSearchTestSuite("Test suite 2", termsToExpectedValues);
}

function testSuite3()
{	
	var expectedSearchResultValues = {
		"email": "lwisniewski@iq.harvard.edu",
		"phone": "+1-617-496-7971",
		"unit": "FAS / FCOR / Inst Quant SocSci-Stf",
		"title": "IQSS Director of Technology Services"
	};
	
	var termsToExpectedValues = {
		"Wisniewski": expectedSearchResultValues, // Search for the last name
		"Leonard Wisniewski": expectedSearchResultValues, // Search for the full name
		"496 7971": expectedSearchResultValues, // Search for the phone number
	};

	runSearchTestSuite("Test suite 3", termsToExpectedValues);			
}

function testSuite4()
{
	enterSearchTermIntoSearchFieldAndHitGo("Dave");
	// The result of this search should be an alert mentioning a search failure. 
	// Harvard LDAP will return nothing but an error for a search this broad.

	logTestResult(true, "Test suite 4 - make sure you saw the alert.");	
	// Unfortunately, when run by Instruments, UIAlerts seems to be dismissed immediately, so we don't 
	// really have a chance to check what's in them. This is puzzling because as a result, the 
	// UIAApplication.alert() method is useless.

	/*
	assertNotNull(application.alert(), "Search error alert is missing.");
	if (application.alert())
	{
		if (application.alert().staticTexts()[0] == "Search failed")
		{
			logTestResult(true, "Test suite 4");
			navigateBack();
			return;
		}
	}
	logTestResult(false, "Test suite 4");	
	*/
	
	hitSearchCancel();
}


function testSuite5()
{
	enterSearchTermIntoSearchFieldAndHitGo("asd;fih;aosdfhasd");
	// Searching for garbage should return no results.

	logTestResult(true, "Test suite 5 - make sure you saw No Results label.");	
	hitSearchCancel();
}

function testSuiteFieldsSeparatedByNewLine()
{
	var expectedSearchResultValues = {
		"email": "jmurcian@law.harvard.edu",
		"title": "Associate Director, OPIA and Director of Fellowships\nTutor, Assistant Sr (Harv Std)\nContin Ed/Spec Prog Instructor",
		"fax": "+1-617-496-4944",
		"unit": "HLS / Pblc Interest\nFAS / FCOL / Leverett-Oth\nFAS / FDCE / Other Academic"
	};
	
	var termsToExpectedValues = {
		"Judith Murciano": expectedSearchResultValues
	};

	runSearchTestSuite("Test suite: Titles and units separated by newline", termsToExpectedValues);	
}

function testSuiteActionsFromPersonDetails()
{
	var expectedSearchResultValues = {
		"email": "amy_lavoie@harvard.edu",
		"title": "Project Manager",
		"phone": "+1-617-495-3014"
	};
	
	var termsToExpectedValues = {
		"Amy Lavoie": expectedSearchResultValues
	};

	runSearchTestSuite("Test suite: Basic search for actions from person details", termsToExpectedValues, true);
	
	// Launch email.
	cell = mainWindow.tableViews()[0].cells().firstWithName("email, amy_lavoie@harvard.edu");
	assertNotNull(cell, "Couldn't find email cell.");
	if (cell.checkIsValid())
	{
		cell.tap();
		// Test runner needs to visually verify that the mail sheet came up.
		logTestResult(true, "Test suite actions from person details - make sure you saw the mail sheet.");	
		// Hit cancel button.
		cell.waitForInvalid();
		target.tap({ x:28, y:42 });
		// Hit "Delete Draft."
		target.delay(1);
		var deleteDraftButton = application.actionSheet().buttons()["Delete Draft"];
		application.actionSheet().buttons()["Delete Draft"].tap();
		deleteDraftButton.waitForInvalid();
	}
	
	navigateBack();
	hitSearchCancel();
}

function testSuiteMultipleTitles()
{		
	var termsToExpectedValues = {
		"Bloembergen": {
			"unit": "CADM / OPR / OGB / Univ Profs\nFAS / FCOL / Pforzheimer-Oth",
			"title": "Gerhard Gade University Professor, Emeritus\nHonorary Associate of Pforzheimer House"
		}, 
		"darnton": {
			"unit": "CADM / OPR / OGB / Univ Profs\nCADM / Prov / OPR / Provost Stf",
			"title": "Carl H. Pforzheimer University Professor\nDirector of the Harvard University Library"
		}, 
		"galison peter": {
			"unit": "CADM / OPR / OGB / Univ Profs\nFAS / FCOR / Soc of Fllws-Oth",
			"title": "Pellegrino University Professor\nSenior Fellow of the Society of Fellows"
		}, 
		"henry louis gates": {
			"unit": "CADM / OPR / OGB / Univ Profs\nFAS / FCOR / Du Bois Inst-Oth Acad",
			"title": "Alphonse Fletcher, Jr., University Professor\nDirector of the W.E.B. Du Bois Institute for African and African American Research"
		}, 
		"Stephen Greenblatt": {
			"unit": "CADM / OPR / OGB / Univ Profs",
			"title": "Cogan University Professor"
		},
		"oscar handlin": {
			"unit": "CADM / OPR / OGB / Univ Profs",
			"title": "Carl M Loeb University Professor, Emeritus" // This guy actually only has one title?
		},
		"Dale Jorgenson": {
			"unit": "CADM / OPR / OGB / Univ Profs\nKSG / Faculty Members",
			"title": "Samuel W. Morris University Professor\nMember of Faculty"
		},
		"Barry Mazur": {
			"unit": "CADM / OPR / OGB / Univ Profs\nFAS / FCOL / Cabot-Oth\nFAS / FCOR / Soc of Fllws-Oth",
			"title": "Gade University Professor\nAssociate of Cabot House\nSenior Fellow of the Society of Fellows"
		}		
	};

	runSearchTestSuite("Test suite: Multiple titles", termsToExpectedValues);			
}

// "Main" block.

// Provide a default grace period in seconds for each action to complete.
target.setTimeout(0.5);
navigateToPeopleView();

// These have to be watched (literally, meaning visually) by the test runner.
testSuiteActionsFromPersonDetails();
testSuite4();
testSuite5();

// You might want to watch a few of these to make sure the display is not messed up.
testSuiteMultipleTitles();

// These should work without supervision.
testSuiteFieldsSeparatedByNewLine();
testSuite1();
testSuite2();
testSuite3();

// Don't have time to automate this at the moment, but you should look at addresses for the following people each regression check:
// Leonard Wisniewski
// Judith Murciano
// David Carrasco
// Rustam Ibragimov

