## Release notes for v0.38 TEST build ([click to download)](http://snackr.googlecode.com/files/Snackr-v0.38-TEST.air) ##

If you're upgrading from the 0.33 official release, see also the [v0.34 release notes](http://code.google.com/p/snackr/wiki/ReleaseNotes_0_34_TEST) and the [v0.35 release notes](http://code.google.com/p/snackr/wiki/ReleaseNotes_0_35_TEST).

**IMPORTANT**: Before installing a test build, please [back up your feed database AND your Google Reader feed list](http://code.google.com/p/snackr/wiki/TestBuildInfo)!

  * Added initial version of Google Reader integration (by Rob Adams)--woohoo! This keeps your feed lists and read items synchronized between Reader and Snackr. You can set this up from the Getting Started popup, or go to the Options Popup and click on the Google Reader tab. Some caveats:
    * **If you delete a feed in Snackr, it will automatically be deleted in Reader as well** (and if you add a feed in Snackr, it will get added to Reader too). We plan to make this optional in the future.
    * If you have a lot of feeds or read items in Google Reader, the ticker may stutter a bit after you first connect as it synchronizes everything.
    * Items from your Reader feeds won't show up until a couple minutes after you first connect (if the ticker is already running when you connect).
    * **NOTE**: Starred items are not yet being synced with Google Reader.
    * Actions you take in Snackr like reading items or adding/deleting feeds will show up in Google Reader more or less immediately; actions you take in Google Reader will take a bit longer to show up in Snackr, since Snackr polls Reader every ten minutes or so.
    * If you downloaded the 0.37 version, the functionality in this version is basically the same, but adds a few warnings to make it clearer that the feed lists in Google Reader and Snackr are synchronized, so deleting feeds in Snackr deletes them in Reader as well.
  * Added a copy/post menu in the item popup (the arrow icon next to the star) to let you copy the item URL to the clipboard, email it, post it to del.icio.us/digg, or make a short URL. Future versions will make this extensible so you can add your own commands.
  * Snackr now minimizes to the system tray (Windows)/dock (OS X) by default. To get the old collapsing behavior back, uncheck the option in the Preferences tab of the Options popup.
  * You can now horizontally resize Snackr when it's vertical (thanks Matthew Boedicker). You can't resize it when it's horizontal yet.
  * Many bugfixes: see [this list](http://code.google.com/p/snackr/issues/list?can=1&q=fixedafter:0.35&colspec=ID%20Type%20Status%20Priority%20FixBy%20FixedAfter%20Owner%20Summary).