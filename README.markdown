# Kurogo

Kurogo is a framework for delivering high quality, data driven
customizable content to a wide range of mobile devices. Its strengths
lie in the customizable system that allows you to adapt content from a
variety of sources and easily present that to mobile devices from
feature phones, to early generation smart phones, to modern devices
and tablets.

This is the native iOS portion of the Kurogo framework. It is meant to
be used in conjunction with a server running 
[Kurogo Mobile Web](https://github.com/modolabs/Kurogo-Mobile-Web)

## NOTICE: Pre-release version

This project is in a pre-beta stage, with the first beta scheduled in
mid April.  Please be aware that certain conventions, API and file
locations may change. We will strive to provide detailed release notes
when critical core behavior has been altered.

## Building the project

### Requirements

Building the project requires Xcode 4 and iOS SDK 4.2 or above.

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

### Secret files

Many apps will include secrets (passwords, API keys, etc.) that should
not be committed to a public repository. This is done in Kurogo by
using a secret .plist file to override public configuration settings,
as follows:

1. In your project's Resources directory, make a directory called
   secret (if it doesn't already exist).

2. Copy Config.plist from your project root into secret.

3. Remove all the dictionary entries that do not need to be secret.

4. Add or modify any dictionary entries with secret values.

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
