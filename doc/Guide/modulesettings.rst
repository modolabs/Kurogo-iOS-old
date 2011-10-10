#################
Settings Module
#################

The Settings module contains several sections that allow the user to change
certain settings within the app. These settings are configured in the file
*Settings.plist* in *Supporting Files*.

Currently the configurable settings are

* *Font* - the default font to use throughout the application.
* *FontSize* - the default font size to use throughout the application.
* *PrimaryModules* - the order and visibility of primary modules on the home
  screen.
* *SecondaryModules* - the order and visibility of secondary modules on the
  home screen.

Additionally, two settings are not configurable but will appear depending on
context:

* *Login* - if the user is logged in, there will be an option to log out.
* *Servers* - if the app is built in debug mode, there will be a section to 
  select which server the application is communicating with.

