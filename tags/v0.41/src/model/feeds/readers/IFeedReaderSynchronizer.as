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

package model.feeds.readers
{
	import flash.events.IEventDispatcher;
	
	import model.feeds.FeedItemDescriptor;
	
	import mx.collections.ArrayCollection;
	
	/**
		Generic interface for classes that keep Snackr's feed list and read/unread items in sync
		with an external blog reader such as Google Reader, Bloglines, etc.
		@author Rob Adams
	*/
	public interface IFeedReaderSynchronizer extends IEventDispatcher
	{
		/**
		 * Authenticates Snackr with the external feed reader. Must be called before other operations can be performed.
		 * @param login User name to log in as.
		 * @param password The user's password
		 */
		function authenticate(login: String, password: String): void;
		function authenticateCaptcha(login: String, password: String, captchaToken: String, captchaValue: String): void;
		
		/**
		 * Tells us whether the synchronizer is currently connected to its remote reader client or not.
		 * @return true if connected, false otherwise
		 */
		function get connected(): Boolean;
			
		/**
		 *	Sync up all feeds and read/unread items between the local Snackr database and the external feed reader
		 *	@param feeds The list of Snackr feeds to sync with the external reader.
		 */
		function synchronizeAll(): void;
		
		/**
		 *	Return the list of feeds present in the external feed reader.
		 *	@param callback Called on completion - takes one parameter, an ArrayCollection containing the urls of
		 *                  the RSS feeds as Strings
		 */
		function getFeeds(callback: Function): void;
		
		/**
			Add a feed to the external feed reader.
			@param feedURL The url of the feed to add
		*/
		function addFeed(feedURL: String): void;
		
		/**
			Remove a feed from the external feed reader.
			@param feedURL The URL of the feed to remove
		*/
		function deleteFeed(feedURL: String): void;
		
		/**
		 *	Return the list of items marked as read on the external feed reader for the given feed.
		 *	@param callback Called on completion - takes one parameter, an ArrayCollection containing hashmaps
		 *                  with three values - "guid" contains the feed item's rss id, "itemURL" contains the
		 *                  feed item's url (since I don't trust the guid to always be present / accurate),
		 *                  and "feedURL" contains the url to the item's feed (so we can match it up when synchronizing) 
		*/
		function getReadItems(callback: Function): void;
		
		/**
		 *	Set an item as read on the external feed reader.
		 *	@param item The descriptor of the item to set as read. 
		 * 	@param feedURL The url of the feed the item came from
		*/
		function setItemRead(item: FeedItemDescriptor, feedURL: String): void;
		
		/**
		 * Creates a merged list that combines the feeds in Snackr and the feeds in the feed reader,
		 * then sets both tools to this new list of feeds.
		 */
		function mergeFeedLists(): void;
		
		/**
		 * Sets the list of feeds in the reader to the new list provided.
		 * @param newFeedList an array of strings containing the URLs of the new feeds
		 */
		function setFeedList(newFeedList: ArrayCollection): void;
	}
}