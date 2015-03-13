## Release notes for v0.39 TEST build ([click to download)](http://snackr.googlecode.com/files/Snackr-v0.39-TEST.air) ##

If you're upgrading from the 0.33 official release, see also the [v0.34 release notes](http://code.google.com/p/snackr/wiki/ReleaseNotes_0_34_TEST), the [v0.35 release notes](http://code.google.com/p/snackr/wiki/ReleaseNotes_0_35_TEST), and the [v0.38 release notes](http://code.google.com/p/snackr/wiki/ReleaseNotes_0_38_TEST).

**IMPORTANT**: Before installing a test build, please [back up your feed database AND your Google Reader feed list](http://code.google.com/p/snackr/wiki/TestBuildInfo)!

  * Added option to make Snackr not show up in the taskbar on Windows. You can uncheck this from the Preferences tab in the Options popup.
  * Added option to auto-start Snackr at login (also in the Preferences tab).
  * Added option to always show newest items across all feeds, rather than picking random feeds to show the newest items from. This is intended for use by people who always want to see the absolute latest stuff that comes in.
    * If you choose this, you should probably reduce the feed check interval in the Feeds tab of the Options popup as well.
    * Note that for feeds that don't do a good job of timestamping, or feeds that update very often, you'll end up seeing large clumps of items from the same feed.
  * Fixed bugs:
    * #6: Behavior when only a few items are available is weird
    * #38: Feed list isn't sorted alphabetically when Options popup opens
    * #51: Some feeds are broken in Snackr
    * #121: Popping up items from particular feeds is very slow
    * #134: Importing OPML file into Snackr on initial startup doesn't wait for feeds to load