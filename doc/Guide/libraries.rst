###################
Standard Libraries
###################

The Common group includes many classes that take care of handling data from the
Kurogo server, data stored locally, commonly used views, and other common tasks.


-------------
Cocoa
-------------

This group consists of category methods added to common classes in Foundation
and UIKit. See the files Foundation+KGOAdditions.h and UIKit+KGOAdditions.h for
currently defined methods.

Below are methods used frequently throughout the app

* *NSDictionary* includes several wrappers around *-objectForKey:* that check
  for the object type and return a falsy or default value if the type is 
  incorrect. These methods are used mostly when results returned by the REST 
  API, which can for many reasons be different from the expected types.

  * *-stringForKey:* - returns nil if the key does not exist, or the matching 
    object is not of type NSString.
  * *-nonemptystringForKey:* - a stricter version of -stringForKey:, this 
    returns nil if the key does not exist, the matching object is not of type
    NSString, or the object is an empty string.
  * *-numberForKey:* - returns nil if the matching object is not of type 
    NSNumber.
  * *-boolForKey:*, *-integerForKey:*, and *-floatForKey:* - returns boolean,
    integer, or float values if the object, regardless of type, can be 
    converted into boolean, integer, or float.
  * *-dictionaryForKey:*, *-arrayForKey:* - returns an NSDictionary or NSArray
    respectively if the key exists and the object type matches.

* *UIImage* methods

  * *-imageWithPathName:* - selects asset files in the order specified in 
    :ref:`xcodelayout-resources`.
  * *-blankImageOfSize:* - creates a blank image.

-------------
Connection
-------------

See :doc:`server` for details.

-------------
Core Data
-------------

This group provides the singleton object, *CoreDataManager*. which is 
initialized during app launch and manages many independent Core Data models 
declared by separate modules. Commonly used methods include:

* *-insertNewObjectForEntityForName:* - a wrapper around 
  :kbd:`[NSEntityDescription insertNewObjectForEntityForName:]`. Use this to
  instantiate NSManagedObject subclasses.
* *-objectsForEntity:matchingPredicate:sortDescriptors:* - Fetches
  NSManagedObjects matching the given predicate and sorted by the given 
  descriptors.
* *-uniqueObjectForEntity:attribute:value:* - Fetches a single NSManagedObject 
  whose attribute named after the given attribute matches the given value.
* *-deleteObjects:* - Deletes an array of NSManagedObjects.
* *-deleteObject:* - Deletes a single NSManagedObject.
* *-saveData* - Commits all changes since the last time this method was called.

See CoreDataManager.h for more details and methods.

.. _libraries-search:

-------------
Search
-------------

Because Kurogo has the concept of federated search, all modules that wish to
participate in federated search must return results in a similar way. The
protocols defined in KGOSearchModel.h are meant for this purpose.

The *KGOSearchResult* protocol is implemented by the unit objects in the People
module (by KGOPersonWrapper), the Calendar module (by KGOEventWrapper), the Map
module (by KGOPlacemark), the News module (by NewsStory), and the Video module 
(by Video), This protocol requires that all objects return 

* an *identifier*
* a *title*
* whether or not it *isBookmarked* by the user, as well as ways to 
  *addBookmark* and *removeBookmark*
* the *moduleTag* of the module where it came from,

Usually the unit object will also implement the *-didGetSelected:* method, in 
which the object usually asks its parent module to show a detail screen for
the selected object.

The search life cycle is mostly accomplished together by the module object (the 
object that subclasses KGOModule) and an instance of 
*KGOSearchDisplayController*, which may associated either with the search bar
on the home screen, or a search bar within a particular module.

For modules that participate in search, the KGOModule object must implements 
the methods

* *-supportsFederatedSearch*
* *-performSearchWithText:params:delegate*

When the module receives results, it will generally pass the results directly
to the delegate from *-performSearchWithText:params:delegate:* which is an
instance of *KGOSearchResultsHolder* (whose name implies that it knows how to 
handle a list of search results).

-------------
Social Media
-------------

This group contains classes that interact with social media services. Currently
the external services supported are Facebook and foursquare.

Facebook
^^^^^^^^^

The singleton KGOFacebookService object is accessed by calling ::

    [KGOSocialMediaController facebookService]

KGOFacebookService currently supports the following method:

* *-shareOnFacebook:prompt:* - calls Facebook's *dialog* API to show the user
  a dialog asking whether they wish to share the attached media.

foursquare
^^^^^^^^^^^

The existing foursquare methods are implemented in KGOFoursquareEngine, which
can be accessed by calling ::

    [[KGOSocialMediaController foursquareService] foursquareEngine]

KGOFoursquareEngine supports a limited set of foursquare actions, including:

* *-checkinVenue:delegate:message:* - performs a foursquare "checkin" to the
  specified venue, with a optional message attached. All checkins are public.
* *-checkUserStatusForVenue:delegate:* - queries foursquare for users who are 
  currently checked in the specified venue.

For more information see the KGOFoursquareEngine.h file.

KGOShareButtonController
^^^^^^^^^^^^^^^^^^^^^^^^^

Called KGOShareButtonController because it is most often invoked from a button
in the UI, this class is used in several modules to show the user an action
sheet where they select one of the provided sharing methods (Email, Facebook)
to share an article or URL.

An example of how to use this class from within a UIViewController follows. ::

    KGOShareButtonController *sbc = nil;

    sbc = [[[KGOShareButtonController alloc] initWithContentsController:self] autorelease];
    sbc.shareTypes = KGOShareControllerShareTypeEmail | KGOShareControllerShareTypeFacebook;
    sbc.actionSheetTitle = @"Share this article?";
    sbc.shareTitle = @"An interesting article";
    sbc.shareURL = @"http://interesting-article.net";
    sbc.shareBody = @"This is an interesting article!";
    [sbc shareInView:self.view];




