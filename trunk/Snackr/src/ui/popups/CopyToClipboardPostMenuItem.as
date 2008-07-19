package ui.popups
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	
	import model.feeds.FeedItem;
	
	public class CopyToClipboardPostMenuItem implements IPostMenuItem
	{
		public function get label(): String
		{
			return "Copy to clipboard";
		}
		
		public function execute(item: FeedItem): void
		{
			Clipboard.generalClipboard.clear();
			Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, item.link);
			Clipboard.generalClipboard.setData(ClipboardFormats.URL_FORMAT, item.link);
		}	
	}
}