package ui.ticker
{
	import model.feeds.FeedItem;
	
	[Bindable]
	public class TickerItemData
	{
		public var title: String = "";
		public var info: String = "";
		public var info2: String = "";
		public var imageURL: String = "";
		public var description: String = "";
		public var link: String = "";
		
		// TODO: This shouldn't really live in here, but we're depending on it in a few places.
		// It should at the very least be opaque.
		public var feedItem: FeedItem = null;
	}
}