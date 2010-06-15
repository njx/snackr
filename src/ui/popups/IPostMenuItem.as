package ui.popups
{
	import model.feeds.FeedItem;
	
	public interface IPostMenuItem
	{
		function get label(): String;
		function execute(item: FeedItem): void;
	}
}