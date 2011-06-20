####################
Setup and Building
####################


===================
System Requirements
===================

* A server running Kurogo Mobile Web v1.1 or later.  While it is possible to 
  run Kurogo iOS apps without an associated Kurogo server, functionality at 
  this point is extremely limited.

* Xcode 4.x.  Applications can still be built using Xcode 3, but 
  setting may need to be changed for dependencies to be linked properly.

* iOS SDK 4.0 or above.  The latest iOS SDK is recommended.

===========================
Building the Sample Project
===========================

Kurogo iOS comes with the sample project Universitas.  To build this 
project, the git submodules in the repository must all be included.  Git 
submodules can be downloaded from the Kurogo-iOS source root in the 
Terminal and typing

| :kbd:`git submodule init`
| :kbd:`git submodule update`

-----------------------------
Configuring for Kurogo server
-----------------------------

In Xcode 4, open *Projects/Kurogo.xcworkspace*.  In the file navigator, 
find and select Config.plist in the Resources folder.  Expand the options 
in Servers and enter the address of the appropriate Kurogo Mobile Web server 
as the value of Host.

For shared projects, it is sometimes convenient to change host locations 
without committing changes to the git repository.  For this purpose, server 
names may be set up in Resouces/secret/Config.plist.

--------------------------
Creating a Release build
--------------------------

Under the Build Scheme menu, select the scheme for Universitas and Edit 
Scheme.  Make sure each build step is set to use one of the Release 
configurations.  The included configurations affect which server (as 
specified in Config.plist) is used.

Click OK.  The project should now build normally.

--------------------------
Creating a Debug build
--------------------------

Under the Build Scheme menu, select Manage Schemes.  Duplicate the 
Universitas scheme, giving it a descriptive name like 
"Universitas - Debug - Testing".  Edit this scheme and make sure each 
build step is set to use one of the Debug configurations.

When building for a Debug scheme, Xcode does not automatically place static 
libraries in the correct location.  Thus, each static library needs to be 
built separately before building the main project.  This can be done by 
selecting the build schemes for each individual project and building.



