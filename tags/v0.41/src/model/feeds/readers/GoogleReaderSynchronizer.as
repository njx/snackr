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
	import flash.data.SQLConnection;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;
	import flash.system.System;
	
	import model.feeds.FeedItemDescriptor;
	import model.feeds.FeedModel;
	import model.logger.Logger;
	import model.options.OptionsModel;
	
	import mx.collections.ArrayCollection;
	
	/**
	 * IFeedReaderSynchronizer implementation that works with Google Reader.
	 * @author Rob Adams
	 */
	public class GoogleReaderSynchronizer extends FeedReaderSynchronizerBase
	{
		private static const AUTH_URL:String = "https://www.google.com/accounts/ClientLogin";
		private static const TOKEN_URL:String = "http://www.google.com/reader/api/0/token";
		private static const SUBSCRIPTION_EDIT_URL:String = "http://www.google.com/reader/api/0/subscription/edit";
		private static const GET_FEEDS_URL:String = "http://www.google.com/reader/api/0/subscription/list";
		private static const GET_READ_ITEMS_URL:String = "http://www.google.com/reader/atom/user/-/state/com.google/read";
		private static const TAG_EDIT_URL:String = "http://www.google.com/reader/api/0/edit-tag";
		private static const GET_FEED_ITEMS_URL:String = "http://www.google.com/reader/atom/feed/";
		
		private var _authToken: String;
		private var optionsModel:OptionsModel;
		
		private var _connected: Boolean = false;
		
		namespace atom = "http://www.w3.org/2005/Atom";
		namespace gr = "http://www.google.com/schemas/reader/atom/";
		
		public function GoogleReaderSynchronizer(sqlConnection: SQLConnection, feedModel: FeedModel)
		{
			super(sqlConnection, feedModel);
			
		}
		
		override public function authenticateCaptcha(login: String, password: String, captchaToken: String, captchaValue: String): void {
			//TODO: Figure out if/when the cookie will expire with the server and call authenticate()
			//again automatically if that occurs
			var authRequest:URLRequest = new URLRequest();
			authRequest.url = AUTH_URL;
			authRequest.method = "POST";
			var variables: URLVariables = new URLVariables();
			variables.service = "reader";
			variables.source = SNACKR_CLIENT_ID;
			variables.accountType = "GOOGLE";
			variables.Email = login;
			variables.Passwd = password;
			if(captchaToken != null)
				variables.logintoken = captchaToken;
			if(captchaValue != null)
				variables.logincaptcha = captchaValue;
			authRequest.data = variables;
			var authConnection: URLLoader = new URLLoader();
			authConnection.addEventListener(Event.COMPLETE, function handleAuthResultEvent(event: Event): void {
				var result:String = String(event.target.data);
				//manually parsing out the SID name/value pair
				var tokens:Array = result.split(/[\n=]/);
				for(var i:int = 0; i < tokens.length; i++) {
					if((tokens[i] == "Auth") && (i+1 != tokens.length)) {
						_authToken = tokens[i+1];
						connected = true;
						break;
					}
				}
				Logger.instance.log("Authentication successful, result: " + result, Logger.SEVERITY_DEBUG);
				dispatchEvent(new SynchronizerEvent(SynchronizerEvent.AUTH_SUCCESS));
			});
			var accountsResponder : GoogleAccountsResponder = new GoogleAccountsResponder();
			authConnection.addEventListener(IOErrorEvent.IO_ERROR, accountsResponder.handleAuthFaultEvent);
			authConnection.addEventListener(HTTPStatusEvent.HTTP_STATUS, accountsResponder.handleAuthStatusEvent);
			accountsResponder.addEventListener(SynchronizerEvent.AUTH_BAD_CREDENTIALS, handleAuthFail);
			accountsResponder.addEventListener(SynchronizerEvent.AUTH_CAPTCHA_CHALLENGE, handleAuthFail);
			accountsResponder.addEventListener(SynchronizerEvent.AUTH_FAILURE, handleAuthFail);
			
			authConnection.load(authRequest);
		}
		
		private function handleAuthFail(syncEvent: SynchronizerEvent) : void {
			connected = false;
			dispatchEvent(syncEvent);
		}
		
		[Bindable(event="connectedChanged")]
		override public function get connected() : Boolean {
			return _connected;
		}
		
		public function set connected(value: Boolean) : void {
			if(_connected != value) {
				_connected = value;
				dispatchEvent(new Event("connectedChanged"));
			}
		}
		
		/**
		 * Retrieves a "token" string that all Google Reader API calls that make edits require.
		 * @param callback a function that accepts a single String argument.
		 * 					The function will receive the token if the call was successful, null if it failed.
		 */
		private function getToken(callback: Function): void {
			//because AIR manages cookies by default and there is no way to turn this off via HTTPService,
			//I had to use URLLoader directly instead. Maybe there is some way to set a cookie programmatically
			//in the HTML engine but I can't figure out how and HTTPService isn't worth the bother.
			var tokenRequest:URLRequest = new URLRequest();
			tokenRequest.url = TOKEN_URL + "?client=" + SNACKR_CLIENT_ID;
			tokenRequest.userAgent = SNACKR_CLIENT_ID;
			tokenRequest.manageCookies = false;
			tokenRequest.requestHeaders = getAuthenticationHeaders();
			var tokenConnection:URLLoader = new URLLoader();
			tokenConnection.addEventListener(Event.COMPLETE, function handleTokenResult(event:Event):void {
				Logger.instance.log("Got token: " + event.target.data, Logger.SEVERITY_DEBUG);
				callback(event.target.data);
			});
			tokenConnection.addEventListener(IOErrorEvent.IO_ERROR, function handleTokenFault(event:IOErrorEvent):void {
				Logger.instance.log("GoogleReaderSynchronizer: getToken() failed: " + event.text, Logger.SEVERITY_NORMAL);
				callback(null);
			});
			tokenConnection.load(tokenRequest);
		}
		
		private function getAuthenticationHeaders(): Array {
			var headers:Array = new Array(new URLRequestHeader("Authorization", "GoogleLogin auth=" + _authToken));
			return headers;
		}
		
		public function get authToken(): String {
			return _authToken;
		}
		
		override public function getFeeds(callback: Function): void {
			var getFeedsRequest:URLRequest = new URLRequest();
			getFeedsRequest.url = GET_FEEDS_URL + "?output=xml&client=" + SNACKR_CLIENT_ID;
			getFeedsRequest.userAgent = SNACKR_CLIENT_ID;
			getFeedsRequest.manageCookies = false;
			getFeedsRequest.requestHeaders = getAuthenticationHeaders();
			var getFeedsConnection:URLLoader = new URLLoader();
			getFeedsConnection.addEventListener(Event.COMPLETE, function handleGetFeedsResult(event:Event):void {
				var resultXML: XML = XML(event.target.data);
				callback(processGetFeedsResult(resultXML));
				System.disposeXML(resultXML);
			});
			getFeedsConnection.addEventListener(IOErrorEvent.IO_ERROR, function handleGetFeedsFault(event:IOErrorEvent):void {
				Logger.instance.log("GoogleReaderSynchronizer: getFeeds() failed: " + event.text, Logger.SEVERITY_NORMAL);
				callback(null);
			});
			getFeedsConnection.load(getFeedsRequest);
		}
		
		private function processGetFeedsResult(resultXML:XML): ArrayCollection {
			var feedListXML:XMLList = new XMLList();
			//yank out all the feed ids, which contain the feed URLs
			feedListXML = resultXML.list.object.string.(@name=="id");
			var feedList:Array = new Array(feedListXML.length());
			var i:int = 0;
			for each (var item:String in feedListXML) {
				//Google Reader puts a feed/ in front of each URL to create its feed ids so we need to strip that off
				feedList[i] = item.replace(/^feed\//, "");
				i++;
			}
			return new ArrayCollection(feedList);
		}
		
		override public function addFeed(feedURL:String):void {
			getToken(function retrieveToken(token:String): void {
				var addRequest:URLRequest = new URLRequest();
				addRequest.url = SUBSCRIPTION_EDIT_URL;
				addRequest.userAgent = SNACKR_CLIENT_ID;
				addRequest.manageCookies = false;
				addRequest.requestHeaders = getAuthenticationHeaders();
				addRequest.method = "POST";
				var request:URLVariables = new URLVariables();
				request.s = "feed/" + feedURL;
				request.ac = "subscribe";
				request.T = token;
				addRequest.data = request;
				var addConnection:URLLoader = new URLLoader();
				addConnection.addEventListener(Event.COMPLETE, function handleAddSuccess(event:Event): void {
					Logger.instance.log("GoogleReaderSynchronizer: Added feed: " + feedURL, Logger.SEVERITY_DEBUG);
				});
				addConnection.addEventListener(IOErrorEvent.IO_ERROR, function handleAddFail(event:IOErrorEvent): void {
					Logger.instance.log("GoogleReaderSynchronizer: Add feed failed: " + feedURL, Logger.SEVERITY_NORMAL);
					markFeedForAdd(feedURL);
				});
				addConnection.load(addRequest);
			});
		}
		
		override public function deleteFeed(feedURL:String):void	{
			getToken(function retrieveToken(token:String): void {
				var deleteRequest:URLRequest = new URLRequest();
				deleteRequest.url = SUBSCRIPTION_EDIT_URL;
				deleteRequest.userAgent = SNACKR_CLIENT_ID;
				deleteRequest.manageCookies = false;
				deleteRequest.requestHeaders = getAuthenticationHeaders();
				deleteRequest.method = "POST";
				var request:URLVariables = new URLVariables();
				request.s = "feed/" + feedURL;
				request.ac = "unsubscribe";
				request.T = token;
				deleteRequest.data = request;
				var deleteConnection:URLLoader = new URLLoader();
				deleteConnection.addEventListener(Event.COMPLETE, function handleDeleteSuccess(event:Event): void {
					Logger.instance.log("GoogleReaderSynchronizer: Deleted feed: " + feedURL, Logger.SEVERITY_DEBUG);
				});
				deleteConnection.addEventListener(IOErrorEvent.IO_ERROR, function handleDeleteFail(event:IOErrorEvent): void {
					Logger.instance.log("GoogleReaderSynchronizer: Delete feed failed: " + feedURL, Logger.SEVERITY_NORMAL);
					markFeedForDelete(feedURL);
				});
				deleteConnection.load(deleteRequest);
			});
		}
		
		override public function getReadItems(callback: Function): void {
			getReadItemsHelper(callback, new ArrayCollection, null);
		}
		
		private function getReadItemsHelper(callback: Function, readItems: ArrayCollection, continuationToken: String) : void {
			var getReadItemsRequest:URLRequest = new URLRequest();
			getReadItemsRequest.url = GET_READ_ITEMS_URL;
			getReadItemsRequest.userAgent = SNACKR_CLIENT_ID;
			getReadItemsRequest.manageCookies = false;
			var urlVariables : URLVariables = new URLVariables;
			urlVariables.client = SNACKR_CLIENT_ID;
			if(continuationToken != null)
				urlVariables.c = continuationToken;
			getReadItemsRequest.data = urlVariables;
			getReadItemsRequest.requestHeaders = getAuthenticationHeaders();
			var getReadItemsConnection:URLLoader = new URLLoader();
			getReadItemsConnection.addEventListener(Event.COMPLETE, function handleGetReadItemsResult(event:Event):void {
				use namespace atom;
				
				var resultXML : XML = XML(event.target.data);
				var resultArray : ArrayCollection = processGetReadItemsResult(resultXML);
				System.disposeXML(resultXML);
				for each (var obj: Object in resultArray) {
					readItems.addItem(obj);
				}
				var newContinutationToken : String = resultXML.child(new QName(gr, "continuation"));
				if(newContinutationToken == "")
					callback(readItems);
				else
					getReadItemsHelper(callback, readItems, newContinutationToken);
			});
			getReadItemsConnection.addEventListener(IOErrorEvent.IO_ERROR, function handleGetReadItemsFault(event:IOErrorEvent):void {
				Logger.instance.log("GoogleReaderSynchronizer: getReadItems() failed: " + event.text, Logger.SEVERITY_NORMAL);
				callback(null);
			});
			getReadItemsConnection.load(getReadItemsRequest);
		}
		
		private function processGetReadItemsResult(resultXML: XML): ArrayCollection {
			use namespace atom;
			
			//Google Reader rewrites the ids and stores the original in the gr:original-id attribute, so we're using that instead
			var readItemsIDsXML:XMLList = resultXML.entry.id.attribute(new QName(gr, "original-id"));
			var readItemsURLsXML:XMLList = resultXML.entry.link.(@rel == "alternate").@href;
			var readItemsFeedURLsXML:XMLList = resultXML.entry.source.attribute(new QName(gr, "stream-id"));
			var itemList:Array = new Array(readItemsIDsXML.length());
			var i:int = 0;
			for each (var guid:String in readItemsIDsXML) {
				var item:Object = new Object();
				item.guid = guid;
				itemList[i] = item;
				i++;
			}
			i = 0;
			for each (var itemURL:String in readItemsURLsXML) {
				itemList[i].itemURL = itemURL;
				i++;
			}
			i = 0;
			for each (var feedURL: String in readItemsFeedURLsXML) {
				//kill the feed/ in front of the feed url that google reader adds to make its stream-id
				itemList[i].feedURL = feedURL.replace(/^feed\//, "");
				i++;
			}
			return new ArrayCollection(itemList);
		}
		
		/**
		 * @param item Note that both the link property and the url property of the feed object
		 * 			MUST be set for this method to work correctly.
		 */
		override public function setItemRead(item:FeedItemDescriptor, feedURL: String):void {
			setItemReadHelper(item, feedURL, null);
		}
		
		private function setItemReadHelper(item:FeedItemDescriptor, feedURL: String, continuationToken: String) : void {
			//because the Google API can only identify feeds by its own rewriting of the feed's guid,
			//we need to retrieve that guid from Google Reader before we can set the read state
			var getFeedItemsRequest:URLRequest = new URLRequest();
			getFeedItemsRequest.url = GET_FEED_ITEMS_URL + escape(feedURL);
			
			var urlVariables: URLVariables = new URLVariables();
			urlVariables.client = SNACKR_CLIENT_ID;
			if(continuationToken != null) 
				urlVariables.c = continuationToken;	
			getFeedItemsRequest.data = urlVariables;		
			getFeedItemsRequest.userAgent = SNACKR_CLIENT_ID;
			getFeedItemsRequest.manageCookies = false;
			getFeedItemsRequest.requestHeaders = getAuthenticationHeaders();
			var getFeedItemsConnection:URLLoader = new URLLoader();
			getFeedItemsConnection.addEventListener(Event.COMPLETE, function handleGetFeedsResult(event:Event):void {
				use namespace atom;
				
				//extract Google Reader's guid using the feed item's url
				var resultXML:XML = XML(event.target.data);
				var entriesXMLList: XMLList = resultXML.entry;
				var newContinuationToken : String = resultXML.child(new QName(gr, "continuation"));
				var grGuid:String = "";
				//had to iterate through these manually since sometimes the link field doesn't appear in an entry
				//and I can't figure out how to make that work in e4x
				for each (var entry:XML in entriesXMLList) {
					if(entry.id.attribute(new QName(gr, "original-id")) == item.guid || (entry.link != null && (entry.link.(@rel == "alternate").@href == item.link))) {
						grGuid = entry.id;
						break;
					}
				}
				System.disposeXML(resultXML);
				//if we found the guid, try setting the read status of the item
				if(grGuid != "") {
					getToken(function retrieveToken(token:String): void {
						var setItemReadRequest:URLRequest = new URLRequest();
						setItemReadRequest.url = TAG_EDIT_URL;
						setItemReadRequest.userAgent = SNACKR_CLIENT_ID;
						setItemReadRequest.manageCookies = false;
						setItemReadRequest.requestHeaders = getAuthenticationHeaders();
						setItemReadRequest.method = "POST";
						var request:URLVariables = new URLVariables();
						request.i = grGuid;
						request.a = "user/-/state/com.google/read";
						request.ac = "edit";
						request.T = token;
						setItemReadRequest.data = request;
						var setItemReadConnection:URLLoader = new URLLoader();
						setItemReadConnection.addEventListener(Event.COMPLETE, function handleSetItemReadSuccess(event:Event): void {
							Logger.instance.log("GoogleReaderSynchronizer: setItemRead(): " + item, Logger.SEVERITY_DEBUG);
						});
						setItemReadConnection.addEventListener(IOErrorEvent.IO_ERROR, function handleSetItemReadFail(event:IOErrorEvent): void {
							Logger.instance.log("GoogleReaderSynchronizer: setItemRead() failed: " + item, Logger.SEVERITY_NORMAL);
							Logger.instance.log("setItemRead error: " + event.toString(), Logger.SEVERITY_DEBUG);
							markItemForReadStatusAssignment(feedURL, item);
						});
						setItemReadConnection.load(setItemReadRequest);
					});
				}
				//if not and there's a continuation token, try the next set
				else if(newContinuationToken != null && newContinuationToken != "") {
					setItemReadHelper(item, feedURL, newContinuationToken);
				}
				//we couldn't find the guid for some reason, so try again later
				else {
					Logger.instance.log("GoogleReaderSynchronizer: setItemRead couldn't find the guid for the item: " + item, Logger.SEVERITY_NORMAL);
					markItemForReadStatusAssignment(feedURL, item);
				}
			});
			getFeedItemsConnection.addEventListener(IOErrorEvent.IO_ERROR, function handleGetFeedsFault(event:IOErrorEvent):void {
				Logger.instance.log("GoogleReaderSynchronizer: setItemRead() failed: " + event.text, Logger.SEVERITY_NORMAL);
				Logger.instance.log("setItemRead error: " + event.toString(), Logger.SEVERITY_DEBUG);
				markItemForReadStatusAssignment(feedURL, item);
			});
			getFeedItemsConnection.load(getFeedItemsRequest);
		}
	}
}