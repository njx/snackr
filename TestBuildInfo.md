## Info on test builds ##

Builds with TEST in the version number are builds that haven't been tested much by me or other people. If you're willing to try them out, please do--since I don't have a QA staff, that's the only way I'll find out whether they work!

Before you install a test build, you should either back up your existing Snackr database, or at least export your current feed list, so if your database goes south you can at least get all your feeds back. If you plan to enable Google Reader integration, make sure you back up your Google Reader settings by exporting your feed list to an OPML file.

**To back up your database**, just go into your My Documents (Windows) or Documents (Mac) folder, look for the Snackr subfolder, and copy the FeedDatabase.sql file somewhere safe. To restore the database, just quit Snackr, copy the file back into the Documents/Snackr folder, and restart Snackr.

**To export your feeds**, click the Export button at the bottom of the Feeds tab of the Options popup. To reimport your feeds, use the Import button.

**To back up your Google Reader feeds**, log in to your Google Reader account and click the "Settings" link in the upper right corner. Then choose "Import/Export" and click on the "Export your subscriptions to an OPML file" link. If something goes wrong, you can re-import your feeds into Google Reader by selecting this OPML file with the "Browse" button under the "Import your subscriptions" sections of this same page.

If you run into any problems, please [file a bug](http://code.google.com/p/snackr/issues/entry) and note which version you found the bug in. Thanks!