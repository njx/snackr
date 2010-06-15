package ui.popups
{
	import flash.events.Event;

	public class DetailPopupManagerEvent extends Event
	{
		static public const DETAIL_POPUP_OPEN: String = "detailPopupOpen";
		static public const DETAIL_POPUP_CLOSE: String = "detailPopupClose";
		
		public var popup: DetailPopup;
		
		public function DetailPopupManagerEvent(type: String, popup: DetailPopup) {
			super(type);
			this.popup = popup;
		}
	}
}