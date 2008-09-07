package ui.popups
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import model.feeds.FeedItem;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	/**
	 * Class for posting links to a given URL, substituting information about the item
	 * into the URL as necessary.
	 *
	 * The URL may contain the following substitutable items:
	 * 
	 * ${link} -- the link to post
	 * ${title} -- the link title
	 * 
	 * Not yet implemented:
	 * ${prompt("label")} -- a string to get from the user through a dialog; the given label is used as the label for the input field in the dialog
	 */
	public class URLPatternPostMenuItem implements IPostMenuItem
	{
		private var _label: String = "";
		private var _urlPattern: String = "";
		private var _params: Object = null;
		
		public function URLPatternPostMenuItem(label: String, urlPattern: String)
		{
			_label = label;
			_urlPattern = urlPattern;
		}

		public function get label(): String
		{
			return _label;
		}
		
		public function execute(item: FeedItem): void
		{
			_params = new Object();
			_params.link = item.link;
			_params.title = item.title;
			_params.shortlink = "";
			if (_urlPattern.indexOf("${shortlink}") >= 0) {
				makeShortLinkAndExecute();
			}
			else {
				doExecute();
			}
		}	
		
		private function doExecute(): void {
			// TODO: handle ${prompt("some label")}
			navigateToURL(new URLRequest(doSubstitutions(_urlPattern, _params)));
		}
		
		private function makeShortLinkAndExecute(): void {
			var service: HTTPService = new HTTPService();
			service.url = doSubstitutions("http://snipr.com/site/snip?r=simple&link=${link}&title=${title}", _params);
			service.resultFormat = HTTPService.RESULT_FORMAT_TEXT;
			service.addEventListener(ResultEvent.RESULT, handleMakeShortLinkResult);
			service.addEventListener(FaultEvent.FAULT, handleMakeShortLinkFault);
			service.send();
		}
		
		private function handleMakeShortLinkResult(event: ResultEvent): void {
			_params.shortlink = event.result.toString();
			doExecute();	
		}
		
		private function handleMakeShortLinkFault(event: FaultEvent): void {
			// TODO
		}
		
		private function doSubstitutions(urlPattern: String, params: Object): String {
			var result: String = urlPattern;
			for (var paramName: String in params) {
				result = result.replace("${" + paramName + "}", encodeURIComponent(params[paramName]));
			}
			return result;
		}
		
	}
}