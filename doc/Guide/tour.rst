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
* scripts
* tests
* xcconfig
* xctemplate

Of these *Application*, *Common*, *Contrib*, *Modules*, *Resources*,
and *xcconfig* are included in every Kurogo project.

*Projects* contains the sample starter project, the default workspace, 
and is meant to contain any new projects derived from the framework.

Each of these directories is described in detail below.

-----------
Application
-----------


------
Common
------


------
Config
------


-------
Contrib
-------

This directory is meant for external code libraries. Currently used libraries 
are

* JSON
* Facebook
* GoogleAnalytics

-------
Modules
-------

This directory contains default implementations of modules shipping
with Universitas.  Projects add their own modules to the Modules
subdirectory inside the project directory.

--------
Projects
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






