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

		public function synchronizeAll(): void
		{
			Logger.instance.log("NullFeedReaderSynchronizer: synchronizeAll", Logger.SEVERITY_DEBUG);
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