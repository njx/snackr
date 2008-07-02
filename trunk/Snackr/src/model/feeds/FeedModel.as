/*
	Copyright (c) 2008 Narciso Jaramillo
	All rights reserved.

	Redistribution and use in source and binary forms, with or without 
	modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.
    * Neither the name of Narciso Jaramillo nor the names of other 
      contributors may be used to endorse or promote products derived from 
      this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
	USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package model.feeds
{
	import flash.data.SQLColumnSchema;
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLTableSchema;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Timer;
	
	import model.feeds.readers.IFeedReaderSynchronizer;
	import model.feeds.readers.NullFeedReaderSynchronizer;
	import model.logger.Logger;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
		
	[Event(name="feedsUpdated", type="model.feeds.FeedEvent")]
	[Event(name="feedListUpdated", type="model.feeds.FeedEvent")]
	
	/**
	 * The main model class for managing the local database of feeds and items. 
	 */
	public class FeedModel extends EventDispatcher
	{
		/**
		 * How often to check a set of feeds, in milliseconds. We check up to FEED_CHECK_LIMIT feeds at a time,
		 * but only if there are feeds that are ready to check (because we last checked them
		 * more than _feedCheckMinTime minutes ago).
		 */
		static private const FEED_CHECK_TIMER_INTERVAL: Number = 1 * 60 * 1000;
		/**
		 * The default minimum check time for a given feed (see _feedCheckMinTime).
		 */
		static private const DEFAULT_FEED_CHECK_MINIMUM_TIME: Number = 45; 
		/**
		 * How many feeds to check at once every FEED_CHECK_TIMER_INTERVAL. We spread out feed checks so that
		 * Snackr doesn't stutter too much.
		 */
		static private const FEED_CHECK_LIMIT: Number = 8;
		/**
		 * How many feed fetch connections to keep open at once.
		 */
		static private const MAX_CONNECTIONS: Number = 8;
		/**
		 * How many seconds to wait before timing out an HTTPService connection.
		 */
		static private const FETCH_TIMEOUT: Number = 30;
		
		/**
		 * Columns added to the feed item table schema after Snackr's initial release.
		 */
		static private const NEW_FEED_ITEM_COLUMNS: Array = [
			{name: "starred", type: "BOOLEAN", defaultValue: "0", indexed: true}
		];
		
		/**
		 * Hashtable of feeds stored by database ID, for easy in-memory lookup.
		 */
		private var _feedsByID: Object = new Object();
		/**
		 * Array of all feeds.
		 */
		private var _feeds: ArrayCollection = new ArrayCollection(new Array());
		/**
		 * Number of feed fetch connections that are currently open.
		 */
		private var _numConnections: Number = 0;
		/**
		 * Queue of feeds we're waiting to fetch.
		 */
		private var _feedFetchQueue: Array = new Array();
		/**
		 * Timer that notifies us when we should check another batch of feeds.
		 */
		private var _feedCheckTimer: Timer;
		/**
		 * Minimum time between checks of a given feed. We space out our checks of a given feed
		 * so as not to overwhelm the feed's server.
		 */
		private var _feedCheckMinTime: Number = DEFAULT_FEED_CHECK_MINIMUM_TIME;
		
		/**
		 * Our connection to the local database.
		 */
		private var _sqlConnection: SQLConnection;
		/**
		 * List of cached SQL statements we use for accessing the database.
		 */
		private var _statements: FeedStatements;
		/**
		 * The manager for the feed reader we're synchronized to, if any.
		 */
		public var feedReader: IFeedReaderSynchronizer;
		
		/**
		 * Constructor.
		 * @param sqlConnection The connection we should use to access the local database.
		 */
		public function FeedModel(sqlConnection: SQLConnection, ifeedReader: IFeedReaderSynchronizer = null) {
			_statements = new FeedStatements(sqlConnection);
			_sqlConnection = sqlConnection;
			initializeDB();
			
			if(ifeedReader != null) 
				feedReader = ifeedReader;
			else
				feedReader = new NullFeedReaderSynchronizer;
			
			fetchAllFeeds();
			
			_feedCheckTimer = new Timer(FEED_CHECK_TIMER_INTERVAL);
			_feedCheckTimer.addEventListener(TimerEvent.TIMER, handleFeedCheckTimer);
			_feedCheckTimer.start();
		}
		
		/**
		 * Cleanup function when we're ready to stop using this model.
		 */
		public function dispose(): void {
			if (_feedCheckTimer != null) {
				_feedCheckTimer.stop();
				_feedCheckTimer = null;
			}
		}

		/**
		 * Set the minimum time to wait between checks of a given feed.
		 */
		public function set feedCheckMinTime(value: Number): void {
			_feedCheckMinTime = value;
		}		
		
		/**
		 * Returns the array of feeds.
		 */
		public function get feeds(): ArrayCollection {
			return _feeds;
		}
		
		/**
		 * Initializes the feed database, creating tables if this is the first startup, and
		 * reading the existing set of feeds out of the feed table.
		 */
		private function initializeDB(): void {			
			// Create our tables if they don't already exist.
			var createTable1: LoggingStatement = new LoggingStatement();
			createTable1.sqlConnection = _sqlConnection;
			createTable1.text =
			    "CREATE TABLE IF NOT EXISTS main.feeds (" + 
			    "    feedId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			    "    url TEXT UNIQUE, " + 
			    "    name TEXT, " + 
			    "    homeURL TEXT, " + 
			    "	 logoURL TEXT, " +
			    "    priority INTEGER, " +
			    "    hasColor BOOLEAN, " +
			    "    color NUMERIC, " +
			    "    lastFetched DATE" +
			    ")";
			createTable1.execute();
			var createTable2: LoggingStatement = new LoggingStatement();
			createTable2.sqlConnection = _sqlConnection;
			createTable2.text =
			    "CREATE TABLE IF NOT EXISTS main.feedItems (" + 
			    "    guid TEXT PRIMARY KEY, " + 
			    "    feedId INTEGER, " + 
			    "    title TEXT, " + 
			    "    timestamp DATE, " + 
			    "	 link TEXT, " +
			    "    imageURL TEXT, " +
			    "    description TEXT, " +
			    "    wasRead BOOLEAN, " +
			    "    wasShown BOOLEAN " +
			    ")";
			createTable2.execute();
			
			// Check for columns required by newer versions of Snackr and add them if they don't exist.
			_sqlConnection.loadSchema(SQLTableSchema, "feedItems");
			var schema: SQLSchemaResult = _sqlConnection.getSchemaResult();
			for (var i: int = 0; i < NEW_FEED_ITEM_COLUMNS.length; i++) {
				var columnInfo: Object = NEW_FEED_ITEM_COLUMNS[i];
				var foundColumn: Boolean = false;
				if (schema != null && schema.tables.length > 0) {
					var tableSchema: SQLTableSchema = schema.tables[0];
					for (var col: Number = 0; col < tableSchema.columns.length; col++) {
						if (SQLColumnSchema(tableSchema.columns[col]).name == columnInfo.name) {
							foundColumn = true;
							break;
						}
					}
				}
				if (!foundColumn) {
					var alterTable: LoggingStatement = new LoggingStatement();
					alterTable.sqlConnection = _sqlConnection;
					// Not sure why, but parameters don't work here.
					alterTable.text = "ALTER TABLE main.feedItems ADD COLUMN " + columnInfo.name + " " + columnInfo.type + " DEFAULT " +
						columnInfo.defaultValue;
					alterTable.execute(); 
					
					// Setting the default doesn't actually seem to set that column's value on existing items.
					var setDefaultValue: LoggingStatement = new LoggingStatement();
					setDefaultValue.sqlConnection = _sqlConnection;
					setDefaultValue.text = "UPDATE main.feedItems SET " + columnInfo.name + " = " + columnInfo.defaultValue;
					setDefaultValue.execute();
					
					if (columnInfo.indexed) {
						var createIndex: LoggingStatement = new LoggingStatement();
						createIndex.sqlConnection = _sqlConnection;
						createIndex.text =
							"CREATE INDEX IF NOT EXISTS main.idxFeedItemsBy" + columnInfo.name + " ON feedItems (" + columnInfo.name + ")";
						createIndex.execute();
					}
				}
			}
					
			var createIndex1: LoggingStatement = new LoggingStatement();
			createIndex1.sqlConnection = _sqlConnection;
			createIndex1.text =
				"CREATE INDEX IF NOT EXISTS main.idxFeedItemsById ON feedItems (feedId, wasRead, wasShown, timestamp)";
			createIndex1.execute();
			var createIndex2: LoggingStatement = new LoggingStatement();
			createIndex2.sqlConnection = _sqlConnection;
			createIndex2.text =
				"CREATE INDEX IF NOT EXISTS main.idxFeedsByPriority ON feeds (priority)";
			createIndex2.execute();
			
			// Turn off the "wasShown" bit for all items, so we always see the newest stuff. 
			// (Read items will still be skipped.)
			var turnOffShown: LoggingStatement = new LoggingStatement();
			turnOffShown.sqlConnection = _sqlConnection;
			turnOffShown.text = "UPDATE main.feedItems SET wasShown = 0";
			turnOffShown.execute();
			
			// Read in the existing list of feeds.
			var getFeeds: LoggingStatement = new LoggingStatement();
			getFeeds.sqlConnection = _sqlConnection;
			getFeeds.text = "SELECT * FROM main.feeds ORDER BY name ASC, url ASC";
			getFeeds.execute();
			
			var feedResult: SQLResult = getFeeds.getResult();
			if (feedResult.data != null) {
				for (var j: int = 0; j < feedResult.data.length; j++) {
					addFeedFromInfo(feedResult.data[j], false);
				}
			}
		}

		/**
		 * Adds a set of feeds from an OPML file.
		 */
		public function loadOPMLFile(file: File): void {
			var fileStream: FileStream = new FileStream();
			fileStream.open(file, FileMode.READ);
			var opml: XML = XML(fileStream.readUTFBytes(fileStream.bytesAvailable));
			fileStream.close();
			
			for each (var outline: XML in opml..outline) {
				if (outline.hasOwnProperty("@xmlUrl")) {
					addFeedURL(outline.@xmlUrl, true);
				}
			}
			fetchAllFeeds();
		}
		
		/**
		 * Exports the current set of feeds as an OPML file.
		 */
		public function saveOPMLFile(file: File): void {
			// Construct the XML corresponding to the OPML file. We do this rather than
			// just writing out strings because we want to make sure things like ampersands
			// and quotes get properly entity-encoded.
			var opml: XML = 
				<opml version="1.0">
					<head>
						<title>Feeds exported by Snackr</title>
					</head>
					<body>
					</body>
				</opml>
			opml.head.dateCreated = new Date().toUTCString();

			var outline: XML;
			for each (var feed: Feed in _feeds.source) {
				outline = <outline/>;
				outline.@text = feed.name;
				outline.@xmlUrl = feed.url;
				outline.@htmlUrl = feed.homeURL;
				opml.body.appendChild(outline);
			}		
		
			var fileStream: FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
			fileStream.writeUTFBytes(opml.toXMLString());			
			fileStream.close();
		}
		
		/**
		 * Handles the timer that tells us when to check a batch of feeds.
		 */
		private function handleFeedCheckTimer(event: TimerEvent): void {
			fetchSomeFeeds();
		}
		
		/**
		 * Initiate a fetch of every feed in the database. We do this once on startup;
		 * after that, we only do it when the user requests it.
		 */
		public function fetchAllFeeds(): void {
			for each (var feed: Feed in _feeds.source) {
				fetchFeed(feed);
			}
		}
		
		/**
		 * Fetches a small batch of feeds that haven't been recently fetched.
		 */
		private function fetchSomeFeeds(): void {
			Logger.instance.log("Checking to see if there are feeds to fetch...", Logger.SEVERITY_DEBUG);
			var getLRFetchedFeeds: LoggingStatement = new LoggingStatement();
			getLRFetchedFeeds.sqlConnection = _sqlConnection;
			getLRFetchedFeeds.text = 
				"SELECT * FROM main.feeds WHERE lastFetched < :timeLimit ORDER BY lastFetched ASC LIMIT :maxFeeds";
			getLRFetchedFeeds.parameters[":maxFeeds"] = FEED_CHECK_LIMIT;
			getLRFetchedFeeds.parameters[":timeLimit"] = new Date(new Date().getTime() - _feedCheckMinTime * 60 * 1000);
			getLRFetchedFeeds.execute();
			var result: SQLResult = getLRFetchedFeeds.getResult();
			if (result.data != null) {
				for each (var feed: Object in result.data) {
					fetchFeed(getFeedByID(feed.feedId));
				}
			}
		}
		
		/**
		 * Returns the feed with the given database ID.
		 */
		private function getFeedByID(id: Number): Feed {
			return _feedsByID[String(id)];
		}
		
		/**
		 * Adds a feed from the given object, which must have fields corresponding to the public properties
		 * of Feed. See the Feed class for more info.
		 * @param feedInfo The object to set the feed's information from.
		 * @param initialAdd Whether this is the first time this feed is being added. If true, the feed
		 * will be added to the database.
		 */
		public function addFeedFromInfo(feedInfo: Object, initialAdd: Boolean, triggerReaderSync: Boolean = true): void {
			var feed: Feed = new Feed(_sqlConnection, _statements);
			feed.setInfo(feedInfo);
			addFeed(feed, initialAdd, triggerReaderSync);
		}
		
		/**
		 * Adds a feed for the given URL. Does not attempt to autodiscover a feed (i.e. the URL must be the
		 * actual feed URL, not a general website URL).
		 * @param url The feed URL to add.
		 * @param initialAdd Whether this is the first time this feed is being added. If true, the feed
		 * will be added to the database.
		 */
		public function addFeedURL(url: String, initialAdd: Boolean, triggerReaderSync: Boolean = true): void {
			var feed: Feed = new Feed(_sqlConnection, _statements);
			feed.url = url;
			addFeed(feed, initialAdd, triggerReaderSync);
		}
		
		
		/**
		 * Adds a feed for the given URL, which may either be a feed URL or the URL of a website with
		 * feed autodiscovery tags. This should be used for any URLs that come from the user through the UI.
		 * @param url The feed or website URL to add.
		 */
		public function addOrDiscoverNewFeed(url: String): void {
			var service: HTTPService = new HTTPService();
			service.url = url;
			service.resultFormat = HTTPService.RESULT_FORMAT_TEXT;
			service.requestTimeout = FETCH_TIMEOUT;
			service.headers = { Referer: "-" };
			service.addEventListener(ResultEvent.RESULT, handleFeedURLCheckResult);
			service.addEventListener(FaultEvent.FAULT, handleFeedURLCheckFault);
			service.send();
		}
		
		/**
		 * Handles when a feed URL can't be accessed when we're checking it before adding to the database. 
		 * This just redispatches an event to whoever might be interested.
		 */
		private function handleFeedURLCheckFault(event: FaultEvent): void {
			dispatchEvent(new FeedModelEvent(FeedModelEvent.INVALID_FEED, HTTPService(event.target).url));			
		}
		
		/**
		 * Handles a fetch of a feed or site URL and attempts to autodiscover and/or validate the feed.
		 */
		private function handleFeedURLCheckResult(event: ResultEvent): void {
			var result: String = String(event.result);
			var url: String = HTTPService(event.target).url;
			
			// Looks like we can't get the content-type (headers seems to be null often).
			// Does this look like HTML? If so, try to find possible autodiscover tags.
			var autodiscovered: Boolean = false;
			var hrefRegExp: RegExp = /href="([^"]+)"/i;
			if (result.match(/<html/i) != null) {
				var links: Array = result.match(/<link [^>]*>/gi);
				for each (var link: String in links) {
					if (link.match(/rel=['"]alternate["']/i) != null && link.match(/type=['"]application\/(rss|atom)\+xml["']/i) != null) {
						var feedURLMatches: Array = hrefRegExp.exec(link);
						if (feedURLMatches.length > 1) {
							// Looks like we've found a feed autodiscovery tag. Go and fetch it and make sure it looks like a feed.
							addOrDiscoverNewFeed(feedURLMatches[1]);
							autodiscovered = true;
							break;
						}
					}
				}
				if (!autodiscovered) {
					dispatchEvent(new FeedModelEvent(FeedModelEvent.INVALID_FEED, url));
				}
			}
			else if (result.match(/<?xml/) != null) {
				// Make sure it looks like a real feed.
				var resultXML: XML = XML(result);
				var localName: String = resultXML.localName();
				if (localName == "rss" || localName == "RDF" || localName == "feed") {			
					// TODO: this will end up fetching the feed again...kind of dumb; should just pass through
					// the XML we already got.
					addFeedURL(url, true);
				}
				else {
					dispatchEvent(new FeedModelEvent(FeedModelEvent.INVALID_FEED, url));
				}
			}	
		}
		
		/**
		 * Adds the given feed object to the model.
		 * @param feed The feed object to add.
		 * @param initialAdd Whether this is the first time this feed is being added. If true, the feed
		 * will be added to the database.
		 */
 		private function addFeed(feed: Feed, initialAdd: Boolean, triggerReaderSync: Boolean = true): Boolean {
			// If we already have a feed for this URL, do nothing.
			// TODO: should return error so we can show UI if the user adds a dupe
			for each (var existingFeed: Feed in _feeds.source) {
				if (existingFeed.url == feed.url) {
					dispatchEvent(new FeedModelEvent(FeedModelEvent.DUPLICATE_FEED_ADDED, feed.url));
					return false;
				}
			}
			
			_feeds.addItem(feed);
			feed.addEventListener(FeedEvent.FETCHED, handleFeedFetched);
			feed.addEventListener(FeedEvent.FETCH_FAILED, handleFeedFetchFailed);
			
			if (initialAdd) {
				feed.addToDB();
				fetchFeed(feed);
				
				if(triggerReaderSync)
					feedReader.addFeed(feed.url);
				
				dispatchEvent(new FeedModelEvent(FeedModelEvent.FEED_ADDED, feed.url));
			}
			_feedsByID[String(feed.feedId)] = feed;
			
			dispatchEvent(new FeedModelEvent(FeedModelEvent.FEED_LIST_UPDATED));
			return true;
		}
		
		/**
		 * Deletes the given feed and all its items from the database. This cannot be undone.
		 * @param feed The feed object we want to delete.
		 */
		public function deleteFeed(feed: Feed, triggerReaderSync: Boolean = true): void {
			var index: Number = _feeds.getItemIndex(feed);
			if (index != -1) {
				_feeds.removeItemAt(index);
				
				// Delete the feed and its items from the database.
				var deleteFeed: LoggingStatement = new LoggingStatement();
				deleteFeed.sqlConnection = _sqlConnection;
				deleteFeed.text = "DELETE FROM main.feedItems WHERE feedId = :feedId";
				deleteFeed.parameters[":feedId"] = feed.feedId;
				deleteFeed.execute();
				
				deleteFeed.text = "DELETE FROM main.feeds WHERE feedId = :feedId";
				deleteFeed.parameters[":feedId"] = feed.feedId;
				deleteFeed.execute();
				
				if(triggerReaderSync)
					feedReader.deleteFeed(feed.url);
				
				dispatchEvent(new FeedModelEvent(FeedModelEvent.FEED_DELETED, feed.url));
				dispatchEvent(new FeedModelEvent(FeedModelEvent.FEED_LIST_UPDATED));
			}
		}
		
		/**
		 * Initiates a fetch of the given feed. If too many connections are open,
		 * the feed is added to a queue to fetch later as the connections free up.
		 */
		public function fetchFeed(feed: Feed): void {
			if (_numConnections < MAX_CONNECTIONS) {
				_numConnections++;
				feed.fetch();
			}
			else {
				_feedFetchQueue.push(feed);
			}
		}
		
		/**
		 * Handle the result of a feed fetch. This just kicks us to see if we
		 * need to pull another feed off the fetch queue.
		 */
		private function handleFeedFetched(event: FeedEvent): void {
			_numConnections--;
			dispatchEvent(new FeedModelEvent(FeedModelEvent.FEEDS_UPDATED));
			checkFetchQueue();
		}
		
		/**
		 * Handle a feed fetch failure. This just kicks us to see if we
		 * need to pull another feed off the fetch queue.
		 */
		private function handleFeedFetchFailed(event: FeedEvent): void {
			_numConnections--;
			checkFetchQueue();
		}
		
		/**
		 * Checks the queue of feeds to fetch, and initiates as many fetches as we have
		 * available connections.
		 */
		private function checkFetchQueue(): void {
			while (_feedFetchQueue.length > 0 && _numConnections < MAX_CONNECTIONS) {
				_numConnections++;
				Feed(_feedFetchQueue.shift()).fetch();
			}
		}
		
		/**
		 * Choose a random batch of unshown, unread items from the database. Eventually this will use things like the
		 * feed priority, but right now it just picks a random feed, then a random item from that feed.
		 * @param numItems The number of items to pick. We might return fewer if there aren't enough
		 * unshown items left.
		 * @param ageLimit Sets the maximum age (in milliseconds) for an item to pick (i.e., we won't pick an item further back
		 * than this number of milliseconds ago).
		 */
		public function pickItems(numItems: Number, ageLimit: Number): Array {
			Logger.instance.log("Picking items...", Logger.SEVERITY_DEBUG);
			
			var result: Array = new Array();
			
			// TODO: priorities are ignored right now
			// First cut at priority-based feed mixing: 
			// -- Pick a priority (between 1 and PRIORITY_MAX), where priority N is N times as likely as priority 1.
			// -- If there are no feeds with that priority, try again.
			// -- Pick a random feed with the given priority.
			// -- Pick the next unshown item within that feed.
			// Magic function to get a number between 1 and N (inclusive) with N being N times as likely as 1.
//			var priority: Number = Math.floor(Math.sqrt(Feed.PRIORITY_MAX * (Feed.PRIORITY_MAX + 1) * Math.random() + 0.25) + 0.5);

			// Note: eventually this needs to go inside the loop, and we should cache the
			// list of feeds with unread items by priority.
			var priority: Number = 5;
			
			var limitDate: Date;
			if (ageLimit >= 1) {
				limitDate = new Date(new Date().time - ageLimit);
			}
			else {
				limitDate = new Date(0);
			}
			
			// Find all feeds with the given priority with unread items within the age limit.
			// (Note that even if an item has no unshown items, we want it as long as it has
			// *unread* items, since we do want to re-show items that have passed by in the ticker
			// but haven't been read.)
			var getFeedsStatement: LoggingStatement = _statements.getStatement(FeedStatements.GET_NONEMPTY_FEEDS_WITH_PRIORITY);
			getFeedsStatement.parameters[":priority"] = priority;
			getFeedsStatement.parameters[":limitDate"] = limitDate;
			getFeedsStatement.execute();
			var getFeedsResult: SQLResult = getFeedsStatement.getResult();
			if (getFeedsResult == null || getFeedsResult.data == null || getFeedsResult.data.length == 0) {
				Logger.instance.log("No items to pick", Logger.SEVERITY_DEBUG);
				return result;
			}
			
			var feeds: Array = getFeedsResult.data;			
			var i: Number = 0;
			var item: FeedItem;
			var feed: Feed;
			while (i < numItems) {
				// Pick a random feed from the list of feeds that match our criteria.
				feed = getFeedByID(feeds[Math.floor(Math.random() * feeds.length)].feedId);
				
				// Get the next unshown item in the feed.
				item = feed.getNextUnshownItem(limitDate);
				if (item == null) {
					// We've cycled through all the items. Start over from the
					// beginning (but still skip items that have already been read).
					feed.clearShownItems();
					item = feed.getNextUnshownItem(limitDate);
				}
				if (item != null) {
					feed.setItemShown(item);
					result.push(item);
					i++;
				}
			}
			
			Logger.instance.log("Done picking items", Logger.SEVERITY_DEBUG);
			return result;
		}

		/**
		 * Returns a list of all the starred items in the database.
		 */
		public function getStarredItems(): Array {
			var statement: LoggingStatement = _statements.getStatement(FeedStatements.GET_STARRED_ITEMS);
			statement.execute();
			var result: SQLResult = statement.getResult();
			var resultArray: Array = [];
			if (result.data != null) {
				for (var i: int = 0; i < result.data.length; i++) {
					var item: FeedItem = new FeedItem(result.data[i]);
					item.feed = getFeedByID(result.data[i].feedId);
					resultArray.push(item);		
				}
			}
			return resultArray;
		}
		
		/**
		 * Sets a flag indicating whether this item has been read (i.e. whether the user has clicked on it to view the
		 * item popup). Items that have been read never show up again in the ticker.
		 * @param item The item that should be marked as read/unread.
		 * @param value Whether to mark it as read (true) or unread (false). Default true.
		 */ 
		public function setItemRead(item: FeedItem, value: Boolean = true, triggerReaderSync: Boolean = true): void {
			setReadFlag(((item.guid == "" || item.guid == null) ? FeedItemDescriptor.UNSPECIFIED_VALUE : item.guid),
				((item.link == "" || item.link == null) ? FeedItemDescriptor.UNSPECIFIED_VALUE : item.link),
				value);
			if(triggerReaderSync)
				feedReader.setItemRead(item);
		}
		
		private function setReadFlag(guid: String, link: String, value: Boolean): void {
			var statement: LoggingStatement = _statements.getStatement(FeedStatements.SET_ITEM_READ);
			statement.parameters[":guid"] = guid;
			statement.parameters[":link"] = link;
			statement.parameters[":wasRead"] = value;
			statement.execute();		
		}
		
		public function setItemReadByDescriptor(descriptor: FeedItemDescriptor, value: Boolean = true, triggerReaderSync: Boolean = true): void {
			var item: FeedItem = getItemByDescriptor(descriptor);
			if (item != null) {
				setItemRead(item, value, triggerReaderSync);
			}
		}
		
		public function setItemsReadByDescriptors(descriptors: Array, value: Boolean = true, triggerReaderSync: Boolean = true): void {
			_sqlConnection.begin();
			for each (var descriptor: FeedItemDescriptor in descriptors) {
				if (triggerReaderSync) {
					// We can't short-circuit the DB read in this case, because we want to send bona-fide items to the reader.
					setItemReadByDescriptor(descriptor, value, triggerReaderSync);
				}
				else {
					// Bypass looking up the item in the DB. Just set the read flag.
					setReadFlag(descriptor.guid, descriptor.link, value);
				}
			}
			_sqlConnection.commit();
		}
		
		public function getItemByDescriptor(descriptor: FeedItemDescriptor): FeedItem {
			var statement: LoggingStatement = _statements.getStatement(FeedStatements.GET_ITEM_BY_IDS);
			statement.parameters[":guid"] = descriptor.guid;
			statement.parameters[":link"] = descriptor.link;
			statement.execute();
			var result: SQLResult = statement.getResult();
			if (result.data != null && result.data.length > 0) {
				var item: FeedItem = new FeedItem(result.data[0]);
				item.feed = getFeedByID(result.data[0].feedId);
				return item;
			}
			return null;			
		}
		
		public function getReadItems() : ArrayCollection {
			var statement: LoggingStatement = _statements.getStatement(FeedStatements.GET_READ_ITEMS);
			statement.execute();
			var result: SQLResult = statement.getResult();
			var readItems : ArrayCollection = new ArrayCollection(new Array());
			if(result.data != null) {
				for (var i:int = 0; i < result.data.length; i++) {
					var item: FeedItem = new FeedItem(result.data[i]);
					item.feed = getFeedByID(result.data[i].feedId);
					readItems.addItem(item);
				}
			}
			return readItems;
		}
		
		public function getUnreadItemDescriptors() : ArrayCollection {
			var statement: LoggingStatement = _statements.getStatement(FeedStatements.GET_UNREAD_ITEM_DESC);
			statement.execute();
			var result: SQLResult = statement.getResult();
			var unreadItems : ArrayCollection = new ArrayCollection(new Array());
			if(result.data != null) {
				for (var i:int = 0; i < result.data.length; i++) {
					var item: FeedItemDescriptor = new FeedItemDescriptor(result.data[i].guid, result.data[i].link);
					unreadItems.addItem(item);
				}
			}
			return unreadItems;
		}
	}
}