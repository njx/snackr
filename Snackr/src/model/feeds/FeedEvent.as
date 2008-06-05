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
	 * Events dispatched by feeds when they're fetched or when an item in the feed is read.
	 */
	public class FeedEvent extends Event
	{
		/**
		 * Event type for when a feed is successfully fetched.
		 */
		static public const FETCHED: String = "fetched";
		/**
		 * Event type for when a feed fetch fails.
		 */
		static public const FETCH_FAILED: String = "fetchFailed";
		/**
		 * Event type for when an item is read by the user.
		 */
		static public const ITEM_READ: String = "itemRead";
		
		/**
		 * The feed to which this event refers.
		 */
		public var feed: Feed;
		/**
		 * The feed item to which this event refers; only applies to itemRead events.
		 * In other cases, the item will be null.
		 */
		public var item: FeedItem;

		/**
		 * Constructor.
		 * @param type The event type (one of the constants above).
		 * @param feed The feed to which the event refers.
		 * @param item The feed item to which the event refers; only applies to itemRead events. Default null.
		 */
		public function FeedEvent(type: String, feed: Feed, item: FeedItem = null)
		{
			super(type);
			this.feed = feed;
			this.item = item;
		}
	}
}