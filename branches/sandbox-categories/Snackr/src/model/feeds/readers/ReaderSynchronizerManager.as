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
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import model.feeds.FeedModel;
	
	/**
	 * Holds the static singleton instance of the global reader synchronizer.
	 * @author Rob Adams
	 */
	public class ReaderSynchronizerManager
	{
		/**
		 * How long to wait between syncs with the external feed reader program.
		 */
		static private const FEED_READER_SYNC_INTERVAL : Number = 600000;
		
		[Bindable]
		public static var reader: IFeedReaderSynchronizer;
		
		/**
		 * Timer that causes the feed reader synchronizer to poll its reader for remote
		 * changes.
		 */
		private static var _feedReaderSynchronizeTimer: Timer = null;
		
		public static function initializeGoogleReaderSynchronizer(feedModel: FeedModel) : void {
			reader = new GoogleReaderSynchronizer(feedModel.sqlConnection, feedModel);
			initializeTimer();
		}
		
		public static function initializeNullReaderSynchronizer() : void {
			reader = new NullFeedReaderSynchronizer;
			initializeTimer();
		}
		
		public static function startSyncTimer() : void {
			initializeTimer();
			_feedReaderSynchronizeTimer.start();
		}
		
		public static function stopSyncTimer() : void {
			initializeTimer();
			_feedReaderSynchronizeTimer.stop();
		}

		private static function initializeTimer() : void {
			if(_feedReaderSynchronizeTimer == null) {
				_feedReaderSynchronizeTimer = new Timer(FEED_READER_SYNC_INTERVAL);
				_feedReaderSynchronizeTimer.addEventListener(TimerEvent.TIMER, handleSyncTimerEvent);
				_feedReaderSynchronizeTimer.start();
			}			
		}
		
		private static function handleSyncTimerEvent(event: TimerEvent) : void {
			if(reader != null)
				reader.synchronizeAll();
		}
	}
}