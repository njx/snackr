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
	import flash.events.Event;

	/**
	 * Event class for various events that come out of the FeedModel.
	 */
	public class FeedModelEvent extends Event
	{
		/**
		 * Event type indicating that at least one feed has been recently successfully fetched.
		 */
		static public const FEEDS_UPDATED: String = "feedsUpdated";
		/**
		 * Event type indicating that the list of feeds has changed.
		 */
		static public const FEED_LIST_UPDATED: String = "feedListUpdated";
		/**
		 * Event type indicating that a new feed has been added.
		 */
		static public const FEED_ADDED: String = "feedAdded";
		/**
		 * Event type indicating that a feed has been deleted.
		 */
		static public const FEED_DELETED: String = "feedDeleted";
		/**
		 * Event type indicating that an attempt was made to add a feed that was already in the database.
		 */
		static public const DUPLICATE_FEED_ADDED: String = "duplicateFeedAdded";
		/**
		 * Event type indicating that an attempt was made to add a URL that doesn't appear to be a valid feed.
		 */ 
		static public const INVALID_FEED: String = "invalidFeed";
		
		/**
		 * The URL of the feed this event refers to. Does not apply to FEEDS_UPDATED or FEED_LIST_UPDATED.
		 */
		public var url: String = "";
		
		/**
		 * Constructor.
		 * @param type The type of the event (one of the constants above).
		 * @param url The URL this event refers to, if relevant.
		 */
		public function FeedModelEvent(type: String, url: String = "")
		{
			super(type);
			this.url = url;
		}
		
	}
}