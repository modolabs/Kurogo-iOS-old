####################
Setup and Building
####################


===================
System Requirements
===================

* A server running Kurogo Mobile Web v1.3 or later.

* Xcode 4.0 or above, including the iOS SDK (4.0 or above).

=====================
Getting the Code
=====================

The current Kurogo iOS framework depends on two extenral libraries that are
also versioned using git. Thus, to check out the source code including all
dependencies from the terminal, type the following:

| :kbd:`git clone git://github.com/modolabs/Kurogo-iOS.git`
| :kbd:`cd Kurogo-iOS`
| :kbd:`git submodule init`
| :kbd:`git submodule update`

===========================
Building the Sample Project
===========================

From Xcode, open */path/to/Kurogo-iOS/Projects/Kurogo.xcworkspace*. Do not open
the individual .xcodeproj files.

Under the Build Schemes drop down menu, make sure the *Universitas* target is
selected (instead of one of the dependencies like facebook or json), and 
select "build" or "run". This will build Universitas into the selected 
simulator or device.

-----------------------------
Configuring for Kurogo server
-----------------------------

When building the Universitas app without modification, the app will launch and
show an alert about failing to connect to the server. The location of a working
server needs to be specified in Config.plist (under "Supporting Files" in the
project), or in *secret/Config.plist*. *secret/Config.plist* is a git-ignored
file whose settings override those in the versioned Config.plist. See 
:ref:`config-secret` for more information.

In Xcode, open Config.plist and expand the *Servers* key. The default 
configuration assumes four servers: development, testing, staging, and 
production. If there are fewer than four servers, it is easiest to just repeat
the same settings multiple times.

Each server has the following options:

* *APIPath* - the relative path of the REST API. For example, if REST APIs
  have URLs like http://kurogo.com/rest/people/search?q=john, put *rest* here.
* *Host* - the server domain name with no relative paths or trailing slashes,
  e.g. *example.com*.
* *PathExtension* - if the Kurogo instance is in a relative URL, put the 
  relative path here. For example, if Kurogo runs off a URL of 
  http://example.com/extension, put *extension* here.
* *UseHTTPS* - whether or not the Kurogo instance uses HTTPS.

---------------------------------
Servers and Build Configurations
---------------------------------

Kurogo comes with three build configurations: *Debug*, *Staging*, and 
*Release*. Debug and Release follow general conventions (e,g, Debug uses less 
optimization, Release is signed with the Distribution certificate); Staging is 
identical to Release except for the Kurogo server it hits. Apps built under the 
Release configuration hit the Production server configured in Config.plist, 
while Staging hits the Staging server in Config.plist.

In Debug builds, users may change the current server via the Settings module if
it is enabled in the app.  The server can determine whether an app is a debug
build by the presence of the *debug* parameter in API requests.

