#################
Login Module
#################

For apps that require authentication, the Login module provides the interface
and key steps in the process of authenticating users.

Unlike all other modules, whose view controllers are handled by the 
:ref:`Application Delegate <xcode-application-group>` object, the login module
is handled as a special case by :ref:`kgorequestmanager`. The login process
ends when an appropriate :ref:`session <server-login>` is set, and the login
module dismisses itself by way of notifications from the request manager.

The only user interface for logging out is currently provided via the 
:doc:`modulesettings`.

