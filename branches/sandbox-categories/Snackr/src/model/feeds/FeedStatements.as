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
	import flash.data.SQLConnection;
	
	/**
	 * Global cache of SQL statements we use to make various queries. Caching the statements improves
	 * performance slightly, since there is a small startup cost to prepare a feed statement. By
	 * keeping the statements around, and just changing statement parameters each time we run the
	 * query, we save a small amount of work.
	 * 
	 * To add a new statement, just add a constant for it, then add the statement itself to
	 * the _statementInit array below.
	 */
	public class FeedStatements
	{
		static public const ADD_FEED: String = "addFeed";
		static public const GET_NONEMPTY_FEEDS_WITH_PRIORITY: String = "getNonemptyFieldsWithPriority";
		static public const COUNT_ITEMS: String = "countItems";
		static public const SET_ITEM_SHOWN: String = "setItemShown";
		static public const SET_ITEM_READ: String = "setItemRead";
		static public const SET_ITEM_STARRED: String = "setItemStarred";
		static public const GET_UNSHOWN_ITEM: String = "getUnshownItem";
		static public const CLEAR_SHOWN_ITEMS: String = "clearShownItems";
		static public const GET_STARRED_ITEMS: String = "getStarredItems";
		static public const GET_STATE: String = "getState";
		static public const INSERT_ITEM: String = "insertItem";
		static public const DELETE_ITEM: String = "deleteItem";
		static public const UPDATE_FEED: String = "updateFeed";
		static public const UPDATE_FAILED_FEED: String = "updateFailedFeed";
		static public const GET_ITEM_BY_IDS: String = "getItemByIds";
		static public const GET_READ_ITEMS: String = "getReadItems";
		static public const GET_UNREAD_ITEM_DESC: String = "getUnreadItemDesc";
		static public const HAS_UNSHOWN_ITEMS: String = "hasUnshownItems";
		static public const ADD_TAG: String = "addTag";
		static public const DELETE_TAG: String = "deleteTag";
		static public const RENAME_TAG: String = "renameTag";
		static public const SET_TAG_COLOR: String = "setTagColor";
		static public const ADD_FEED_TAG: String = "addFeedTag";
		static public const ADD_FEED_TAG_BY_NAME: String = "addFeedTagByName";
		static public const GET_FEED_TAGS: String = "getFeedTags";
		static public const GET_FEEDS_WITH_TAG: String = "getFeedsWithTag";
		static public const REMOVE_FEED_TAG: String = "removeFeedTag";
		static public const REMOVE_FEEDS_WITH_TAG: String = "removeFeedsWithTag";
		
		/**
		 * Array of SQL queries to cache. Add an entry to this array to add a new cached statement.
		 */
		static private const _statementInit: Array = [
			[ADD_FEED, "INSERT INTO main.feeds (url, name, homeURL, logoURL, priority, hasColor, color, lastFetched) " +
				"VALUES (:url, :name, :homeURL, :logoURL, :priority, :hasColor, :color, :lastFetched)"],
			[GET_NONEMPTY_FEEDS_WITH_PRIORITY, "SELECT feedId FROM main.feeds feed " +
				"WHERE priority = :priority " +
				"AND EXISTS (SELECT guid from main.feedItems WHERE feed.feedId = feedItems.feedId AND wasRead != true AND timestamp > :limitDate)"],
			[COUNT_ITEMS, "SELECT * FROM main.feedItems WHERE feedId = :feedId LIMIT 1"],
			[SET_ITEM_SHOWN, "UPDATE main.feedItems SET wasShown = true WHERE guid = :guid"],
			[GET_ITEM_BY_IDS, "SELECT * FROM main.feedItems WHERE guid = :guid OR link = :link LIMIT 1"],
			[SET_ITEM_READ, "UPDATE main.feedItems SET wasRead = :wasRead WHERE guid = :guid OR link = :link"],
			[SET_ITEM_STARRED, "UPDATE main.feedItems SET starred = :starred WHERE guid = :guid"],
			[GET_UNSHOWN_ITEM, "SELECT * FROM main.feedItems " +
				"WHERE feedId = :feedId AND wasShown != true AND wasRead != true " +
				"AND timestamp > :limitDate " +
				"ORDER BY timestamp DESC " +
				"LIMIT 1"],
			[CLEAR_SHOWN_ITEMS, "UPDATE main.feedItems SET wasShown = false WHERE feedId = :feedId"],
			[GET_STARRED_ITEMS, "SELECT * FROM main.feedItems WHERE starred = true ORDER BY timestamp DESC"],
			[GET_STATE, "SELECT guid, wasShown, wasRead FROM main.feedItems " +
				"WHERE feedId = :feedId"],
			[GET_READ_ITEMS, "SELECT * FROM main.feedItems WHERE wasRead = true ORDER BY timestamp DESC"],
			[GET_UNREAD_ITEM_DESC, "SELECT guid, link FROM main.feedItems WHERE wasRead = false ORDER BY timestamp DESC"],
			[INSERT_ITEM, "REPLACE INTO main.feedItems (guid, feedId, title, timestamp, link, imageURL, description, wasRead, wasShown, starred) " +
				"VALUES (:guid, :feedId, :title, :timestamp, :link, :imageURL, :description, :wasRead, :wasShown, :starred)"],
			[DELETE_ITEM, "DELETE FROM main.feedItems WHERE guid = :guid"],
			[UPDATE_FEED, "UPDATE main.feeds " +
				"SET url = :url, name = :name, homeURL = :homeURL, logoURL = :logoURL, priority = :priority, hasColor = :hasColor, color = :color, lastFetched = :lastFetched " +
				"WHERE feedId = :feedId"],
			[UPDATE_FAILED_FEED, "UPDATE main.feeds SET name = :name, lastFetched = :lastFetched WHERE feedId = :feedId"],
			[HAS_UNSHOWN_ITEMS, "SELECT * FROM main.feedItems " +
				"WHERE wasShown != true AND wasRead != true " +
				"AND timestamp > :limitDate " +
				"LIMIT 1"],
			[ADD_TAG, "INSERT INTO main.tags (tag, hasColor, color) VALUES (:tag, :hasColor, :color)"],
			[DELETE_TAG, "DELETE FROM main.tags WHERE tagId = :tagId"],
			[RENAME_TAG, "UPDATE main.tags SET tag = :tag WHERE tagId = :tagId"],
			[SET_TAG_COLOR, "UPDATE main.tags SET hasColor = :hasColor, color = :color WHERE tagId = :tagId"],
			[ADD_FEED_TAG, "REPLACE INTO main.feedsWithTags (feedId, tagId) VALUES (:feedId, :tagId)"],
			// TODO: not sure this will work
			[ADD_FEED_TAG_BY_NAME, "INSERT INTO main.feedsWithTags (feedId, tagId) VALUES (:feedId, (SELECT tagId FROM main.tags WHERE tag = :tag))"],
			[GET_FEED_TAGS, "SELECT * FROM main.feedsWithTags WHERE feedId = :feedId"],
			[GET_FEEDS_WITH_TAG, "SELECT * FROM main.feedsWithTags WHERE tagId = :tagId"],
			[REMOVE_FEED_TAG, "DELETE FROM main.feedsWithTags WHERE feedId = :feedId AND tagId = :tagId"],
			[REMOVE_FEEDS_WITH_TAG, "DELETE FROM main.feedsWithTags WHERE tagId = :tagId"]
		];
		
		/**
		 * The array of cached statements.
		 */
		static private var _statements: Object = new Object();
		
		/**
		 * Constructor. Creates SQLStatements for each statement in _statementInit.
		 * @param sqlConnection The database connection to use for the statements.
		 */
		public function FeedStatements(sqlConnection: SQLConnection) {
			var statement: LoggingStatement;
			for (var i: Number = 0; i < _statementInit.length; i++) {
				statement = new LoggingStatement();
				statement.sqlConnection = sqlConnection;
				statement.text = _statementInit[i][1];
				_statements[_statementInit[i][0]] = statement;
			}
		}
		
		/**
		 * Returns the SQLStatement for a given key (one of the constants above).
		 */
		public function getStatement(key: String): LoggingStatement {
			return _statements[key];
		}
	}
}