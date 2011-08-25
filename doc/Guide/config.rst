##################
App Configuration
##################





-------------
Secret files
-------------

Many apps will include secrets (passwords, API keys, etc.) that should
not be committed to a public repository. This is done in Kurogo by
using a secret .plist file to override public configuration settings,
as follows:

1. In your project's Resources directory, make a directory called
   secret (if it doesn't already exist).

2. Copy Config.plist from your project root into secret.

3. Remove all the dictionary entries that do not need to be secret.

4. Add or modify any dictionary entries with secret values.
