package model.utils
{
	import model.logger.Logger;
	
	public class FeedUtils
	{
		static public function resolveURL(url: String, docBase: String): String {
			var urlParseExp: RegExp = /^([a-z]+):\/\/([a-zA-Z0-9][a-zA-Z0-9.\-]*)((\/.*)|$)/;
			// Figure out if this is an absolute, site-relative, or doc-relative URL.
			if (url.match(/^[a-z]+:\/\//) != null) {
				// Absolute URL, does not need to be resolved.
				return url;
			}
			else {			
				// Relative URL.
				var docBaseMatch: Array = urlParseExp.exec(docBase);
				if (docBaseMatch == null || docBaseMatch.length < 3) {
					Logger.instance.log("FeedUtils.resolveURL(): Couldn't parse docBase " + docBase);
					return url;
				}
				else {
					var scheme: String = docBaseMatch[1];
					var hostname: String = docBaseMatch[2];
					var path: String = "";
					if (docBaseMatch.length > 3) {
						path = docBaseMatch[3];
					}
					if (url.length > 0 && url.charAt(0) == '/') {
						// Site-relative URL. Extract the scheme and hostname from the docBase.
						return scheme + "://" + hostname + url;
					}
					else {
						// Must be doc-relative. Extract everything up to the last slash
						// from the docBase path.
						var folderPath: String = "";
						var lastSlash: Number = path.lastIndexOf("/");
						if (lastSlash == -1) {
							folderPath = path + "/";
						}
						else {
							folderPath = path.substr(0, lastSlash + 1);
						}
						return scheme + "://" + hostname + folderPath + url;
					}
				}
			}
		}
		
		static public function fixupFeedURL(url: String, returnBlankIfInvalid: Boolean = false): String {
			if (url.indexOf("http://") == 0) {
				return url;
			}
			else if (url.indexOf("feed://") == 0) {
				return url.replace("feed://", "http://");
			}
			else {
				// If it looks like it starts with a site name, assume it's a URL that the user
				// just forgot to put http:// in front of.
				if (url.match(/^[a-zA-Z0-9][a-zA-Z0-9.\-]*(\/|$)/) != null) {
					return "http://" + url;
				}
				return (returnBlankIfInvalid ? "" : url);
			}
		}
	}
}