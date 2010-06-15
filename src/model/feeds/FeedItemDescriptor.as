package model.feeds
{
	/**
	 * A structure that can be used to look up a FeedItem in the model. Can specify either
	 * a guid, a link, or both.
	 */
	public class FeedItemDescriptor
	{
		// String representing an unspecified guid or link. We set these to explicit strings rather
		// than just the empty string so that we won't accidentally match a missing guid or link in
		// the database.
		static public const UNSPECIFIED_VALUE: String = "_UNSPECIFIED_VALUE_";
		
		public var guid: String = UNSPECIFIED_VALUE;
		public var link: String = UNSPECIFIED_VALUE;
		
		public function FeedItemDescriptor(guid: String, link: String)
		{
			this.guid = (guid == null || guid == "") ? UNSPECIFIED_VALUE : guid;
			this.link = (link == null || link == "") ? UNSPECIFIED_VALUE : link;
		}
		
		public function toString() : String {
			return "FeedItemDescriptor [guid: " + guid + ", link: " + link + "]";
		}
	}
}