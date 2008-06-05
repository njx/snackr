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
	/**
	 * Class holding information for a single item from a feed. Unlike feeds, these are
	 * transient objects; feed items are retrieved from the database when necessary,
	 * and aren't cached for long periods of time.
	 */
	public class FeedItem
	{
		/**
		 * Reference to the feed this item is from.
		 */
		public var feed: Feed = null;
		/**
		 * The globally unique ID for this feed item. Since guids are supposed to be
		 * global, this should generally be unique even across feeds.
		 */
		public var guid: String = "";
		/**
		 * The title of the feed item.
		 */
		public var title: String = "";
		/**
		 * The time the feed item was last updated.
		 */
		public var timestamp: Date = null;
		/**
		 * Link to the original post this feed item represents.
		 */
		public var link: String = "";
		/**
		 * Image associated with this feed item. Note that this only indicates the
		 * image directly mentioned in the feed item (which isn't a standard field
		 * in RSS or Atom); our heuristics for choosing images out of the content
		 * of the item are implemented further up the chain.
		 */
		public var imageURL: String = "";
		/**
		 * The content of the item.
		 */
		public var description: String = "";
		/**
		 * Whether this item was starred to read later.
		 */
		public var starred: Boolean = false;
		
		/**
		 * Constructs a feed item from a generic object with fields corresponding to the
		 * names of the various item properties.
		 */
		public function FeedItem(itemInfo: Object) {
			guid = itemInfo.guid; 
			title = itemInfo.title;
			timestamp = itemInfo.timestamp;
			link = itemInfo.link;
			imageURL = itemInfo.imageURL;
			description = itemInfo.description;
			starred = itemInfo.starred;
		}
	}
}