####################
External URL Module
####################

The External URL module does not return any view controllers, but tells the
application to open a specified URL in the device's native web browser.

The URL to be opened by this module is set in the *payload* parameter in its
:ref:`initialization options <config-modules>`. The format of the payload is
a dictionary as follows: ::

    <dict>
        <key>url</key>
        <string>http://external-site.com</string>
    </dict>


