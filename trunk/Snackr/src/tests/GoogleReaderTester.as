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

package tests
{
	import flash.data.SQLConnection;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.filesystem.File;
	
	import model.feeds.FeedItemDescriptor;
	import model.feeds.FeedModel;
	import model.feeds.readers.GoogleReaderSynchronizer;
	import model.feeds.readers.ReaderSynchronizerManager;
	import model.feeds.readers.SynchronizerEvent;
	import model.logger.Logger;
	
	import mx.collections.ArrayCollection;
	
	public class GoogleReaderTester
	{
		private var _reader: GoogleReaderSynchronizer;
		
		public function GoogleReaderTester()
		{
			var sqlConnection:SQLConnection;
			var feedModel: FeedModel;
			var docRoot: File = File.documentsDirectory.resolvePath("TestHarness");
			docRoot.createDirectory();
			var dbFile: File = docRoot.resolvePath("TestDatabase.sql");
			try {
				sqlConnection = new SQLConnection();
				sqlConnection.open(dbFile);
				sqlConnection.compact();
				feedModel = new FeedModel(sqlConnection);
			}
			catch (error: SQLError) {
				Logger.instance.log("Couldn't read or create the database file: " + error.details, Logger.SEVERITY_SERIOUS);
				throw error;
			}
			ReaderSynchronizerManager.initializeGoogleReaderSynchronizer(feedModel);
			_reader = GoogleReaderSynchronizer(ReaderSynchronizerManager.reader);
		}
		
		public function testAdd(): void {
			_reader.addEventListener(SynchronizerEvent.AUTH_SUCCESS, function callback(event: Event): void {
				Logger.instance.log("GoogleReaderTester: Authentication successful, SID: " + _reader.SID);
				_reader.addFeed("http://rss.slashdot.org/Slashdot/slashdot");
			});
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n");
		}
		
		public function testDelete(): void {
			_reader.addEventListener(SynchronizerEvent.AUTH_SUCCESS, function callback(event: Event): void {
				Logger.instance.log("GoogleReaderTester: Authentication successful, SID: " + _reader.SID);
				_reader.deleteFeed("http://rss.slashdot.org/Slashdot/slashdot");
			});
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n");
		}
		
		public function testAuthenticationSuccess(): void {
			_reader.addEventListener(SynchronizerEvent.AUTH_SUCCESS, handleAuthSuccessTest);
			_reader.addEventListener(SynchronizerEvent.AUTH_BAD_CREDENTIALS, handleAuthSuccessTest);
			_reader.addEventListener(SynchronizerEvent.AUTH_FAILURE, handleAuthSuccessTest);			
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n");
		}
		
		private function handleAuthSuccessTest(event: SynchronizerEvent): void {
			Logger.instance.log("GoogleReaderTester.testAuthenticationSuccess: " + (event.type == SynchronizerEvent.AUTH_SUCCESS), Logger.SEVERITY_NORMAL);
			Logger.instance.log("GoogleReaderTester: SID: " + _reader.SID);
			if(event.type != SynchronizerEvent.AUTH_SUCCESS) {
				Logger.instance.log("GoogleReaderTester: testAuthenticationSuccess failed: " + event, Logger.SEVERITY_DEBUG);
			}
		}
		
		public function testAuthenticationFailure(): void {
			_reader.addEventListener(SynchronizerEvent.AUTH_SUCCESS, handleAuthFailureTest);
			_reader.addEventListener(SynchronizerEvent.AUTH_BAD_CREDENTIALS, handleAuthFailureTest);
			_reader.addEventListener(SynchronizerEvent.AUTH_FAILURE, handleAuthFailureTest);			
			_reader.authenticate("robadams@gmail.com","badpassword");
		}
		
		private function handleAuthFailureTest(event: SynchronizerEvent) : void {
			if(event.type == SynchronizerEvent.AUTH_BAD_CREDENTIALS) {
				Logger.instance.log("GoogleReaderTester: testAuthenticationFailure succeeded: " + event, Logger.SEVERITY_DEBUG);
			}
		}

		public function testGetFeeds(): void {
			_reader.addEventListener(SynchronizerEvent.AUTH_SUCCESS, function callback(event: Event): void {
				Logger.instance.log("GoogleReaderTester: Authentication successful, SID: " + _reader.SID);
				_reader.getFeeds(function (feedlist: ArrayCollection): void {
					Logger.instance.log("GoogleReaderTester: " + feedlist);
				});
			});
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n");
		}
		
		public function testGetReadItems(): void {
			_reader.addEventListener(SynchronizerEvent.AUTH_SUCCESS,function callback(event: Event): void {
				Logger.instance.log("GoogleReaderTester: Authentication successful, SID: " + _reader.SID);
				_reader.getReadItems(function (itemList: ArrayCollection): void {
					for each (var item:Object in itemList) {
						Logger.instance.log("GoogleReaderTester: testGetReadItems: " + item.guid + ", " + item.feedURL);
					}
				});
			});
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n");
		}		
		
		public function testSetItemRead(urlToRead:String, feedURLtoRead: String): void {	
			_reader.addEventListener(SynchronizerEvent.AUTH_SUCCESS, function callback(event: Event): void {
				Logger.instance.log("GoogleReaderTester: Authentication successful, SID: " + _reader.SID);
				_reader.getReadItems(function (itemList: ArrayCollection): void {
					for each (var item:Object in itemList) {
						Logger.instance.log("GoogleReaderTester: testSetItemRead: guid: " + item.guid + ", itemURL: " + item.itemURL + ", feedURL: " + item.feedURL);
					}
					_reader.setItemRead(new FeedItemDescriptor(null, urlToRead), feedURLtoRead);
				});
			});
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n");
		}

	}
}