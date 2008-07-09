package model.feeds.readers
{
	import flash.events.Event;

	public class SynchronizerEvent extends Event
	{
		public static const AUTH_SUCCESS: String = "authSuccess";
		public static const AUTH_BAD_CREDENTIALS: String = "authBadCredentials";
		public static const AUTH_FAILURE: String = "authFailure";
		
		public function SynchronizerEvent(type:String)
		{
			super(type);
		}
		
		override public function toString() : String {
			return "SynchronizerEvent [type: " + type + "]";
		}
		
	}
}