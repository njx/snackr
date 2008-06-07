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
	import flash.events.EventDispatcher;
	
	import model.feeds.Feed;
	import model.feeds.FeedItem;
	
	import mx.collections.ArrayCollection;

	/**
	 *	Provides common functionality used by many feed reader synchronizers.
	 *	FeedReaderSynchronizerBase is not a complete implementation of IFeedReaderSynchronizer
	 *	itself - see its subclasses for implementations for specific reader programs.
	 *	@author Rob Adams
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