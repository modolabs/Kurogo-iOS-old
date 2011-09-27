#####################
Source Code Layout
#####################

The list of top-level directories in the repository, besides *doc* 
(which contains the markup for this documentation), are:

* Application
* Common
* Contrib
* Modules
* Projects
* Resources
* Supporting Files
* scripts
* tests
* xcconfig

Of these *Application*, *Common*, *Contrib*, *Modules*, *Resources*,
*Supporting Files*, and *xcconfig* are included in every Kurogo project.

*Projects* contains the sample starter project, the default workspace, 
and is meant to contain any new projects derived from the framework.

Each directory (except Kurogo.xcworkspace) under *Projects* contains the
following:

* Application
* Common
* Contrib
* Localization
* Modules
* Projects
* Resources
* Supporting Files
* Config.plist
* KGOInfo.plist

The directories under each project folder obviously and intentionally have 
significant overlap with the top-level directory structure.  Directories with
the same name contain files that are treated as members of the same "group" in
Xcode.

Each Xcode group (including some not listed above) is described in detail 
below.

-----------
Application
-----------

The files in this group control the overall life cycle of the application. The 
following classes are in files (header and implementation) in the top-level 
directory of Kurogo:

* *KGOAppDelegate* - the file that implements UIApplicationDelegate.
* *KGOModule* - the superclass of all modules.
* *KGONotification* - a wrapper around local and push notifications.

------
Common
------

This group includes groups of utility classes, common data management classes,
and various custom views.

-------
Contrib
-------

This directory is meant for external code libraries. Currently used libraries 
are

* JSON
* Facebook
* GoogleAnalytics

-----------------
Indexing Headers
-----------------

These are headers for external libraries included in the project. To add static 
library source code, include the .xcodeproj associated with the library and
drag the public headers into this group.  When prompted for target membership,
make sure all checkboxes are unchecked.  In the library's build settings, set
all header files to "project" (as opposed to "public" or "private").

These steps are not necessary for external libraries that do not include source 
code. For those, just include the built product and header files in Contrib.

-------
Modules
-------

This directory contains default implementations of modules shipping
with Universitas.  Projects add their own modules to the Modules
subdirectory inside the project directory.




--------
Site
--------

Each project requires an Xcode project file (.xcodeproj) and a directory 
to hold project-specific code, configurations, and resources. For example 
the Universitas directory contains

*Application/*

    *KGOModule+Factory.h*

    *KGOModule+Factory.m*

*Config/*

    *Config.plist* - for custom application configurations read by Kurogo.
    These include server names, the list of modules, third-party API keys, etc.

    *KGOInfo.plist* - the Info.plist file associated with the application.
    Standard application configurations go here.

    *[secret/]* - an optional git-ignored directory to place a Config.plist 
    with values that override the required Config.plist

*Localization/* - includes the strings files such as Localizable.strings (used 
throughout the app) and plist files.

    *en.lproj/*

*Modules/* - project-specific module implementations.

*Resources/*

    *common/*

    *modules/*

    *[Default.png]*

    *[Icon.png]*



---------
Resources
---------






