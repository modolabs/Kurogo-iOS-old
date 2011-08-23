#########
Theming
#########

Currently there are two parts to theming: assets, and overall 
look-and-feel specifications.  The former are placed into the project's 
*Resources* directory; the latter in ThemeConfig.plist.

In a Kurogo Xcode project, the Resources directory is included as a group 
where each member is a folder, matching the following layout:

*Resources/*

    *common/*      - references <project-path>/Resources/common

    *modules/*     - references <project-path>/Resources/modules

    *ipad/*        - references <project-path>/Resources/ipad (optional)

        *common/*

        *modules/*

    *kurogo/*      - references ../Resources/default/kurogo

        *common/*

        *modules/*

In code, images must be referenced using the category method [UIImage
imageWithPathName:], instead of [UIImage imageNamed:].  This will
search for images in the following order.

1. If the app is on iPad and a corresponding file exists in the ipad
   folder, use that.

2. Otherwise if a corresponding file exists with the exact name
   (common/myfile or modules/mymodule/myfile), use that.

3. Otherwise, use the default asset in the kurogo folder.
