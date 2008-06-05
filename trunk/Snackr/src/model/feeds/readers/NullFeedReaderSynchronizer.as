package model.feeds.readers
{
	import flash.events.EventDispatcher;
	
	import model.feeds.Feed;
	import model.feeds.FeedItem;
	import model.logger.Logger;
	
	import mx.collections.ArrayCollection;

	/**
		Implementation of IFeedReaderSynchronizer that does nothing.
		We use this class when no external feed reader is in use
		(as well as for debugging purposes). All methods are stubs.
		@author Rob Adams
	*/
	public class NullFeedReaderSynchronizer extends EventDispatcher implements IFeedReaderSynchronizer
	{
		public function NullFeedReaderSynchronizer()
		{
			Logger.instance.log("NullFeedReaderSynchronizer: constructor", Logger.SEVERITY_DEBUG);
		}

		public function synchronizeAll(feeds:ArrayCollection): void
		{
			Logger.instance.log("NullFeedReaderSynchronizer: synchronizeAll: " + feeds, Logger.SEVERITY_DEBUG);
		}
		
		public function getFeeds(callback: Function): void
		{
			Logger.instance.log("NullFeedReaderSynchronizer: getFeeds", Logger.SEVERITY_DEBUG);
		}
		
		public function addFeed(feedURL:String): void
		{
			Logger.instance.log("NullFeedReaderSynchronizer: addFeed: " + feedURL, Logger.SEVERITY_DEBUG);
		}
		
		public function deleteFeed(feedURL:String): void
		{
			Logger.instance.log("NullFeedReaderSynchronizer: deleteFeed: " + feedURL, Logger.SEVERITY_DEBUG);
		}
		
		public function getReadItems(callback: Function): void
		{
			Logger.instance.log("NullFeedReaderSynchronizer: getReadItems", Logger.SEVERITY_DEBUG);
		}
		
		public function setItemRead(item:FeedItem): void
		{
			Logger.instance.log("NullFeedReaderSynchronizer: setItemRead: " + item, Logger.SEVERITY_DEBUG);
		}
		
	}
}