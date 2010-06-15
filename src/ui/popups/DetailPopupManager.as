package ui.popups
{
	import flash.display.Screen;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	
	import ui.ticker.TickerItem;
	import ui.utils.UIUtils;
	
	/**
	 * Class that manages detail popups, ensuring that only one is visible at a time,
	 * and collapsing one before another appears.
	 * TODO: should generalize to most popups, but there are some tricky Snackr-specific
	 * heuristics we'd need to build in.
	 */
	public class DetailPopupManager extends EventDispatcher
	{
		static private var _instance: DetailPopupManager = null;
		
		static public function get instance(): DetailPopupManager {
			if (_instance == null) {
				_instance = new DetailPopupManager();
			}
			return _instance;
		}
		
		/**
		 * The last DetailPopup shown, if any.
		 */
		private var _lastDetailPopup: DetailPopup = null;
		
		/**
		 * The next ticker item to open a popup for when the current one is closed.
		 */
		private var _nextPopupInfo: Object = null;
		
		public function popUpItem(item: TickerItem, isVertical: Boolean, currentScreen: Screen, currentSide: Number): void {
			// Close the last detail popup if one is already open.
			if (_lastDetailPopup != null) {
				if (_lastDetailPopup.data != item.data) {
					// We're opening a new item, so schedule it to be opened when the current one finishes closing.
					_nextPopupInfo = {item: item, isVertical: isVertical, currentScreen: currentScreen, currentSide: currentSide};
				}
				_lastDetailPopup.doClose();
			}
			else {			
				createNewPopup(item, isVertical, currentScreen, currentSide);	
			}
		}
		
		public function closePopups(): void {
			if (_lastDetailPopup != null) {
				_lastDetailPopup.doClose();
			}
		}
		
		private function createNewPopup(item: TickerItem, isVertical: Boolean, currentScreen: Screen, currentSide: Number): void {
			// Figure out where to open the popup. We want it to be anchored to the
			// middle of the item, on the appropriate side of the ticker (depending on
			// where it's docked).
			var globalOrigin: Point = item.localToGlobal(new Point(0, 0));
			globalOrigin.x += item.stage.nativeWindow.bounds.x;
			globalOrigin.y += item.stage.nativeWindow.bounds.y;
			
			var detail: DetailPopup = new DetailPopup();
			if (isVertical) {
				detail.anchorPoint = new Point(
					(currentSide == UIUtils.SIDE_LEFT ? globalOrigin.x + item.width : globalOrigin.x),
					globalOrigin.y + item.height / 2);
			}
			else {
				detail.anchorPoint = new Point(globalOrigin.x + item.width / 2, 
					(currentSide == UIUtils.SIDE_TOP ? globalOrigin.y + item.height : globalOrigin.y));
			}
			
			// Set up the detail popup and open it.
			detail.pointerSide = currentSide;
			detail.currentScreen = currentScreen;
			detail.data = item.data;
			detail.open(true);
			
			_lastDetailPopup = detail;
			_lastDetailPopup.addEventListener(Event.CLOSE, handleDetailClose);
			
			dispatchEvent(new DetailPopupManagerEvent(DetailPopupManagerEvent.DETAIL_POPUP_OPEN, _lastDetailPopup));	
		}

		/**
		 * Handler for detail popup close. If we had previously saved off a new item to pop up, we do it here, after the
		 * previous popup has finished closing.
		 */
		private function handleDetailClose(event: Event): void {
			if (_lastDetailPopup == event.target) {
				event.target.removeEventListener(Event.CLOSE, handleDetailClose);
				dispatchEvent(new DetailPopupManagerEvent(DetailPopupManagerEvent.DETAIL_POPUP_CLOSE, _lastDetailPopup));
				_lastDetailPopup = null;
				
				if (_nextPopupInfo != null) {
					createNewPopup(_nextPopupInfo.item, _nextPopupInfo.isVertical, _nextPopupInfo.currentScreen, _nextPopupInfo.currentSide);
					_nextPopupInfo = null;
				}
			}
		}		
	}
}