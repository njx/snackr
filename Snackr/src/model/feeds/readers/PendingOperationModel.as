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
	
	import model.feeds.FeedStatements;
	import model.feeds.LoggingStatement;
	
	import mx.collections.ArrayCollection;
	
	/**
	 * Model class for managing the feed reader operations that are pending synchronization with the server.
	 * @author Rob Adams
	 */
	public class PendingOperationModel
	{
		private var _statements: FeedStatements;
		private var _sqlConnection: SQLConnection;
		private var _operations: ArrayCollection = new ArrayCollection();
		private var _opsListInvalid: Boolean = false;
		
		public function PendingOperationModel(sqlConnection: SQLConnection)
		{
			_statements = new FeedStatements(sqlConnection);
			_sqlConnection = sqlConnection;
			initializeDB();
		}
		
		private function initializeDB(): void {
			var createTable: LoggingStatement = new LoggingStatement();
			createTable.sqlConnection = _sqlConnection;
			createTable.text = 
				"CREATE TABLE IF NOT EXISTS main.pendingops (" +
				"	opId INTEGER PRIMARY KEY AUTOINCREMENT, " +
				"	opCode INTEGER, " +
				"	url TEXT, " + 
				"	guid TEXT " +
				")";
			createTable.execute();
		}
		
		public function get operations(): ArrayCollection {
			if(_opsListInvalid)
				loadOperations();
			return _operations;
		}
		
		private function loadOperations(): void {
			
		}

	}
}