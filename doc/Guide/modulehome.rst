##############################
The Home Module (Home Screen)
##############################

For most Kurogo-based apps, the Home Screen is the entry point of the user 
interface. It provides a list of all other modules included in the app, and 
optionally a search bar for federated search across modules.

.. _home-screen-configuration:

==========================
Home Screen Configuration
==========================


Many aspects of the home screen's appearance are configurable in the 
*HomeScreen* section in *ThemeConfig.plist* in the project's *Supporting Files* 
group/directory. Below are options in this section.

----------------
NavigationStyle
----------------

This option specifies the type of home screen (how modules are presented -- 
grid, list etc.). It may take one of five values:

* *Grid* - a springboard-style grid of icons.
* *List* - a linear list of module titles with icons on the left.
* *Portlet* - same as Grid but with custom widgets for modules that have them.
* *Sidebar* (iPad only) - a custom iPad interface with a module list on the 
  left hand side and no navigation controller.
* *SplitView* (iPad only) - a standard split view controller, but with 
  navigation on the right hand side.

The default style is Grid. If an invalid style is selected, e.g. if an 
iPad-only style is selected when the device is an iPhone, the default value of
Grid will be selected.

To configure different interfaces for the iPhone and iPad, include two files 
named *ThemeConfig.plist* and *ThemeConfig-iPad.plist* respectively.

The Portlet and Sidebar interfaces are experimental.

-------------------------
Icon Grid Configurations
-------------------------

For grid-type home screen styles, the following settings determine the 
appearance of module icons:

* *ModuleIconSize* - two integers in "width height" format; specifies the size 
  of each icon in iOS pixels (e.g. "54 50").
* *ModuleLabelFont* - the font, color, and size of title labels below the 
  module icon.
* *ModuleLabelTitleMargin* - integer; spacing between the icon image and title
* *ModuleListMargins* - four integers in "top left bottom right" format (note
  that this is the same argument order as some UIKit functions in iOS, not the
  same as CSS); specifies the margins between the screen edges and the list of
  icons.
* *ModuleListSpacing* - two integers in "horizontal vertical" format; specifies
  the spacing between module icons.

For applications that distinguish between primary and secondary modules, all 
settings above apply only to primary modules. Secondary modules are configured
with the settings *SecondaryModuleIconSize*, *SecondaryModuleLabelFont*,
*SecondaryModuleLabelTitleMargin*, *SecondaryModuleListMargins*, and
*SecondaryModuleListSpacing*. The argument formats are identical to those 
above.

---------------
ShowsSearchBar
---------------

This boolean setting determines whether there is a search bar on the home 
screen, and thereby a user interface for federated search.

----------------
Other settings
----------------

* *BackgroundColor* - the background color of the home screen in hex format. 
  This may also be an image; specify the path of the image to be read by
  [UIImage imageWithPathName:], e.g. modules/home/mybackground.png.



