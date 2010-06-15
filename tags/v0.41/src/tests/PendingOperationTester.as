package tests
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	
	import model.feeds.FeedModel;
	import model.feeds.LoggingStatement;
	import model.feeds.readers.PendingOperation;
	import model.feeds.readers.PendingOperationModel;
	import model.logger.Logger;
	
	import mx.collections.ArrayCollection;
	
	public class PendingOperationTester
	{
		private var _sqlConnection: SQLConnection;
		private var _pendingOpModel: PendingOperationModel;
		
		public function PendingOperationTester()
		{
			var docRoot: File = File.documentsDirectory.resolvePath("TestHarness");
			docRoot.createDirectory();
			var dbFile: File = docRoot.resolvePath("TestDatabase.sql");
			try {
				_sqlConnection = new SQLConnection();
				_sqlConnection.open(dbFile);
				_sqlConnection.compact();
				var feedModel: FeedModel = new FeedModel(_sqlConnection);
			}
			catch (error: SQLError) {
				Logger.instance.log("Couldn't read or create the database file: " + error.details, Logger.SEVERITY_SERIOUS);
				throw error;
			}
		}
		
		private function loadTestData() : void {
			var loadOps: LoggingStatement = new LoggingStatement();
			loadOps.sqlConnection = _sqlConnection;
			loadOps.text = "DELETE FROM main.feeds WHERE 1=1";
			loadOps.execute();
			loadOps.text = "DELETE FROM main.feeditems WHERE 1=1";
			loadOps.execute();
			loadOps = new LoggingStatement();
			loadOps.sqlConnection = _sqlConnection;
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
				
			loadOps = new LoggingStatement();
			loadOps.sqlConnection = _sqlConnection;
			loadOps.text = "DELETE FROM main.pendingops WHERE 1=1";
			loadOps.execute();
			loadOps.text = "INSERT INTO main.pendingops (opCode, feedURL, feedItemGuid) VALUES (:opCode, :feedURL, :feedItemGuid)";
			loadOps.parameters[":opCode"] = PendingOperation.ADD_FEED_OPCODE;
			loadOps.parameters[":feedURL"] = "http://www.boingboing.com/";
			loadOps.parameters[":feedItemGuid"] = null;
			loadOps.execute();
			loadOps.parameters[":opCode"] = PendingOperation.DELETE_FEED_OPCODE;
			loadOps.parameters[":feedURL"] = "http://www.slashdot.org/";
			loadOps.parameters[":feedItemGuid"] = null;
			loadOps.execute();
			loadOps.parameters[":opCode"] = PendingOperation.MARK_READ_OPCODE;
			loadOps.parameters[":feedURL"] = "http://www.boingboing.com/post1.html";
			loadOps.parameters[":feedItemGuid"] = "GUID1";
			loadOps.execute();
		}
		
		public function testCleanLoad() : void {
			_pendingOpModel = new PendingOperationModel(_sqlConnection);
			Logger.instance.log("Clean load operations: " + printOpsList(_pendingOpModel.operations));
			
		}
		
		public function testRetrieveOps() : void {
			loadTestData();
			_pendingOpModel = new PendingOperationModel(_sqlConnection);
			Logger.instance.log("Retrieve operations: " + printOpsList(_pendingOpModel.operations));
		}
		
		private function printOpsList(opsList: ArrayCollection) : String {
			var printList: String = "";
			for(var i:int=0; i < opsList.length; i++) {
				var pendingOp: PendingOperation = PendingOperation(opsList.getItemAt(i));
				printList += ("PendingOperation: opCode: " + pendingOp.opCode + ", feedURL: " + pendingOp.feedURL + ", feedDescriptor: " + pendingOp.feedItemDescriptor + "\n");
				
			}
			return printList;
		}
		
		public function testAddOp() : void {
			loadTestData();
			_pendingOpModel = new PendingOperationModel(_sqlConnection);
			_pendingOpModel.addOperation(new PendingOperation(PendingOperation.ADD_FEED_OPCODE, "http://www.test.com/"));
			Logger.instance.log("Added operations: " + printOpsList(_pendingOpModel.operations));
		}
		
		public function testClearOps() : void {
			loadTestData();
			_pendingOpModel = new PendingOperationModel(_sqlConnection);
			_pendingOpModel.clearOperations();
			Logger.instance.log("Cleared operations: " + printOpsList(_pendingOpModel.operations));
		}

	}
}