package tests
{
	import flash.data.SQLConnection;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	
	import model.feeds.LoggingStatement;
	import model.feeds.readers.PendingOperation;
	import model.feeds.readers.PendingOperationModel;
	import model.logger.Logger;
	
	import mx.collections.ArrayCollection;
	
	public class PendingOperationTester
	{
		var _sqlConnection: SQLConnection;
		var _pendingOpModel: PendingOperationModel;
		
		public function PendingOperationTester()
		{
			var docRoot: File = File.documentsDirectory.resolvePath("TestHarness");
			docRoot.createDirectory();
			var dbFile: File = docRoot.resolvePath("TestDatabase.sql");
			try {
				_sqlConnection = new SQLConnection();
				_sqlConnection.open(dbFile);
				_sqlConnection.compact();
			}
			catch (error: SQLError) {
				Logger.instance.log("Couldn't read or create the database file: " + error.details, Logger.SEVERITY_SERIOUS);
				throw error;
			}
		}
		
		private function loadTestData() : void {
			var loadOps: LoggingStatement = new LoggingStatement();
			loadOps.sqlConnection = _sqlConnection;
			loadOps.text = "DELETE FROM main.pendingops WHERE 1=1";
			loadOps.execute();
			loadOps.text = "INSERT INTO main.pendingops (opCode, feedURL, itemURL) VALUES (:opCode, :feedURL, :itemURL)";
			loadOps.parameters[":opCode"] = PendingOperation.ADD_FEED_OPCODE;
			loadOps.parameters[":feedURL"] = "http://www.boingboing.com/";
			loadOps.parameters[":itemURL"] = null;
			loadOps.execute();
			loadOps.parameters[":opCode"] = PendingOperation.DELETE_FEED_OPCODE;
			loadOps.parameters[":feedURL"] = "http://www.slashdot.org/";
			loadOps.parameters[":itemURL"] = null;
			loadOps.execute();
			loadOps.parameters[":opCode"] = PendingOperation.MARK_READ_OPCODE;
			loadOps.parameters[":feedURL"] = "http://www.boingboing.com/post1.html";
			loadOps.parameters[":itemURL"] = "GUID";
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
				printList += ("PendingOperation: opCode: " + pendingOp.opCode + ", feedURL: " + pendingOp.feedURL + ", itemURL: " + pendingOp.itemURL + "\n");
				
			}
			return printList;
		}
		
		public function testAddOp() : void {
			loadTestData();
			_pendingOpModel = new PendingOperationModel(_sqlConnection);
			_pendingOpModel.addOperation(new PendingOperation(PendingOperation.ADD_FEED_OPCODE, "http://www.test.com/", "TEST_GUID"));
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