# Kurogo

Kurogo is a framework for delivering high quality, data driven
customizable content to a wide range of mobile devices. Its strengths
lie in the customizable system that allows you to adapt content from a
variety of sources and easily present that to mobile devices from
feature phones, to early generation smart phones, to modern devices
and tablets.

This is the native iOS portion of the Kurogo framework. It is meant to
be used in conjunction with a server running 
[Kurogo Mobile Web](https://github.com/modolabs/Kurogo-Mobile-Web).

## Building the project

### Requirements

Apps built with the Kurogo iOS framework are required to fetch data from a
server running Kurogo Mobile Web version 1.3.

Building the project requires Xcode 4 and above with iOS SDK 4.2 or above.

### Checking out source code and dependencies

This project has several external dependencies that are git
submodules.  To build the included Universitas project, you must have
pulled the submodule sources in addition to the Kurogo source.  To
pull all sources from the terminal, you can use the following
commands:

    $ git clone git://github.com/modolabs/Kurogo-iOS.git
    $ cd Kurogo-iOS
    $ git submodule init
    $ git submodule update

## History

This project is based on
[MIT Mobile for iPhone](https://github.com/MIT-Mobile/MIT-Mobile-for-iPhone)
and contributions from
[Harvard University](https://github.com/modolabs/Harvard-Mobile-for-iPhone).

## Help

More documentation is on the way, but for now please join our 
[Kurogo-Dev](https://groups.google.com/group/kurogo-dev?pli=1) list to find out
more about Kurogo for iOS. You can also email questions directly to 
kurogo-dev@googlegroups.com
