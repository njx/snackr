package model.feeds.readers
{
	import flash.events.EventDispatcher;
	
	import model.feeds.Feed;
	import model.feeds.FeedItem;
	
	import mx.collections.ArrayCollection;

	/**
		Provides common functionality used by many feed reader synchronizers.
		FeedReaderSynchronizerBase is not a complete implementation of IFeedReaderSynchronizer
		itself - see its subclasses for implementations for specific reader programs.
		@author Rob Adams
	*/
	public class FeedReaderSynchronizerBase extends EventDispatcher implements IFeedReaderSynchronizer
	{
		public static const SNACKR_CLIENT_ID: String = "Snackr";
		
		public function synchronizeAll(feeds:ArrayCollection): void
		{
		}
		
		public function getFeeds(callback: Function): void
		{
		}
		
		public function addFeed(feedURL:String): void
		{
		}
		
		public function deleteFeed(feedURL:String): void
		{
		}
		
		public function getReadItems(callback: Function): void
		{
		}
		
		public function setItemRead(item:FeedItem): void
		{
		}
		
	}
}