##################
App Configuration
##################

Each project has two main .plist files that can be found in the 
*Projects/Supporting Files* group: KGOInfo.plist and Config.plist.  
KGOInfo.plist is the standard iOS application's 
`Info.plist <http://developer.apple.com/library/ios/#documentation/general/Reference/InfoPlistKeyReference/Articles/AboutInformationPropertyListFiles.html>`_ file.

Config.plist contains options specific to Kurogo. The keys are described below.

.. _config-options:

====================
Config.plist Options
====================

-------------
Analytics
-------------

For apps that use external analytics libraries, fill in the following keys:

* *Provider* - the name of the external analytics service. Currently "Google"
  is the only supported option. Several analytics service providers have 
  similar interfaces and can be included by extending the AnalyticsWrapper 
  class in Common/Analytics.
* *AccountID* - the account ID used with the service provider.

This section and all keys are optional. However, if there is no analytics 
provider, it is recommended to leave all keys blank for clarity.

-------------
Location
-------------

Whenever a map is displayed with no annoatations, this value determines the
extent to be shown. The following keys are required:

* *DefaultCenter* - a string in latitude, longitude decimal format specifying
  the map's center coordinate.
* *DefaultZoom* - an integer specifying the map's initial zoom level using 
  Google-style zoom levels (powers of 2 up to 19; 1 means entire earth)

This section and all keys are strongly recommended.

.. _config-modules:

-------------
Modules
-------------

This section specifies the default list of modules included in the app and the
default module order to be shown on the home screen. Note that the actual
modules in use may be affected by the results of the :ref:`server-hello` and 
:ref:`server-login` APIs.

The list of modules is stored as an array of dictionaries, each of which has
the following keys:

* *id* (required) - a string that determines which module to instantiate. This
  **must** be identical to the module ID returned by the server. Which module 
  to instantiate locally is determined by the dictionary in KGOModule+Factory.m 
* *tag* (required) - a unique key to associate with the instantiated module.
  Since the same module can be instantiated multiple times, they need to be
  distinguished from one another via the tag. The tag **must** be identical to 
  the module's *configModule* property in the server counterpart.
* *title* (requred) - the module's display name.
* *hidden* (optional) - YES if the module should be hidden from the home 
  screen. The default is NO.
* *secondary* (optional) - YES if the module should appear in the secondary
  list of modules on the home screen. The default is NO.
* *payload* (optional) - a custom dictionary of data that the module should be
  able to handle once initialized. Currently the only module with a concrete
  implementation of payload handling is the :doc:`moduleurl`.

This section is required.

-------------
Servers
-------------

This section specifies information about the servers where the Kurogo REST API
resides. It contains settings for up to four servers in a single build: the 
*Development*, *Testing*, *Staging*, and *Production* servers. All four keys 
are required, but the servers need not be unique. For example, an organization 
with two servers can use the same values for Development and Testing, and the 
same values for Staging and Release.

Each server has the following configuration keys:

* *Host* - the server's host name, e.g. *www.example.com*. Must not contain 
  slashes.
* *PathExtension* - the URL path, relative to the host, of Kurogo's root URL. 
  For example, if Kurogo's index is accessible at *www.example.com/kurogo*, use
  *kurogo* for the path.
* *APIPath* - the path relative to Kurogo's root URL where the REST API 
  resides. The default path on a Kurogo server instance is *rest*.
* *UseHTTPS* - whether or not the server should be accessed via HTTPS. When set
  to YES, all connections to the server will use HTTPS.

This section and all keys are required.

-------------
SocialMedia
-------------

This section specifies information to be used with apps that integrate social 
media and sharing. Recognized keys are the following:

* *Email* - include this key if users should be allowed to share items (e.g.
  news articles, videos, events) from the app. If this key is present, the
  user will be shown the device's native mail client when they choose to share 
  an item by email. If this key is not present, the user will not be given
  the option to share items by email, though other parts of the app may use
  email functionality for non-sharing purposes. This key is not associated with
  any additional data.

* *Facebook* - include this key if there should be any Facebook integration in 
  the app. The following information below is also required from a registered 
  Facebook app, which can be created following instructions on the 
  `Facebook developer documentation <http://developers.facebook.com/docs/beta/opengraph/tutorial/#create-app>`_:

  * *AppID* - the app ID of the registered Facebook app.

  To use Facebook's single sign-on system, a URL scheme based on the Facebook
  AppID must be specified in KGOInfo.plist as an item in the CFBundleURLTypes 
  key as follows: ::

    <dict>
        <key>CFBundleURLName</key>
        <string>com.facebook</string>
        <key>CFBundleURLSchemes</key>
        <array>
                <string>fbXXXXXXXXXXX</string>
        </array>
    </dict>

  where XXXXXXXXXXX is the app ID. This step is not necesary for 
  `Facebook dialog <http://developers.facebook.com/docs/reference/dialogs/>`_
  sharing.

* *foursquare* - include this key if there should be any foursquare integration
  in the app. Note that the word "foursquare" begins with a lowercase letter to
  be consistent with the foursquare brandig. The following information is 
  required from a registered foursquare application, which can be created on
  the `foursquare developer site <https://foursquare.com/oauth/>`_.

  * *ClientID* - The client ID of the foursquare app.
  * *ClientSecret* - The client secret of the foursquare app.

.. _config-secret:

==============
Local Settings
==============

Often there will be configuration options that developers wish to override 
without committing such options to version control. Similar to the construction
of `local configuration files <file://localhost/home/sonya/sites/kurogo/doc/Guide/_build/html/configuration.html#local-files>`_
in Kurogo Mobile Web, Kurogo iOS allows settings in Config.plist to be 
overridden on a per-section basis using the file 
*Supporting Files/secret/Config.plist*. To create this file:

1. Locate the *secret* folder in your project's *Supporting Files* 
   group/directory.

2. Make a copy of Config.plist and place it in this directory. This should be 
   done through the filesystem (for example using Finder) instead of Xcode.

3. Remove the dictionary entries that do not need to be changed.

4. Add/modify dictionary entries as necessary.

Developers will most commonly edit the *Servers* section in the local 
Config.plist to work with a local or temporary server. Sensitive information
like passwords may also be stored in this file and read by the code.

