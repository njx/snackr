package model.feeds.readers
{
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	
	import model.logger.Logger;

	public class GoogleAccountsResponder extends EventDispatcher
	{

		private static const CAPTCHA_AUTH_URL_PREFIX:String = "http://www.google.com/accounts/";
		
		private static const AUTH_BAD_CREDENTIALS_STATUS_CODE: Number = 403;
		
		private var previousEvent:SynchronizerEvent = null;
		private var caughtIOError:Boolean = false;
		private var caughtHTTPStatus:Boolean = false;

		public function GoogleAccountsResponder()
		{
		}
		
		public function handleAuthFaultEvent(event: IOErrorEvent): void {
			Logger.instance.log("GoogleReaderSynchronizer: Authentication failed: event:" + event, Logger.SEVERITY_NORMAL);
			Logger.instance.log("GoogleReaderSynchronizer: Authentication failed: event.target.data:" + event.target.data, Logger.SEVERITY_DEBUG);
			caughtIOError = true;
			var result: String = String(event.target.data);
			var responseVars: Object = new Object;
			var tokens:Array = result.split(/[\n]/);
			for(var i:int = 0; i < tokens.length; i++) {
				var firstEqualsPosition:int = tokens[i].indexOf("=");
				if(firstEqualsPosition != -1) {
					if(tokens[i].slice(0,firstEqualsPosition) == "Error") {
						responseVars.Error = tokens[i].slice(firstEqualsPosition+1,tokens[i].length);
					}
					else if(tokens[i].slice(0,firstEqualsPosition) == "CaptchaToken") {
						responseVars.CaptchaToken = tokens[i].slice(firstEqualsPosition+1,tokens[i].length);
					}
					else if(tokens[i].slice(0,firstEqualsPosition) == "CaptchaUrl") {
						responseVars.CaptchaUrl = tokens[i].slice(firstEqualsPosition+1,tokens[i].length);
					}
					else if(tokens[i].slice(0,firstEqualsPosition) == "Url") {
						responseVars.Url = tokens[i].slice(firstEqualsPosition+1,tokens[i].length);
					}
				}
				
			}
			if(responseVars.Error == "CaptchaRequired") {
				var syncEvent:SynchronizerEvent = new SynchronizerEvent(SynchronizerEvent.AUTH_CAPTCHA_CHALLENGE);
				syncEvent.captchaToken = responseVars.CaptchaToken;
				syncEvent.captchaURL = CAPTCHA_AUTH_URL_PREFIX + responseVars.CaptchaUrl;
				syncEvent.externalCaptchaDialogURL = responseVars.Url;
				previousEvent = syncEvent;
				dispatchEvent(syncEvent);
			}
			else {
				var authFailure : SynchronizerEvent = new SynchronizerEvent(SynchronizerEvent.AUTH_FAILURE);
				//did HTTP_STATUS already happen?
				if(caughtHTTPStatus) {
					//if no AUTH_BAD_CREDENTIALS was held, this must be a generic error
					if(previousEvent == null)
						dispatchEvent(authFailure);
					//there was an AUTH_BAD_CREDENTIALS, so fire that and ignore the generic error
					else
						dispatchEvent(previousEvent);
				}
				//don't know what to do with this yet, so store the AUTH_FAILURE so we can figure it out in handleAuthStatusEvent
				else {
					previousEvent = authFailure;
				}
				
				/*if(noBadCredentials)
					dispatchEvent(authFailure);
				else if(previousEvent.type == SynchronizerEvent.AUTH_BAD_CREDENTIALS)
					dispatchEvent(previousEvent);
				else
					previousEvent = authFailure;*/
			}
		}
		
		public function handleAuthStatusEvent(event: HTTPStatusEvent) : void {
			Logger.instance.log("GoogleReaderSynchronizer: response status: " + event, Logger.SEVERITY_DEBUG);
			Logger.instance.log("GoogleReaderSynchronizer: response status: event.target.data:" + event.target.data, Logger.SEVERITY_DEBUG);
			caughtHTTPStatus = true;
			if(event.status == AUTH_BAD_CREDENTIALS_STATUS_CODE) {
				var badCredentialsEvent : SynchronizerEvent = new SynchronizerEvent(SynchronizerEvent.AUTH_BAD_CREDENTIALS);
				//did IO_ERROR already happen?
				if(caughtIOError) {
					//if IO_ERROR didn't fire an AUTH_CAPTCHA_CHALLENGE, go ahead and fire the AUTH_BAD_CREDENTIALS event. otherwise, do nothing.
					if(previousEvent.type != SynchronizerEvent.AUTH_CAPTCHA_CHALLENGE)
						dispatchEvent(badCredentialsEvent);
				}
				//we don't know what to do with this yet, so store it and figure it out in handleAuthFaultEvent
				else {
					previousEvent = badCredentialsEvent;
				}
				/*if(previousEvent.type != SynchronizerEvent.AUTH_CAPTCHA_CHALLENGE)
					dispatchEvent(badCredentialsEvent);
				else
					previousEvent = badCredentialsEvent;*/
			}
			else {
				//did IO_ERROR already happen?
				if(caughtIOError) {
					//if we stored an AUTH_FAILURE event, go ahead and fire that since we're not firing a AUTH_BAD_CREDENTIALS
					if(previousEvent.type == SynchronizerEvent.AUTH_FAILURE)
						dispatchEvent(previousEvent);
				}
				/*noBadCredentials = true;
				if(previousEvent.type == SynchronizerEvent.AUTH_FAILURE)
					dispatchEvent(previousEvent);*/
			}
		}
		
		
	}
}