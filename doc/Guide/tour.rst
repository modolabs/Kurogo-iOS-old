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

===========
Application
===========

The files in this group control the overall life cycle of the application. The 
following classes are in files (header and implementation) in the top-level 
directory of Kurogo:

* *KGOAppDelegate* - the file that implements UIApplicationDelegate.
* *KGOModule* - the superclass of all modules.
* *KGONotification* - a wrapper around local and push notifications.

===========
Common
===========

This group includes groups of utility classes, common data management classes,
and various custom views.

===========
Contrib
===========

This directory is meant for external code libraries. Currently used libraries 
are

* JSON
* Facebook
* GoogleAnalytics

======================
Indexing Headers
======================

These are headers for external libraries included in the project. To add static 
library source code, include the .xcodeproj associated with the library and
drag the public headers into this group.  When prompted for target membership,
make sure all checkboxes are unchecked.  In the library's build settings, set
all header files to "project" (as opposed to "public" or "private").

These steps are not necessary for external libraries that do not include source 
code. For those, just include the built product and header files in Contrib.

===========
Modules
===========

This group contains default implementations of modules shipping with 
Universitas.  Projects add their own modules to the Modules group under the 
Site group.

===========
Resources
===========

This group contains default assets (such as images) that are embedded in the
application. Images that exist in the Site/Resources group will override 
images in this group.

=================
Supporting Files
=================

This group is for standard files required by iOS projects that do not vary
across applications. Currently this just includes main.m.

===========
Site
===========

Each project requires an Xcode project file (.xcodeproj) and a directory 
to hold project-specific code, configurations, and resources. Subgroups of this
group are the following.

-------------
Application
-------------

This group contains the files for the category *KGOModule (Factory)*.

The file *KGOModule+Factory.m* must import every Module file used in the 
application, and define a mapping between module ID's returned by the server
and the Module class to instantiate.

For example, an application with a home screen showing the People and News 
modules could have a *KGOModule+Factory.m* file like the following: ::

    #import "KGOModule+Factory.h"
    #import "KGOModule.h"
    #import "HomeModule.h"
    #import "NewsModule.h"
    #import "PeopleModule.h"

    @implementation KGOModule (Factory)

    + (KGOModule *)moduleWithDictionary:(NSDictionary *)args {
        KGOModule *module = nil;
        NSString *className = [args objectForKey:@"class"];
        if (!className) {
            NSDictionary *moduleMap = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"HomeModule", @"home",
                                       @"NewsModule", @"news",
                                       @"PeopleModule", @"people",
                                       nil];
            
            NSString *serverID = [args objectForKey:@"id"];
            className = [moduleMap objectForKey:serverID];
        }

        if (className) {
            Class moduleClass = NSClassFromString(className);
            if (moduleClass) {
                module = [[[moduleClass alloc] initWithDictionary:args] autorelease];
            }
        }
        
        if (!module) {
            DLog(@"could not initialize module with params: %@", [args description]);
        }
        
        return module;
    }

    @end

If your application uses a different module for News, e.g. SiteNewsModule, 
your file would import SiteNewsModule.h and map the "news" key to 
"SiteNewsModule" instead.

----------
Modules
----------

This group is for custom modules, subclassed modules, and module files that are
specific to the project.

-----------
Resources
-----------

This group contains assets embedded in the application, such as images. It 
contains the following folder references:

* *common* - application-wide assets.
* *modules* - assets used by a specific module.
* *ipad* - contains *common* and *modules* subfolders for assets that should
  be used instead when the interface is iPad.

Images are chosen via the function ::

    [UIImage imageWithPathName:myPathName]

where *myPathName* is either "common/some-image.png" or 
"modules/people/some-image.png" (the png extension is optional for some 
versions of iOS).

When building for iPad, images that match the path name *ipad/myPathName* have
highest priority, followed by *myPathName*, followed by *kurogo/myPathname* 
(in the top-level Resources group). When building for iPhone, the same rules
apply except the ipad folder is not searched.

-----------------
Supporting Files
-----------------

This group contains several .plist files that are used to store configurations.

* *KGOInfo.plist* is the standard Info.plist used in every application. More
  information is available in the `iOS documentation <http://developer.apple.com/library/ios/#documentation/general/Reference/InfoPlistKeyReference/Articles/AboutInformationPropertyListFiles.html>`_

* *Config.plist* is used for Kurogo-specific configurations.  See 
  :ref:`config-options`.

* *ThemeConfig.plist* contains theme values that determine various fonts and
  colors in the application.

* *ThemeConfig.plist-iPad* (optional) is used when different theme values 
  should be used for iPad builds.


There is a folder called *secret* which may contain an un-versioned copy of 
Config.plist.  See :ref:`config-secret`.

-------------
Localization
-------------

This group holds all localized/localizable assets, such as Localizable.strings
and plist files with user-facing strings.






