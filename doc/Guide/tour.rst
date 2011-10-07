#####################
Source Code Layout
#####################

The Kurogo iOS source tree includes the following top-level directories. 
Directories beginning with uppercase letters are included in Xcode projects.
Directories beginning with lowercase letters, except *xcconfig*, are not used
by Xcode.

* Application - files implementing UIApplicationDelegate and the Kurogo module 
  superclass.
* Common - library files used in by multiple modules.
* Contrib - source code and libraries from other projects.
* Modules - source code for each module.
* Projects - project-specific files.

  * Kurogo.xcworkspace - the workspace file to open in Xcode.
  * Universitas - the sample project

    * Application - files that extend those in the top level Application
      directory.
    * Modules - files that extend or add to those in the top level Modules 
      directory.
    * Resources - assets to be used instead of or in addition to those in the
      top level Resources directory.
    * Supporting Files - project configuration files

* Resources - assets such as images, audio, and html templates

  * default - assets used by the default Universitas theme.

* Supporting Files - supporting files, i.e. the precompiled header and main.m
* doc - source files to build this documentation.
* scripts - miscellaneous scripts for use with Kurogo iOS.
* tests - where test-related files should go
* xcconfig - Xcode configuration files. Xcode build configurations that do not 
  need to be target-specific should be set here.

The source code is displayed similarly when viewed in Xcode projects, but with 
subtle important differences, especially directories that are included as 
folder references. See :doc:`xcodelayout` for details.

