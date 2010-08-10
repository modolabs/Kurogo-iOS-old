// Globals.
target = UIATarget.localTarget();
//application = target.frontMostApp(); 
// Do not cache frontMostApp. For some reason, sometimes this gets the wrong app. Always call frontMostApp right when you need it.
//mainWindow = application.mainWindow();
g_lastSearch = "";
g_searchTestResults = {}; // Key: Search term. Value: Result.

// Utility functions.

function getApp()
{
 	return target.frontMostApp();
}

function getMainWindow()
{
	return getApp().mainWindow();
}

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
function navigateToMapView()
{
	//getMainWindow().logElementTree();
	scrollView = getMainWindow().scrollViews()[0];
	//scrollView.logElementTree();
	peopleDirectoryButton = scrollView.buttons()["maps"];
	peopleDirectoryButton.tap();
}

function navigateBack()
{
	getMainWindow().navigationBar().elements()[0].buttons()["home"].tap();
}

function enterSearchTermIntoSearchFieldAndHitGo(searchTerm)
{
	// Type search term into search field and run search.
	searchBar = getMainWindow().elements()["Campus Map Search Bar"];
	searchBar.tap();
	searchBar.setValue(searchTerm);
	//getMainWindow().logElementTree();
	
	//msg("Is the map view valid? " + getMainWindow().elements()["Map View"].checkIsValid());
	//getMainWindow().elements()["Map View"].waitForInvalid();
	//target.delay(10); // TODO: Find something else to wait for that might be done sooner than a second.
	keyboard = getApp().keyboard();
	buttons = keyboard.buttons();	
	searchButton = buttons["search"];
	searchButton.tap();	
		
	// Will wait up to five seconds for elements to go invalid before allowing the next thing to happen.
	target.pushTimeout(5);		
	searchButton.waitForInvalid(); 
	target.popTimeout();	
}

// Test helpers.

// Tests.

// After this runs, you should end up with a valid map view, or an alert saying nothing was found.
function runSearch(searchTerm)
{	
	// Store the search we're running so that if we get an alert, the alert handler knows to what search the alert refers.
	g_lastSearch = searchTerm; 
	enterSearchTermIntoSearchFieldAndHitGo(searchTerm);
	
	// Find out if we got a search result.
	testResult = false;
	
	// First, check to see if we got an alert that said there were no results.
	alert = getApp().alert();
	// Then, find out if the map view is enabled. It will be if there's a search result.
	mapView = getMainWindow().elements()["Map View"];		
	mapView.logElementTree();
	
	if ((!alert.isValid()) && mapView.isEnabled())
	{
		testResult = true;
	}
	else 
	{
		if (alert.isValid())
		{
			// We need to dismiss the alert.
			// HACK: The alert buttons aren't available to us, so we're just going to tap at the spot the button will be.
			target.tap({ x:120, y:274 });
		}
		else
		{
			// We need to bring the map view back into focus for the next test.
			mapView.tap();					
		}
	}
	
	logTestResult(testResult, searchTerm);	
}


function testSuite()
{	
	runSearch("1737 Cambridge St");	
	runSearch("garbage");	
	runSearch("65 Winthrop St");	
}


// "Main" block.

// Argh. Why won't this get called?
target.onAlert = function onAlert(anAlert)
{
	// TODO: Make sure the alert actually says "no results". Right now, it's the only alert
	// that would come up, though.
	g_searchTestResults[g_lastSearch] = false;
	msg("Received error alert for " + g_lastSearch + ", set result value to " + g_searchTestResults[g_lastSearch]);
	return true; // Let the default UI Automation handler dismiss the alert.
};

//msg("New alert: " + target.onAlert);
// Provide a default grace period in seconds for each action to complete.
target.setTimeout(0.5);
navigateToMapView();

testSuite();
