#################
Overview
#################

Kurogo iOS is the iOS counterpart of Kurogo Mobile Web. It features a similar
set of modules and displays data from the same data sources, but uses fully
native iOS SDK components to build iPhone/iPad apps that can be distributed 
in-house or through the iTunes App Store.

Kurogo is available under a liberal open source MIT license. This mean you 
are free to download, install, copy, modify and use the software as you see 
fit.

==========================
Mobile Web REST Additions
==========================

Kurogo iOS apps are intimately tied to a server running Kurogo Mobile Web.
The Mobile Web component includes a REST API required for most modules.
See the Mobile Web documentation for `instructions <http://modolabs.com/kurogo/guide/apimodule.html>`_ 
on enabling REST API output for modules.

=======
Modules
=======

Modules are the core building block of any Kurogo application. Modules are 
contained pieces of code that (typically) connect to external services and 
process data for display.

To the user, modules behave like autonomous applications bound together by the
overall application infrastructure.

On the web, the life cycle of a module involves fetching data from a raw data
source, parsing and processing the data into the desired pieces that the user
requested, and displaying the data in a template based on the user's device.

In the iOS framework, modules are minimally instantiated at application launch,
but when engaged by the user, they perform the roles of selecting views to 
render and data controllers to initialize. Data sources consist primarily of 
the Kurogo REST API, though external sources like social media may be involved.
