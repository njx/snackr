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

package model.logger
{
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	public class Logger extends EventDispatcher
	{
		// SEVERITY_DEBUG messages are only output in the debug console.
		static public const SEVERITY_DEBUG: Number = -5;
		
		// SEVERITY_NORMAL messages are output to both the debug console and the log file.
		static public const SEVERITY_NORMAL: Number = 0;
		
		// SEVERITY_SERIOUS messages are output to the debug console and log file, and the user is warned about them.
		static public const SEVERITY_SERIOUS: Number = 5;
		
		static private var _logger: Logger = new Logger();
		
		static public function get instance(): Logger {
			return _logger;
		}

		private var _logFile: File = null;
		
		public function initialize(logFile: File): void {
			// TODO: should limit the log file size, or perhaps just always start a new log file on startup.
			_logFile = logFile;
		}
		
		public function get logFile(): File {
			return _logFile;
		}
		
		public function log(message: String, severity: Number = SEVERITY_NORMAL): void {
			trace(message);
			
			if (severity >= SEVERITY_NORMAL && _logFile != null) {
				var stream: FileStream = new FileStream();
				stream.open(_logFile, FileMode.APPEND);
				stream.writeUTFBytes(new Date().toString() + ": " + message + "\n");
				stream.close();
			}
			
			dispatchEvent(new LogEvent(message, severity));
		}
	}
}