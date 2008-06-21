package tests
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	import flash.utils.getQualifiedClassName;
	
	import model.feeds.FeedItem;
	import model.feeds.FeedModel;
	import model.feeds.LoggingStatement;
	import model.feeds.readers.FeedReaderSynchronizerBase;
	import model.feeds.readers.PendingOperation;
	import model.logger.Logger;
	
	import mx.collections.ArrayCollection;

	public class FeedReaderSynchronizerBaseTester extends FeedReaderSynchronizerBase
	{
		private var _sqlConnection: SQLConnection;
		
		public function FeedReaderSynchronizerBaseTester()
		{
			var feedModel: FeedModel;
			var docRoot: File = File.documentsDirectory.resolvePath("TestHarness");
			docRoot.createDirectory();
			var dbFile: File = docRoot.resolvePath("TestDatabase.sql");
			try {
				_sqlConnection = new SQLConnection();
				_sqlConnection.open(dbFile);
				_sqlConnection.compact();
				loadTestData();
				feedModel = new FeedModel(_sqlConnection, this);
				super(_sqlConnection, feedModel);
			}
			catch (error: SQLError) {
				Logger.instance.log("Couldn't read or create the database file: " + error.details, Logger.SEVERITY_SERIOUS);
				throw error;
			}
			
		}
		
		public function testSync() : void {
			this.synchronizeAll();
		}
		
		private function loadTestData() : void {
			var loadOps: LoggingStatement = new LoggingStatement();
			loadOps.sqlConnection = _sqlConnection;
			loadOps.text = "DELETE FROM main.feeds WHERE 1=1";
			loadOps.execute();
			loadOps.text = "DELETE FROM main.feeditems WHERE 1=1";
			loadOps.execute();
			loadOps.text = "INSERT INTO main.feeds (url, name, homeURL, logoURL, priority, hasColor, color, lastFetched) " +
				"VALUES (:url, :name, :homeURL, :logoURL, :priority, :hasColor, :color, :lastFetched)";
			loadOps.parameters[":url"] = "http://www.shared.net/";
			loadOps.parameters[":name"] = "Shared Feed";
			loadOps.parameters[":homeURL"] = "";
			loadOps.parameters[":logoURL"] = "";
			loadOps.parameters[":priority"] = 5;
			loadOps.parameters[":hasColor"] = false;
			loadOps.parameters[":color"] = 0;
			loadOps.parameters[":lastFetched"] = null;
			loadOps.execute();			
			loadOps.parameters[":url"] = "http://www.inSnackrNotInReader.net/";
			loadOps.parameters[":name"] = "Feed In Snackr But Not In Reader";
			loadOps.parameters[":homeURL"] = "";
			loadOps.parameters[":logoURL"] = "";
			loadOps.parameters[":priority"] = 5;
			loadOps.parameters[":hasColor"] = false;
			loadOps.parameters[":color"] = 0;
			loadOps.parameters[":lastFetched"] = null;
			loadOps.execute();		
			loadOps.parameters[":url"] = "http://www.inSnackrNotInReaderButMarkedForAdd.net/";
			loadOps.parameters[":name"] = "Feed In Snackr, Not in Reader But Marked For Add";
			loadOps.parameters[":homeURL"] = "";
			loadOps.parameters[":logoURL"] = "";
			loadOps.parameters[":priority"] = 5;
			loadOps.parameters[":hasColor"] = false;
			loadOps.parameters[":color"] = 0;
			loadOps.parameters[":lastFetched"] = null;
			loadOps.execute();
			loadOps = new LoggingStatement();
			loadOps.sqlConnection = _sqlConnection;
			loadOps.text = "DELETE FROM main.pendingops WHERE 1=1";
			loadOps.execute();
			loadOps.text = "INSERT INTO main.pendingops (opCode, feedURL, itemURL) VALUES (:opCode, :feedURL, :itemURL)";
			loadOps.parameters[":opCode"] = PendingOperation.ADD_FEED_OPCODE;
			loadOps.parameters[":feedURL"] = "http://www.inSnackrNotInReaderButMarkedForAdd.net/";
			loadOps.parameters[":itemURL"] = null;
			loadOps.execute();
			loadOps.parameters[":opCode"] = PendingOperation.DELETE_FEED_OPCODE;
			loadOps.parameters[":feedURL"] = "http://www.inReaderNotInSnackrButMarkedForDelete.org/";
			loadOps.parameters[":itemURL"] = null;
			loadOps.execute();
			loadOps = new LoggingStatement();
			loadOps.sqlConnection = _sqlConnection;
			loadOps.text = "INSERT INTO main.feeditems (guid, feedId, link, wasRead) VALUES (:guid, :feedId, :link, :wasRead)";
			var selectOp: LoggingStatement = new LoggingStatement();
			selectOp.sqlConnection = _sqlConnection;
			selectOp.text = "SELECT feedId FROM main.feeds WHERE url = :url";
			selectOp.parameters[":url"] = "http://www.shared.net/";
			selectOp.execute();
			var result:SQLResult = selectOp.getResult();
			loadOps.parameters[":guid"] = "GUID1";
			loadOps.parameters[":feedId"] = result.data[0].feedId;
			loadOps.parameters[":link"] = "http://www.shared.net/entry1.html";
			loadOps.parameters[":wasRead"] = false;
			loadOps.execute();
			loadOps.parameters[":guid"] = "GUID2";
			loadOps.parameters[":feedId"] = result.data[0].feedId;
			loadOps.parameters[":link"] = "http://www.shared.net/entry2.html";
			loadOps.parameters[":wasRead"] = false;
			loadOps.execute();
			loadOps.parameters[":guid"] = "GUID3";
			loadOps.parameters[":feedId"] = result.data[0].feedId;
			loadOps.parameters[":link"] = "http://www.shared.net/alternateURL.html";
			loadOps.parameters[":wasRead"] = false;
			loadOps.execute();			
		}
		
		override public function getFeeds(callback: Function) : void {
			var feedList: ArrayCollection = new ArrayCollection();
			feedList.addItem("http://www.shared.net/");
			feedList.addItem("http://www.inReaderNotInSnackr.com/");
			feedList.addItem("http://www.inReaderNotInSnackrButMarkedForDelete.org/");
			callback(feedList);
		}
		
		override public function getReadItems(callback: Function) : void {
			var itemList: ArrayCollection = new ArrayCollection();
			var item:Object = new Object();
			item.guid = "";
			item.itemURL = "http://www.shared.net/entry1.html";
			item.feedURL = "http://www.shared.net/";
			itemList.addItem(item);
			item = new Object();
			item.guid = "GUID2";
			item.itemURL = "http://www.doesntExist.net/entry1.html";
			item.feedURL = "http://www.doesntExist.net/";
			itemList.addItem(item);
			item = new Object();
			item.guid = "GUID3";
			item.itemURL = "http://www.alternateURL.net/entry1.html";
			item.feedURL = "http://www.shared.net/";
			itemList.addItem(item);
			callback(itemList);
		}
		
		override public function addFeed(feedURL:String):void {
			Logger.instance.log("FeedReaderSynchronizerTester: addFeed: " + feedURL);
		}
		
		override public function deleteFeed(feedURL:String):void {
			Logger.instance.log("FeedReaderSynchronizerTester: deleteFeed: " + feedURL);
		}
		
		override public function setItemRead(item:FeedItem) : void {
			Logger.instance.log("FeedReaderSynchronizerTester: setItemRead: [guid: " + 
				item.guid + ", link: " + 
				item.link + 
				"]");
		}
	}
}