package tests
{
	import flash.events.Event;
	
	import model.feeds.Feed;
	import model.feeds.FeedItem;
	import model.feeds.readers.GoogleReaderSynchronizer;
	import model.logger.Logger;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	public class GoogleReaderTester
	{
		private var _reader: GoogleReaderSynchronizer = new GoogleReaderSynchronizer();
		
		public function GoogleReaderTester()
		{
		}
		
		public function testAdd(): void {
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n",function callback(event: Event): void {
				Logger.instance.log("GoogleReaderTester: Authentication successful, SID: " + _reader.SID);
				_reader.addFeed("http://rss.slashdot.org/Slashdot/slashdot");
			});
		}
		
		public function testDelete(): void {
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n",function callback(event: Event): void {
				Logger.instance.log("GoogleReaderTester: Authentication successful, SID: " + _reader.SID);
				_reader.deleteFeed("http://rss.slashdot.org/Slashdot/slashdot");
			});
		}
		
		public function testAuthenticationSuccess(): void {
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n", function (event: Event): void {
				Logger.instance.log("GoogleReaderTester.testAuthenticationSuccess: " + (event is ResultEvent), Logger.SEVERITY_NORMAL);
				Logger.instance.log("GoogleReaderTester: SID: " + _reader.SID);
				if(event is FaultEvent) {
					var faultEvent: FaultEvent = FaultEvent(event);
					Logger.instance.log(faultEvent.fault.faultCode + " : " + faultEvent.fault.faultDetail + " : " + faultEvent.fault.faultString, Logger.SEVERITY_DEBUG);
				}
			});
		}
		
		public function testAuthenticationFailure(): void {
			_reader.authenticate("robadams@gmail.com","badpassword", function (event: Event): void {
				Logger.instance.log("GoogleReaderTester.testAuthenticationFailure: " + (event is FaultEvent), Logger.SEVERITY_NORMAL);		
			});
		}

		public function testGetFeeds(): void {
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n",function callback(event: Event): void {
				Logger.instance.log("GoogleReaderTester: Authentication successful, SID: " + _reader.SID);
				_reader.getFeeds(function (feedlist: ArrayCollection): void {
					Logger.instance.log("GoogleReaderTester: " + feedlist);
				});
			});
		}
		
		public function testGetReadItems(): void {
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n",function callback(event: Event): void {
				Logger.instance.log("GoogleReaderTester: Authentication successful, SID: " + _reader.SID);
				_reader.getReadItems(function (itemList: ArrayCollection): void {
					for each (var item:Object in itemList) {
						Logger.instance.log("GoogleReaderTester: testGetReadItems: " + item.guid + ", " + item.feedURL);
					}
				});
			});
		}		
		
		public function testSetItemRead(urlToRead:String): void {	
			_reader.authenticate("snackr.ticker@gmail.com","l0lca+pr0n",function callback(event: Event): void {
				Logger.instance.log("GoogleReaderTester: Authentication successful, SID: " + _reader.SID);
				_reader.getReadItems(function (itemList: ArrayCollection): void {
					for each (var item:Object in itemList) {
						Logger.instance.log("GoogleReaderTester: testSetItemRead: " + item.guid + ", " + item.feedURL);
					}
					var itemObject:Object = new Object();
					itemObject.link = urlToRead;
					var feedItem:FeedItem = new FeedItem(itemObject);
					var feed:Feed = new Feed(null, null);
					feed.url = "http://feeds.feedburner.com/adaptivepath";
					feedItem.feed = feed;
					_reader.setItemRead(feedItem);
				});
			});
		}

	}
}