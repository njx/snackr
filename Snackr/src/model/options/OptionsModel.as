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

package model.options
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	
	import model.logger.Logger;
	
	[Event(name="optionChange", type="model.options.OptionChangeEvent")]
	public class OptionsModel extends EventDispatcher
	{
		static public const OPTION_VERSION: String = "version";
		static public const OPTION_TICKER_SPEED: String = "tickerSpeed";
		static public const OPTION_ALWAYS_IN_FRONT: String = "alwaysInFront";
		static public const OPTION_AGE_LIMIT: String = "ageLimit";
		static public const OPTION_SCREENS_PREFIX: String = "screens";
		static public const OPTION_CHECK_FOR_UPDATES: String = "checkForUpdates";
		static public const OPTION_SCREEN_SIDE: String = "screenSide";
		static public const OPTION_FEED_CHECK_MIN_TIME: String = "feedCheckMinTime";
		static public const OPTION_TICKER_OPACITY: String = "tickerOpacity";
		static public const OPTION_AGE_LIMIT_UNITS: String = "ageLimitUnits";
		static public const OPTION_READER_ENABLED: String = "readerEnabled";
		static public const OPTION_READER_USER_NAME: String = "readerUserName";
		static public const OPTION_READER_PASSWORD: String = "readerPassword";
		
		static public const OPTION_VALUE_AGE_LIMIT_DAYS: String = "days";
		static public const OPTION_VALUE_AGE_LIMIT_HOURS: String = "hours";
		
		static public const ALL_OPTIONS: Array = [
			OPTION_VERSION, OPTION_TICKER_SPEED, OPTION_ALWAYS_IN_FRONT, OPTION_AGE_LIMIT, OPTION_SCREENS_PREFIX, 
			OPTION_CHECK_FOR_UPDATES, OPTION_SCREEN_SIDE, OPTION_FEED_CHECK_MIN_TIME, OPTION_TICKER_OPACITY, OPTION_AGE_LIMIT_UNITS,
			OPTION_READER_ENABLED, OPTION_READER_USER_NAME, OPTION_READER_PASSWORD
		];
		
		private var _sqlConnection: SQLConnection;
		
		public function OptionsModel(sqlConnection: SQLConnection) {
			_sqlConnection = sqlConnection;
			
			var createTable: SQLStatement = new SQLStatement();
			createTable.sqlConnection = _sqlConnection;
			createTable.text =
			    "CREATE TABLE IF NOT EXISTS main.options (" + 
			    "    name TEXT PRIMARY KEY, " + 
			    "    value TEXT" +
			    ")";
			createTable.execute();
		}

		// Note that since option values are always strings, be careful to encode/decode other types to/from strings.
		// Current convention (for somewhat dumb historical reasons) is that booleans map to "0" (false) and "1" (true).
		public function getValue(option: String): String {
			var getOptionValue: SQLStatement = new SQLStatement();
			getOptionValue.sqlConnection = _sqlConnection;
			getOptionValue.text = "SELECT * FROM main.options WHERE name = :name";
			getOptionValue.parameters[":name"] = option;
			getOptionValue.execute();
			var result: SQLResult = getOptionValue.getResult();
			if (result != null && result.data != null && result.data.length > 0) {
				return result.data[0].value;
			}
			return null;
		}
		
		public function setValue(option: String, value: String): void {
			Logger.instance.log("Setting option " + option + " = " + value, Logger.SEVERITY_DEBUG);
			var setOptionValue: SQLStatement = new SQLStatement();
			setOptionValue.sqlConnection = _sqlConnection;
			setOptionValue.text = "REPLACE INTO main.options (name, value) VALUES (:name, :value)";
			setOptionValue.parameters[":name"] = option;
			setOptionValue.parameters[":value"] = value;
			setOptionValue.execute();
			dispatchEvent(new OptionChangeEvent(option, value));
		}
	}
}