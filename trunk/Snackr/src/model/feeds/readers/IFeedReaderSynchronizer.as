package model.feeds.readers
{
	import flash.events.IEventDispatcher;
	
	import model.feeds.Feed;
	import model.feeds.FeedItem;
	
	import mx.collections.ArrayCollection;
	
	/**
		Generic interface for classes that keep Snackr's feed list and read/unread items in sync
		with an external blog reader such as Google Reader, Bloglines, etc.
		@author Rob Adams
	*/
	public interface IFeedReaderSynchronizer extends IEventDispatcher
	{
		/**
			Sync up all feeds and read/unread items between the local Snackr database and the external feed reader
			@param feeds The list of Snackr feeds to sync with the external reader.
		*/
		function synchronizeAll(feeds: ArrayCollection): void;
		
		/**
		 *	Return the list of feeds present in the external feed reader.
		 *	@param callback Called on completion - takes one parameter, an ArrayCollection containing the urls of
		 *                  the RSS feeds
		*/
		function getFeeds(callback: Function): void;
		
		/**
			Add a feed to the external feed reader.
			@param feed The feed to add
		*/
		function addFeed(feedURL: String): void;
		
		/**
			Remove a feed from the external feed reader.
			@param feed The feed to remove
		*/
		function deleteFeed(feedURL: String): void;
		
		/**
		 *	Return the list of items marked as read on the external feed reader for the given feed.
		 *	@param feed The feed containing the requested read items
		 *	@param callback Called on completion - takes one parameter, an ArrayCollection containing hashmaps
		 *                  with two values - "guid" contains the feed item's rss id and "feedURL" contains the
		 *                  feed item's url (since I don't trust the guid to always be present / accurate)
		*/
		function getReadItems(callback: Function): void;
		
		/**
			Set an item as read on the external feed reader.
			@param item The item to set as read
		*/
		function setItemRead(item: FeedItem): void;
	}
}