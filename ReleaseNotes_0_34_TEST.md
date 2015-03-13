## Release notes for [v0.34 TEST build](http://snackr.googlecode.com/files/Snackr-v0.34-TEST.air) ##

Before installing a test build, please [back up your feed database](http://code.google.com/p/snackr/wiki/TestBuildInfo)!

  * Implemented ability to "star" items so you can read them later. Click the star icon in the item popup to star an item, then read starred items by clicking the star icon in the ticker tab.
  * Added option to configure feed fetch interval globally (#54). This is at the bottom of the Feeds tab in the Options popup. You can also force all feeds to get refreshed here.
  * Added option to set transparency of ticker window (#55). This is in the Preferences tab of the Options popup.
  * Fixed #1: Snackr is not always-on-top on first launch even though it's set that way by default in prefs
  * Fixed #2: Snackr seems to think some English titles have non-Western chars and falls back to Verdana when it shouldn't (e.g. NYTimes headlines)
  * Fixed #27: Code cleanup: Popup should auto-hide managed children on init (right now all children have to have visible="false" set manually)
  * Fixed #36: Snackr creates invalid referrers in logs
  * Fixed #50: Mac OS X: icon is too big next to other dock icons
  * Fixed #52: Autoupdate is only checking on startup, not every hour like it's supposed to
  * Fixed #67: Pause the ticker on mouseover
  * Fixed #118: (@rel="alternate") causes an error to be thrown (thanks Justin Patrin)
  * Fixed #119: Some "atom" feeds apparently do not have @rel="alternate" (thanks Justin Patrin)