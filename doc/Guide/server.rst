###############################
Communicating with the Server
###############################

Almost every module in Kurogo requires some communication with a Kurogo server
instance. The classes *KGORequestManager* and *KGORequest* are of note.

============================
General REST API connection
============================
-----------------------------
The KGORequestManager object
-----------------------------

Because the REST API output has a standard structure and requires standard 
parameters, *KGORequestManager* is a singleton object that performs many of the 
steps involved in generating requests and parsing responses.

Methods of note:

* *-requestWithDelegate:module:path:version:params* - This is the factory
  method that generates :ref:`server-kgorequest-object`.

  Example: ::

    NSDictionary *params = [NSDictionary dictionaryWithObject:@"john" forKey:@"q"];
    KGORequest *request = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                          module:@"people"
                                                                            path:@"search"
                                                                         version:1
                                                                          params:params];
    [request connect];

* *-isReachable* - This method is a wrapper around 
  `Apple's Reachability code <http://developer.apple.com/library/ios/#samplecode/Reachability/Introduction/Intro.html>`_
  that determines whether the app is currently able to establish a connection 
  to the associated Kurogo server using any network method.

.. _server-kgorequest-object:

----------------------
The KGORequest object
----------------------

Each KGORequest object is associated with the URL that it is requesting, the
type of object expected in the response, and an action to perform after a
response is received. Note that one of the *-connect...* methods must be called
to actually establish a connection with the server.

--------------------------------
The KGORequestDelegate protocol
--------------------------------

All KGORequest objects should be associated with an object that implements the
KGORequestDelegate protocol, which tells the request what to do when it 
receives an expected or unexpected response.

See the KGORequest.h file for specific properties and methods in KGORequest, as 
well as the methods in KGORequestDelegate.

=============
Notable APIs
=============

Interacting with the REST API should be similar across modules, but two 
endpoints are worth noting because they affect all modules.

.. _server-hello:

------
Hello 
------

The only REST URL with no module component, this is the first endpoint the app 
requests when it is started. A successful response will return a dictionary 
that includes an array identified by *modules*. Each item in the *modules*
array has the same structure as each item in the :ref:`config-modules` config 
section, and each key will be interpreted the same way by the app.

In addition to the keys in the :ref:`config-modules` config section, the 
*hello* API also returns the following keys for each module:

* *access* - a boolean value indicating whether the user is currently 
  authorized to view data from this module.
* *vmin* - the lowest API version the module supports on the server.
* *vmax* - the maximum API version the module supports on the server.

If the *hello* request encounters a module that has an *access* value of false,
the app will attempt a server login. This assumes that the Login module is 
enabled on the server.

.. _server-login:

------
Login
------

Because Kurogo uses login credentials that are often managed by external 
services, the app attempts a login by displaying a web view that requests the
URL of Kurogo's Login module on the mobile web. After the user enters 
credentials, the app requests the Session API to see if the appropriate 
credentials have been set. The existence of a user session is determined by the 
server using cookies saved during the login process.

If the user attempts to use a module without proper credentials, they can see 
the regular user interface of the module, but no new data can be retrieved.

