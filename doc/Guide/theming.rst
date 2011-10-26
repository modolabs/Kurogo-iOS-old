#########
Theming
#########

Currently there are two parts to theming: assets, and overall 
look-and-feel specifications.  The former are placed into the project's 
*Resources* directory; the latter in ThemeConfig.plist.

==========
Resources
==========

The Site/Resources group in Xcode has the following folders

* *common/* 
* *modules/* 
* *ipad/* (optional)

  * *common/*
  * *modules/*

In code, images must be referenced using the category method [UIImage
imageWithPathName:], instead of [UIImage imageNamed:].  This will
search for images in the following order.

1. If the app is on iPad and a corresponding file exists in the ipad
   folder, use that.

2. Otherwise if a corresponding file exists with the exact name
   (common/myfile or modules/mymodule/myfile), use that.

3. Otherwise, use the default asset from the framework.

====================
Theme Configuration
====================

Theme configuration is done in *ThemeConfig.plist* under the project's 
*Supporting Files* group/directory. Universal apps with differing themes for 
the iPhone and iPad will use two files, *ThemeConfig.plist* and 
*ThemeConfig-iPad.plist*. The two files have identical parameters.

Besides :ref:`home-screen-configuration`, ThemeConfig has the following 
configuration sections:

------
Fonts
------

This is the largest section in ThemeConfig. Besides *DefaultFont* and 
*DefaultFontSize*, each font label is mapped to a dictionary that may include 
the following optional values:

* *color* - the font color in hex format.
* *font* - the name of the font (e.g. Helvetica).
* *size* - an number specifying the size of the font relative to the default. 
  Positive values mean this font is larger than the default, for example 2 
  means this font is 2 point sizes larger than the default. Negative values are
  smaller than the default. Zero is the same size as the default.

If *font* is missing, the value of *DefaultFont* is used. If *size* is missing,
the font will have a size of *DefaultFontSize*. If *color* is missing, the font
will be black.

Currently the following font labels include the following.

* *BodyText* - general paragraphs and default font where unspecified.
* *SmallPrint* - general purpose small text: copyright, table footers, etc.

* *ContentTitle* - large title in detail pages where the background is the overall background of the app.
* *ContentSubtitle* - text below ContentTitle.

* *PageTitle* - large title in detail pages where the background is white.
* *PageSubtitle* - text below PageTitle (news deck).  Deck in android.
* *Caption* - text to show below pictures.
* *Byline* - smallprint in news articles.  CSS "byline" class in mobile web.

* *NavListTitle* - default text in UITableViewCell (default and subtitle styles).  List Item - Primary in android.
* *NavListSubtitle* - small print in UITableViewCell.  List item - Secondary in android.
* *NavListLabel* - textLabel in UITableViewCellStyleValue2.  CSS "label" class in mobile web; Label in android.
* *NavListValue* - detailTextLabel in UITableViewCellStyleValue2.  CSS "value" class in mobile web; List Value in android.

* *ScrollTab* - button in scrolling tabstrip.
* *ScrollTabSelected* - active button in scrolling tabstrip.

* *SectionHeader* - section header for plain table view.  SubHead in android.
* *SectionHeaderGrouped* - section header for grouped table view.

* *TabSelected* - active tab in tabbed view.
* *Tab* - inactive tab in tabbed view.


-------
Colors
-------

This section defines colors for some common UI components. All values take hex
strings unless otherwise specified. The following styles are currently defined:

* *AppBaciground* - the default background color for all views other than the 
  home screen. This may be the path to an image.
* *NavBarTintColor* - the tint color of buttons in the navigation bar (not the
  color of the bar itself).
* *NavListSelectionColor* - the background tint color for selected cells in 
  table views. If missing, the background will be blue.
* *PlainSectionheaderBackground* - for plain table views that have section
  headings, this is the background color of the headings.
* *PrimaryCellBackground* - background color for primary list navigation items.
* *SearchBarTintColor* - tint color of buttons in the search bar.
* *SecondaryCellBackground* - backgorund color for secondary list navigation
  items.
* *TableSeparator* - color of lines between navigation items.

-------
Images
-------

This section specifies the path location of assets for some common UI
components. Currently the following are defined:

* *NavBarTitle* - an image to be used as the title in the navigation bar on 
  the home screen.
* *SearchBarBackground* - background image for the common search bar.
* *SearchBarDropShadow* - drop shadow below the search bar, if any.



