package model.feeds.readers
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;
	
	import model.feeds.FeedItem;
	import model.logger.Logger;
	import model.options.OptionsModel;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	/**
	 * IFeedReaderSynchronizer implementation that works with Google Reader.
	 * @author Rob Adams
	 */
	public class GoogleReaderSynchronizer extends FeedReaderSynchronizerBase
	{
		public static const AUTH_URL:String = "https://www.google.com/accounts/ClientLogin";
		public static const TOKEN_URL:String = "http://www.google.com/reader/api/0/token";
		public static const SUBSCRIPTION_EDIT_URL:String = "http://www.google.com/reader/api/0/subscription/edit";
		public static const GET_FEEDS_URL:String = "http://www.google.com/reader/api/0/subscription/list";
		public static const GET_READ_ITEMS_URL:String = "http://www.google.com/reader/atom/user/-/state/com.google/read";
		public static const TAG_EDIT_URL:String = "http://www.google.com/reader/api/0/edit-tag";
		public static const GET_FEED_ITEMS_URL:String = "http://www.google.com/reader/atom/feed/";
		
		private var _SID: String;
		private var optionsModel:OptionsModel;
		
		namespace atom = "http://www.w3.org/2005/Atom";
		namespace gr = "http://www.google.com/schemas/reader/atom/";
		
		public function GoogleReaderSynchronizer()
		{
			super();
			
		}
		
		public function authenticate(login: String, password: String, callback: Function = null): void {
			var authConnection:HTTPService = new HTTPService();
			authConnection.url = AUTH_URL;
			authConnection.method = "POST";
			authConnection.useProxy = false;
			authConnection.resultFormat = "text";
			var request:Object = new Object;
			request.service = "reader";
			request.source = SNACKR_CLIENT_ID;
			request.Email = login;
			request.Passwd = password;
			authConnection.request = request;
			authConnection.addEventListener(ResultEvent.RESULT, function handleAuthResultEvent(event: ResultEvent): void {
				var result:String = String(event.result);
				//manually parsing out the SID name/value pair
				var tokens:Array = result.split(/[\n=]/);
				for(var i:int = 0; i < tokens.length; i++) {
					if((tokens[i] == "SID") && (i+1 != tokens.length)) {
						_SID = tokens[i+1];
						break;
					}
				}
				Logger.instance.log("Authentication successful, result: " + result, Logger.SEVERITY_DEBUG);
			});
			authConnection.addEventListener(FaultEvent.FAULT, function handleAuthFaultEvent(event: FaultEvent): void {
				Logger.instance.log("GoogleReaderSynchronizer: Authentication failed.", Logger.SEVERITY_NORMAL);
			});
			if(callback != null) {
				authConnection.addEventListener(ResultEvent.RESULT, callback);
				authConnection.addEventListener(FaultEvent.FAULT, callback);
			}
			authConnection.send();
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
			var headers:Array = new Array(new URLRequestHeader("Cookie", "SID=" + _SID));
			return headers;
		}
		
		public function get SID(): String {
			return _SID;
		}
		
		override public function getFeeds(callback: Function): void {
			var getFeedsRequest:URLRequest = new URLRequest();
			getFeedsRequest.url = GET_FEEDS_URL + "?output=xml&client=" + SNACKR_CLIENT_ID;
			getFeedsRequest.userAgent = SNACKR_CLIENT_ID;
			getFeedsRequest.manageCookies = false;
			getFeedsRequest.requestHeaders = getAuthenticationHeaders();
			var getFeedsConnection:URLLoader = new URLLoader();
			getFeedsConnection.addEventListener(Event.COMPLETE, function handleGetFeedsResult(event:Event):void {
				Logger.instance.log("Retrieved feeds: " + event.target.data, Logger.SEVERITY_DEBUG);
				callback(processGetFeedsResult(XML(event.target.data)));
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
				feedList[i] = item.replace("feed/", "");
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
				});
				deleteConnection.load(deleteRequest);
			});
		}
		
		override public function getReadItems(callback: Function): void {
			var getReadItemsRequest:URLRequest = new URLRequest();
			getReadItemsRequest.url = GET_READ_ITEMS_URL + "?client=" + SNACKR_CLIENT_ID;
			getReadItemsRequest.userAgent = SNACKR_CLIENT_ID;
			getReadItemsRequest.manageCookies = false;
			getReadItemsRequest.requestHeaders = getAuthenticationHeaders();
			var getReadItemsConnection:URLLoader = new URLLoader();
			getReadItemsConnection.addEventListener(Event.COMPLETE, function handleGetReadItemsResult(event:Event):void {
				callback(processGetReadItemsResult(XML(event.target.data)));
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
			var readItemsFeedsXML:XMLList = resultXML.entry.link.@href;
			var itemList:Array = new Array(readItemsIDsXML.length());
			var i:int = 0;
			for each (var guid:String in readItemsIDsXML) {
				var item:Object = new Object();
				item.guid = guid;
				itemList[i] = item;
				i++;
			}
			i = 0;
			for each (var feedURL:String in readItemsFeedsXML) {
				itemList[i].feedURL = feedURL;
				i++;
			}
			return new ArrayCollection(itemList);
		}
		
		override public function setItemRead(item:FeedItem):void {
			//because the Google API can only identify feeds by its own rewriting of the feed's guid,
			//we need to retrieve that guid from Google Reader before we can set the read state
			var getFeedItemsRequest:URLRequest = new URLRequest();
			getFeedItemsRequest.url = GET_FEED_ITEMS_URL + item.feed.url + "?client=" + SNACKR_CLIENT_ID;
			getFeedItemsRequest.userAgent = SNACKR_CLIENT_ID;
			getFeedItemsRequest.manageCookies = false;
			getFeedItemsRequest.requestHeaders = getAuthenticationHeaders();
			var getFeedItemsConnection:URLLoader = new URLLoader();
			getFeedItemsConnection.addEventListener(Event.COMPLETE, function handleGetFeedsResult(event:Event):void {
				use namespace atom;
				
				//extract Google Reader's guid using the feed item's url
				var resultXML:XML = XML(event.target.data);
				var grGuid:String = resultXML.entry.(link.@href == item.link).id;
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
						Logger.instance.log("GoogleReaderSynchronizer: setItemRead(): " + item, Logger.SEVERITY_NORMAL);
					});
					setItemReadConnection.addEventListener(IOErrorEvent.IO_ERROR, function handleSetItemReadFail(event:IOErrorEvent): void {
						Logger.instance.log("GoogleReaderSynchronizer: setItemRead() failed: " + item, Logger.SEVERITY_NORMAL);
					});
					setItemReadConnection.load(setItemReadRequest);
				});
			});
			getFeedItemsConnection.addEventListener(IOErrorEvent.IO_ERROR, function handleGetFeedsFault(event:IOErrorEvent):void {
				Logger.instance.log("GoogleReaderSynchronizer: setItemRead() failed: " + event.text, Logger.SEVERITY_NORMAL);
			});
			getFeedItemsConnection.load(getFeedItemsRequest);
						
		}
	}
}