## Release notes for v0.4 test build ([click to download)](http://snackr.googlecode.com/files/Snackr-v0.4.air) ##

**IMPORTANT**: Before installing a test build, please [back up your feed database AND your Google Reader feed list](http://code.google.com/p/snackr/wiki/TestBuildInfo)!

**Changes**
  * Now requires AIR 1.5.3. The AIR runtime update should install automatically.
  * Updated Google Reader integration to use new authentication scheme (Google will be turning off the old authentication scheme on June 15). (Thanks to Rob Adams for the fixes!)
  * Changed Options icon to a gear.
  * feed:// URLs now work.
  * Possible fix for reported intermittent memory leaks when Google Reader integration is enabled.

**Known issues**
  * If Google returns a captcha during the initial login process, Snackr won't show it (it will show captchas in the Options popup). This will be fixed in the next build.