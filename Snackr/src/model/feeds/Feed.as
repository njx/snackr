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
	import com.adobe.utils.DateUtil;
	
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.ByteArray;
	
	import model.logger.Logger;
	
	/**
	 * Represents a single feed. Feeds are stored in the local SQL database, and their information
	 * is loaded into memory on startup.
	 */
	public class Feed extends EventDispatcher
	{
		/**
		 * Minimum feed priority. Not currently used.
		 */
		static public const PRIORITY_LOW: Number = 1;
		/**
		 * Normal feed priority. Not currently used.
		 */
		static public const PRIORITY_MEDIUM: Number = 5;
		/**
		 * Maximum feed priority. Not currently used.
		 */
		static public const PRIORITY_MAX: Number = 10;
		
		/**
		 * How many seconds to wait before cancelling an incomplete HTTP request.
		 */
		static private const FETCH_TIMEOUT: Number = 30;
		
		/**
		 * The numeric ID of this feed in the local database.
		 */
		public var feedId: Number;
		/**
		 * The URL of the feed itself (not the site it refers to).
		 */
		public var url: String;
		/**
		 * The title of the feed.
		 */
		public var name: String = null;
		/**
		 * The URL of the site the feed refers to.
		 */
		public var homeURL: String = null;
		/**
		 * The URL of the feed's logo image, if any.
		 */
		public var logoURL: String = null;		

		/**
		 * The priority of the feed. This is not currently used; eventually, I'm planning
		 * to implement a way for some feeds to show up more often than others.
		 */
		public var priority: Number = PRIORITY_MEDIUM;
		/**
		 * Whether the feed has a highlight color. Not currently used.
		 */
		public var hasColor: Boolean = false;
		/**
		 * The color that items in the feed are highlighted with on the ticker. Not currently used.
		 */
		public var color: uint = 0x000000;
		
		/**
		 * The connection to the local SQL database.
		 */
		private var _sqlConnection: SQLConnection;
		/**
		 * Pointer to the list of cached SQL statements we use to query the database.
		 * TODO: this should probably just be global.
		 */
		private var _statements: FeedStatements;
		
		/**
		 * The last time the items in this feed were fetched.
		 */
		private var _lastFetched: Date = null;

		// Various XML namespaces for tags we might encounter in a feed.
		namespace media = "http://search.yahoo.com/mrss/";
		namespace atom03 = "http://purl.org/atom/ns#";
		namespace atom10 = "http://www.w3.org/2005/Atom";
		namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
		namespace rss10 = "http://purl.org/rss/1.0/";
		namespace dc = "http://purl.org/dc/elements/1.1/";
		
		/**
		 * Constructor for Feed objects. You shouldn't call this directly; instead, call
		 * one of the methods on FeedModel that adds a feed (addFeedURL() or
		 * addOrDiscoverNewFeed()).
		 * @param sqlConnection A connection to the database.
		 * @param statements The object containing the cached feed statements we use for all common database queries.
		 */
		public function Feed(sqlConnection: SQLConnection, statements: FeedStatements) {
			_sqlConnection = sqlConnection;
			_statements = statements;
		}
		
		/**
		 * Sets this feed's properties from a generic object with feed information.
		 * @param feedInfo An Object with fields corresponding to the feed's properties.
		 */
		public function setInfo(feedInfo: Object): void {
			feedId = feedInfo.feedId;
			url = feedInfo.url;
			name = feedInfo.name;
			homeURL = feedInfo.homeURL;
			logoURL = feedInfo.logoURL;
			priority = feedInfo.priority;
			hasColor = feedInfo.hasColor;
			color = feedInfo.color;
			_lastFetched = feedInfo.lastFetched;
		}
		
		/**
		 * Adds this feed to the feed table in the database.
		 */
		public function addToDB(): void {
			var statement: LoggingStatement = _statements.getStatement(FeedStatements.ADD_FEED);
			fillFeedParameters(statement.parameters);
			statement.execute();
			feedId = statement.getResult().lastInsertRowID;
		}
		
		/**
		 * Fills the parameters for a feed-related query from the properties of this feed.
		 * @param parameters The parameter object to fill.
		 */
		private function fillFeedParameters(parameters: Object): void {
			parameters[":url"] = url;
			parameters[":name"] = name;
			parameters[":homeURL"] = homeURL;
			parameters[":logoURL"] = logoURL;
			parameters[":priority"] = priority;
			parameters[":hasColor"] = hasColor;
			parameters[":color"] = color;
			parameters[":lastFetched"] = lastFetched;
		}
		
		/**
		 * Returns the last time this feed was fetched.
		 */
		public function get lastFetched(): Date {
			return _lastFetched;
		}
		
		/**
		 * Returns whether there are any items in this feed.
		 */
		public function hasItems(): Boolean {
			var statement: LoggingStatement = _statements.getStatement(FeedStatements.COUNT_ITEMS);
			statement.parameters[":feedId"] = feedId;
			statement.execute();
			var result: SQLResult = statement.getResult();
			return (result.data != null && result.data.length > 0);
		}
		
		/**
		 * Sets a flag indicating that this item has been shown in the ticker. Note that this is different from
		 * whether the item has been read (i.e. clicked on to show the item popup). An item that
		 * has been shown, but not read, will show up again eventually (once all the other items in the
		 * feed have been shown, in reverse chronological order, or after Snackr has been restarted).
		 * @param item The item that was shown.
		 */
		public function setItemShown(item: FeedItem): void {
			var statement: LoggingStatement = _statements.getStatement(FeedStatements.SET_ITEM_SHOWN);
			statement.parameters[":guid"] = item.guid;
			statement.execute();
		}
		
		/**
		 * Sets a flag indicating whether this item has been starred to read later. Starred items show up
		 * in the "starred items" list that can be accessed from the main ticker tab.
		 * @param item The item that should be marked as starred/unstarred.
		 * @param value Whether to mark it as starred (true) or unstarred (false). Default true.
		 */
		public function setItemStarred(item: FeedItem, value: Boolean = true): void {
			var statement: LoggingStatement = _statements.getStatement(FeedStatements.SET_ITEM_STARRED);
			statement.parameters[":guid"] = item.guid;
			statement.parameters[":starred"] = value;
			statement.execute();
			item.starred = value;			
		}
		
		/**
		 * Returns the most recent item in the feed that has not been shown in the ticker (since the last time
		 * unshown items were cleared) and is no older than the given date. 
		 * @param limitDate The cutoff date for items to retrieve.
		 */
		public function getNextUnshownItem(limitDate: Date): FeedItem {
			var statement: LoggingStatement = _statements.getStatement(FeedStatements.GET_UNSHOWN_ITEM);
			statement.parameters[":feedId"] = feedId;
			statement.parameters[":limitDate"] = limitDate;
			statement.execute();
			var result: SQLResult = statement.getResult();
			if (result.data != null && result.data.length > 0) {
				var item: FeedItem = new FeedItem(result.data[0]);
				item.feed = this;
				return item;
			}
			return null;
		}
		
		/**
		 * Clears the "shown" bit for all items. This happens on startup, or when all the items in a feed
		 * have already been shown (in which case we want to start showing them again from the beginning).
		 */
		public function clearShownItems(): void {
			var statement: LoggingStatement = _statements.getStatement(FeedStatements.CLEAR_SHOWN_ITEMS);
			statement.parameters[":feedId"] = feedId;
			statement.execute();
		}

		/**
		 * Initiates a fetch of the items for this feed.
		 */
		public function fetch(): void {
			// TODO: this is just SEVERITY_NORMAL for testing, should eventually be SEVERITY_DEBUG
			Logger.instance.log("Fetching: " + url + " (pri = " + priority + ")", Logger.SEVERITY_NORMAL);
			_lastFetched = new Date();
			
			// We can't use HTTPService here, because we need to retrieve the feed as binary in case it's
			// a non-UTF-8 feed. Instead, we use URLLoader, capture it as a ByteArray, figure out the
			// encoding, then translate it using readMultiByte().
			// TODO: is there any way to set a timeout limit?
			var request: URLRequest = new URLRequest();
			request.url = url;
			request.requestHeaders = [new URLRequestHeader("Referer", "-")];
			var loader: URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, handleFetchComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, handleFetchError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleFetchError);
			loader.load(request);
		}
		
		/**
		 * Gets the href from a <link> with rel="alternate".
		 * 
		 * This is needed because not all <link>s have a rel attribute and e4x chokes in this instance.
		 */
		private function getAlternateLinkHref(result : XML) : String {
			use namespace atom03;
			use namespace atom10;
			for each (var link : XML in result.link) {
				// Bug 118: If no alternate is specified, don't throw an exception. Treat
				// no rel as the same as alternate.
				if (link.@rel == undefined || link.@rel == "alternate") {
					return link.@href;
				}
			}
			return null;
		}
		
		/**
		 * Parses a raw byte array into XML, taking the byte-order-mark and character encoding into account.
		 */
		private function convertByteArrayToXML(bytes: ByteArray): XML {
			var encoding: String = null;
			
			// First, see if we have a byte-order mark. If so, pick the appropriate encoding.
			if (bytes.length >= 2) {
				if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
					encoding = "utf-16";
				}
				else if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
					encoding = "unicodeFFFE";
				}
				else if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
					encoding = "utf-8";
				}
			}
			
			// If we haven't seen a byte-order mark, then convert it to a string and see if we can find 
			// an encoding. 
			// TODO: should really scan the byte array rather than converting to string and using a regexp
			if (encoding == null) {
				var rawString: String = bytes.toString();
				var pattern: RegExp = /<?xml[^>]*encoding\s*=\s*['"]([^'"]*)['"][^>]*?>/;
				var matchResult: Object = pattern.exec(rawString);
				if (matchResult != null && matchResult.length > 1) {
					encoding = matchResult[1];
				}
			}
			
			// If we still haven't found an encoding, it must be utf-8.
			if (encoding == null) {
				encoding = "utf-8";
			}
			
//			Logger.instance.log("Encoding for " + url + ": " + encoding, Logger.SEVERITY_DEBUG);
			var result: XML = null;
			try {
				result = new XML(bytes.readMultiByte(bytes.length, encoding));
			}
			catch (e: Error) {
				doFetchFailed(e.message);
			}
			return result;			
		}
		
		/**
		 * Parses the XML for a given feed, stores any new or updated items in the database,
		 * and deletes any items that have expired from the feed.
		 * @param event The result event for the fetch.
		 */
		private function handleFetchComplete(event: Event): void {
			// TODO: should change this to use the AS syndication library:
			// http://code.google.com/p/as3syndicationlib/
			
			// Gather up the list of existing items. We only want to insert new
			// items, and delete any existing items that are no longer in the feed.
			var getStateStatement: LoggingStatement = _statements.getStatement(FeedStatements.GET_STATE);
			getStateStatement.parameters[":feedId"] = feedId;
			getStateStatement.execute();
			
			var existingItems: Object = new Object();
			var sqlResult: SQLResult = getStateStatement.getResult();
			if (sqlResult.data != null) {
				for each (var row: Object in sqlResult.data) {
					existingItems[row.guid] = true;
				}
			}
			
			// Parse the XML.
			var loader: URLLoader = URLLoader(event.target);
			var resultBytes: ByteArray = ByteArray(loader.data);
			var result: XML = convertByteArrayToXML(resultBytes);
			if (result != null) {			
				// Batch up all the following updates.			
				_sqlConnection.begin();	
				
				var insertStatement: LoggingStatement = _statements.getStatement(FeedStatements.INSERT_ITEM);
				if (result.localName() == "rss" || result.localName() == "RDF") {
					// RSS 0.91, 1.0, or 2.0. RSS 1.0 (the RDF case) requires some special handling.
					// We open the rdf and rss10 namespaces here even in the non-RSS 1.0 case (shouldn't hurt 
					// the other cases, and makes the RSS 1.0 case easier).
					use namespace rdf;
					use namespace rss10;
					var isRDF: Boolean = (result.localName() == "RDF");
					
					name = ensureUnique(result.channel.title);
					homeURL = ensureUnique(result.channel.link);
					logoURL = ensureUnique(isRDF ? result.channel.image.@resource : result.channel.image.url);
					
					var guid: String;
					for each (var item: XML in (isRDF ? result.item : result.channel.item)) {
						if (isRDF) {
							guid = item.@about.toString();
						}
						else {
							guid = ((item.guid == undefined || item.guid == null || item.guid == '') ? item.link.toString() : item.guid.toString());
						}
						if (existingItems[guid] != undefined) {
							// We don't update the existing item, to improve performance. This does mean we won't
							// get changes to the item.
							// TODO: should we?
							existingItems[guid] = false;
						}
						else {
							insertStatement.parameters[":guid"] = guid;
							insertStatement.parameters[":feedId"] = feedId;
							insertStatement.parameters[":title"] = item.title.toString();
							insertStatement.parameters[":timestamp"] = null;
							var pubDate: String = item.pubDate;
							var useW3C: Boolean = false;
							if (pubDate == "" || pubDate == null) {
								pubDate = item.dc::date;
								useW3C = true;
							}
							if (pubDate != "" && pubDate != null) {
								try {
									insertStatement.parameters[":timestamp"] = 
										(useW3C ? DateUtil.parseW3CDTF(pubDate) : DateUtil.parseRFC822(pubDate));
								}
								catch (e: Error) {
									Logger.instance.log("Couldn't parse date " + pubDate + ": " + e.message, Logger.SEVERITY_DEBUG);
									// Use the current date/time. This is a little backwards...items higher up in the feed (which are newer)
									// will get earlier timestamps this way...but it's better than nothing.
									insertStatement.parameters[":timestamp"] = new Date();
								}
							}
							else {
								Logger.instance.log("Couldn't get date for guid: " + guid, Logger.SEVERITY_DEBUG);
								// Use the current date/time. This is a little backwards...items higher up in the feed (which are newer)
								// will get earlier timestamps this way...but it's better than nothing.
								insertStatement.parameters[":timestamp"] = new Date();
							}
							insertStatement.parameters[":link"] = item.link.toString();
							insertStatement.parameters[":imageURL"] = item.media::thumbnail.@url;
							insertStatement.parameters[":description"] = item.description.toString();
							insertStatement.parameters[":wasRead"] = false;
							insertStatement.parameters[":wasShown"] = false;
							insertStatement.parameters[":starred"] = false;
							try {
								insertStatement.execute();
							}
							catch (e: SQLError) {
								// Ignore this for now. We seem to get duplicate guids for some reason.
							}
						}
					}
				}
				else if (result.localName() == "feed") {
					// Atom 0.3 or 1.0
					use namespace atom03;
					use namespace atom10;
					name = ensureUnique(result.title);
					homeURL = getAlternateLinkHref(result);
					logoURL = ensureUnique(result.logo);
					for each (var entry: XML in result.entry) {
						if (existingItems[entry.id.toString()] != undefined) {
							// We don't update the existing item, to improve performance. This does mean we won't
							// get changes to the item.
							// TODO: should we?
							existingItems[entry.id.toString()] = false;
						}
						else {
							insertStatement.parameters[":guid"] = entry.id.toString();
							insertStatement.parameters[":feedId"] = feedId;
							insertStatement.parameters[":title"] = entry.title.toString();
							// TODO: should use updated if it exists
							insertStatement.parameters[":timestamp"] = null;
							var entryDate: String = entry.updated;
							if (entryDate == "" || entryDate == null) {
								entryDate = entry.modified;
							}
							if (entryDate == "" || entryDate == null) {
								entryDate = entry.published;
							}
							if (entryDate == "" || entryDate == null) {
								entryDate = entry.issued;
							}
							if (entryDate != null && entryDate != "") {
								try {
									insertStatement.parameters[":timestamp"] = DateUtil.parseW3CDTF(entryDate);
								}
								catch (e: Error) {
									Logger.instance.log("Couldn't parse date " + entryDate + ": " + e.message, Logger.SEVERITY_DEBUG);
									// Use the current date/time. This is a little backwards...items higher up in the feed (which are newer)
									// will get earlier timestamps this way...but it's better than nothing.
									insertStatement.parameters[":timestamp"] = new Date();
								}
							}
							else {
								Logger.instance.log("Couldn't get date for guid " + entry.id, Logger.SEVERITY_DEBUG);
								// Use the current date/time. This is a little backwards...items higher up in the feed (which are newer)
								// will get earlier timestamps this way...but it's better than nothing.
								insertStatement.parameters[":timestamp"] = new Date();
							}
							insertStatement.parameters[":link"] = getAlternateLinkHref(entry);
							// TODO: what about summary?
							insertStatement.parameters[":description"] = entry.content.toString();
							insertStatement.parameters[":wasRead"] = false;
							insertStatement.parameters[":wasShown"] = false;
							insertStatement.parameters[":starred"] = false;
							// TODO: is there a standard way to have entry images in Atom?
							insertStatement.parameters[":imageURL"] = null;
							try {
								insertStatement.execute();
							}
							catch (e: SQLError) {
								// Ignore this for now. We seem to get duplicate guids for some reason.
							}
						}
					}
				}
				
				// Delete any existing items that are no longer in the feed. Since we're not a
				// real feedreader--we're for "recent serendipity"--we don't want to keep old items
				// around.
				var deleteStatement: LoggingStatement = _statements.getStatement(FeedStatements.DELETE_ITEM);
				for (var oldGuid: String in existingItems) {
					if (existingItems[oldGuid] == true) {
						deleteStatement.parameters[":guid"] = oldGuid;
						deleteStatement.execute();
					}
				}
				
				// Update the information for this feed in the database.
				var updateStatement: LoggingStatement = _statements.getStatement(FeedStatements.UPDATE_FEED);
				fillFeedParameters(updateStatement.parameters);
				updateStatement.parameters[":feedId"] = feedId;
				updateStatement.execute();
				
				// Commit all the batched changes into the database.
				_sqlConnection.commit();
				dispatchEvent(new FeedEvent(FeedEvent.FETCHED, this));
			}
		}
		
		private function ensureUnique(item: *): * {
			if (item is XMLList) {
				return XMLList(item)[0];
			}
			else {
				return item;
			}
		}
		
		/**
		 * Handles when a feed can't be fetched. Currently this just logs the error.
		 * @param event The fault event for the failed fetch.
		 */
		private function handleFetchError(event: ErrorEvent): void {
			doFetchFailed(event.text);
		}
		
		private function doFetchFailed(message: String): void {
			Logger.instance.log("Couldn't fetch feed: " + url + ", error: " + message);
			if (name == null) {
				name = "[Feed can't be read]";
			}
			var updateFailedStatement: LoggingStatement = _statements.getStatement(FeedStatements.UPDATE_FAILED_FEED);
			updateFailedStatement.parameters[":name"] = name;
			updateFailedStatement.parameters[":lastFetched"] = lastFetched;
			updateFailedStatement.parameters[":feedId"] = feedId;
			updateFailedStatement.execute();
			dispatchEvent(new FeedEvent(FeedEvent.FETCH_FAILED, this));
		}
		
		/**
		 * Returns the feed title.
		 */
		override public function toString(): String {
			return name;
		}
	}
}