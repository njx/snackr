package ui.popups
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import model.feeds.FeedItem;
	
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
			var params: Object = new Object();
			params.link = item.link;
			params.title = item.title;
			// TODO: handle ${prompt("some label")}
			navigateToURL(new URLRequest(doSubstitutions(_urlPattern, params)));
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