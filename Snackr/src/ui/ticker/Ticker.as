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

package ui.ticker
{
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import model.feeds.FeedItem;
	import model.feeds.FeedModel;
	import model.logger.Logger;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.MoveEvent;
	import mx.events.ResizeEvent;
	
	import ui.popups.DetailPopupManager;
	import ui.popups.DetailPopupManagerEvent;

	public class Ticker extends UIComponent
	{
		static public const QUEUE_RUNNING_LOW: String = "queueRunningLow";
		
		static private const EDGE_PADDING: Number = 5;
		
		// Should be able to get this from the app, but it doesn't report it properly on startup for some reason.
		static private const FRAME_RATE: Number = 60;
		
		// TODO: should make this changeable
		static private const ITEM_WIDTH: Number = 215;
		static private const ITEM_HEIGHT: Number = 65;
		static private const ITEM_PADDING: Number = 0;
		
		static private const ITEM_BUFFER: Number = 3;
		
		private var _childContainer: UIComponent = new UIComponent();
		private var _itemDataQueue: Array = new Array();
		private var _items: Array = new Array();
		private var _unusedItems: Array = new Array();
		private var _speed: Number = 60;
		private var _framesPerMove: uint = 1;
		private var _pixelsToMove: uint = 1;
		private var _frameCount: Number = 0;
		private var _mask: Sprite = new Sprite();
		private var _maskInvalid: Boolean = true;
		private var _isVertical: Boolean = false;
		private var _pauseRequesters: int = 0;
		
		public var currentScreen: Screen;
		public var currentSide: Number;

		// TODO: This class shouldn't really know about FeedItem/FeedModel--only TickerItems. Should refactor to get
		// rid of that dependency.
		private var _feedModel: FeedModel;
		
		public function Ticker()
		{
			super();
		}
		
		public function set feedModel(value: FeedModel): void {
			_feedModel = value;
		}
		
		public function get itemQueue(): Array {
			return _itemDataQueue;
		}
		
		public function queueItem(newItem: Object): void {
			queueItems([newItem]);
		}
		
		public function queueItems(newItems: Array): void {
			// Remove redundant items.
			var filteredItems: Array = new Array();
			var tickerQueueLookup: Object = new Object();
			for each (var tickerItem: TickerItem in _items) {
				if (tickerItem.data.feedItem != undefined && tickerItem.data.feedItem != null) {
					tickerQueueLookup[tickerItem.data.feedItem.guid] = true;
				}
			}
			for each (var tickerItemData: Object in _itemDataQueue) {
				if (tickerItemData.feedItem != undefined && tickerItemData.feedItem != null) {
					tickerQueueLookup[tickerItemData.feedItem.guid] = true;
				}
			}
			for (var i: uint = 0; i < newItems.length; i++) {
				if (newItems[i].feedItem == undefined || tickerQueueLookup[newItems[i].feedItem.guid] == undefined) {
					if (newItems[i].feedItem != undefined) {
						tickerQueueLookup[newItems[i].feedItem.guid] = true;
					}
					filteredItems.push(newItems[i]);
				}
				else {
					Logger.instance.log("Skipping item already in queue: " + newItems[i].feedItem.guid, Logger.SEVERITY_DEBUG);
				}
			}
			for each (var item: Object in filteredItems) {
				_itemDataQueue.push(item);
			}
			fillItemsFromQueue();
		}
		
		public function queueRunningLow(): Boolean {
			return (_itemDataQueue.length < ITEM_BUFFER);
		}
		
		public function clearQueue(): void {
			_itemDataQueue = new Array();
		}
		
		[Bindable]
		public function get speed(): Number {
			return _speed;
		}
		public function set speed(value: Number): void {
			_speed = value;
			recalcSpeed();
		}
		
		[Bindable]
		public function get isVertical(): Boolean {
			return _isVertical;
		}
		public function set isVertical(newIsVertical: Boolean): void {
			if (_isVertical != newIsVertical && _childContainer != null) {
				// Relayout children in the new orientation.
				var lastPos: Number = 0;
				for (var i: int = 0; i < _items.length; i++) {
					var child: TickerItem = TickerItem(_items[i]);
					if (newIsVertical) {
						child.x = 0;
						child.y = lastPos;
						lastPos += ITEM_HEIGHT + ITEM_PADDING;
						child.imageSide = TickerItem.IMAGE_SIDE_RIGHT;
					}
					else {
						child.x = lastPos;
						child.y = 0;
						lastPos += ITEM_WIDTH + ITEM_PADDING;
						child.imageSide = TickerItem.IMAGE_SIDE_LEFT;
					}
				}

				// Swap the x and y, so that the amount the child container was offset in the original direction
				// is the same in the new direction. But make sure it stays on the screen.
				var temp: Number = _childContainer.x;
				_childContainer.x = _childContainer.y;
				_childContainer.y = temp;
				if (newIsVertical && _childContainer.y > height) {
					_childContainer.y = height;
				}
				else if (!newIsVertical && _childContainer.x > width) {
					_childContainer.x = width;
				}

				// Remove any items that are past our desired size and push them back onto the data queue,
				// so we're not scrolling around a huge number of extra items.
				var truncateTo: Number = _items.length;
				for (i = _items.length - 1; i >= 0; i--) {
					var tickerItem: TickerItem = TickerItem(_items[i]);
					if ((newIsVertical && tickerItem.y > height) ||
						(!newIsVertical && tickerItem.x > width)) {
						truncateTo = i;
						_childContainer.removeChild(tickerItem);
						_itemDataQueue.unshift(tickerItem.data);
					}
					else {
						break;
					}
				}
				_items.length = truncateTo;
			}
			_isVertical = newIsVertical;
			recalcSpeed();
			doResize();
		}
		
		private function recalcSpeed(): void {
			// Slow down the effective speed when we're vertical, since it's harder to
			// target the items when they're flying by vertically.
			var effectiveSpeed: Number = (isVertical ? _speed / 2 : _speed);
			if (effectiveSpeed > FRAME_RATE) {
				_framesPerMove = 1;
				_pixelsToMove = Math.floor(effectiveSpeed / FRAME_RATE);
			}
			else {
				_framesPerMove = Math.floor(FRAME_RATE / effectiveSpeed);
				_pixelsToMove = 1;
			}
		}
		
		override protected function createChildren(): void {
			_childContainer.cacheAsBitmap = true;
			addChild(_childContainer);
			addEventListener(ResizeEvent.RESIZE, handleResize);
			addEventListener(MoveEvent.MOVE, handleMove);
			addEventListener(TickerItemClickEvent.TICKER_ITEM_CLICK, handleTickerItemClick);
			doResize();
			
			DetailPopupManager.instance.addEventListener(DetailPopupManagerEvent.DETAIL_POPUP_OPEN, handleDetailPopupOpen);
			DetailPopupManager.instance.addEventListener(DetailPopupManagerEvent.DETAIL_POPUP_CLOSE, handleDetailPopupClose);
		}
		
		private function handleResize(event: ResizeEvent): void {
			doResize();
		}
		
		private function handleMove(event: MoveEvent): void {
			// Since our mask is relative to our x,y position, we have to invalidate it
			// if we move, even if we don't resize.
			_maskInvalid = true;
			invalidateDisplayList();
		}
		
		private function doResize(): void {
			_maskInvalid = true;
			invalidateDisplayList();
			
			if (_isVertical) {
				_childContainer.width = width;
				_childContainer.height = height + (ITEM_HEIGHT + ITEM_PADDING) * (ITEM_BUFFER + 1);
			}
			else {
				_childContainer.width = width + (ITEM_WIDTH + ITEM_PADDING) * (ITEM_BUFFER + 1);
				_childContainer.height = height;
			}

			for each (var tickerItem: TickerItem in _items) {
				this.setItemWidth(tickerItem);
			}

			fillItemsFromQueue();
		}
		
		private function calcItemWidth(): Number {
		    if (_isVertical) {
		    	return _childContainer.width - 2 * EDGE_PADDING;
		    } else {
		    	return ITEM_WIDTH;
		    }
		}

		private function setItemWidth(tickerItem: TickerItem): void {
			tickerItem.setActualSize(this.calcItemWidth(), tickerItem.height);
		}

		public function animate(): void {
			// Start on right-hand/top side.
			if (_isVertical) {
				_childContainer.x = EDGE_PADDING;
				_childContainer.y = height;
			}
			else {
				_childContainer.x = width;
				_childContainer.y = EDGE_PADDING;
			}
			_frameCount = 0;
			addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		public function pause(): void {
			if (_pauseRequesters == 0) {
				removeEventListener(Event.ENTER_FRAME, handleEnterFrame);
			}
			_pauseRequesters++;
		}
		
		public function resume(): void {
			_pauseRequesters--;
			if (_pauseRequesters == 0) {
				_frameCount = 0;
				addEventListener(Event.ENTER_FRAME, handleEnterFrame);
			}
		}
		
		private function handleEnterFrame(event: Event): void {
			if (++_frameCount >= _framesPerMove) {
				_frameCount = 0;
				if (_isVertical) {
					_childContainer.move(_childContainer.x, _childContainer.y - _pixelsToMove);
				}
				else {
					_childContainer.move(_childContainer.x - _pixelsToMove, _childContainer.y);
				}
				fillItemsFromQueue();
			}
		}

		private function fillItemsFromQueue(): void {
			// Remove any items from the front that are no longer visible because
			// they've scrolled past the left edge, and move them to the "unused"
			// pool. 
			while (_items.length > 0) {
				var item: TickerItem = TickerItem(_items[0]);
				if ((_isVertical && (_childContainer.y + item.y + item.height < 0)) ||
					(!_isVertical && (_childContainer.x + item.x + item.width < 0))) {
					_childContainer.removeChild(_items[0]);
					_unusedItems.push(_items[0]);
					_items.shift();
					if (_isVertical) {
						_childContainer.move(_childContainer.x, _childContainer.y + ITEM_HEIGHT + ITEM_PADDING);					
					}
					else {
						_childContainer.move(_childContainer.x + ITEM_WIDTH + ITEM_PADDING, _childContainer.y);
					}
					for (var i: Number = 0; i < _items.length; i++) {
						item = TickerItem(_items[i]);
						if (_isVertical) {
							item.move(item.x, item.y - ITEM_HEIGHT - ITEM_PADDING);
						}
						else {
							item.move(item.x - ITEM_WIDTH - ITEM_PADDING, item.y);
						}
					}
				}
				else {
					break;
				}
			}
			
			// Fill empty space at the end with items from the head of the 
			// item data queue. We actually buffer a few items past the end so that
			// images have time to load.
			if (_itemDataQueue.length > 0) {
				var nextItemPos: Number;
				if (_items.length == 0) {
					nextItemPos = 0;
				}
				else {
					var lastItem: TickerItem = TickerItem(_items[_items.length - 1]);
					if (_isVertical) {
						nextItemPos = lastItem.y + lastItem.height + ITEM_PADDING;
					}
					else {
						nextItemPos = lastItem.x + lastItem.width + ITEM_PADDING;
					}
				} 
				while (_itemDataQueue.length > 0 && 
					   ((_isVertical && (nextItemPos < _childContainer.height)) ||
					   	(!_isVertical && (nextItemPos < _childContainer.width)))) {
					var nextItem: TickerItem = _unusedItems.shift();
					if (nextItem == null) {
						nextItem = new TickerItem();
					}
					nextItem.data = _itemDataQueue.shift();
					if (_isVertical) {
						nextItem.imageSide = TickerItem.IMAGE_SIDE_RIGHT;
						nextItem.x = 0;
						nextItem.y = nextItemPos;
					}
					else {
						nextItem.imageSide = TickerItem.IMAGE_SIDE_LEFT;
						nextItem.x = nextItemPos;
						nextItem.y = 0;						
					}
					_items.push(nextItem);
					this.setItemWidth(nextItem);
					_childContainer.addChild(nextItem);
					if (_isVertical) {
						nextItemPos += ITEM_HEIGHT + ITEM_PADDING;
					}
					else {
						nextItemPos += ITEM_WIDTH + ITEM_PADDING;
					}
				}
			}
			
			if (queueRunningLow()) {
				dispatchEvent(new Event(QUEUE_RUNNING_LOW));
			}
		}
		
		/**
		 * Handler for clicking on a ticker item. This pops up the detail popup window for that item.
		 */
		private function handleTickerItemClick(event: TickerItemClickEvent): void {
			var item: TickerItem = event.tickerItem;
			
			// Create the detail popup.
			DetailPopupManager.instance.popUpItem(item, isVertical, currentScreen, currentSide);

			// Mark the item as read.
			var feedItem: FeedItem = FeedItem(item.data.feedItem);
			if (feedItem != null) {
				_feedModel.setItemRead(feedItem);
				item.setRead();
			}
		}
		
		/**
		 * Handler for when detail popups open. Pauses the ticker.
		 */
		private function handleDetailPopupOpen(event: DetailPopupManagerEvent): void {
			pause();
		}
		
		/**
		 * Handler for when detail popups close. Resumes the ticker.
		 */
		private function handleDetailPopupClose(event: DetailPopupManagerEvent): void {
			resume();
		}
		
		/**
		 * Updates our display list. Most of our actual display list management is handled in the scrolling
		 * code or the resize handler; all we do here is update our clipping mask to take into account
		 * any change in size. Normally you don't have to worry about dealing with clipping in Flex apps,
		 * but since we're using a raw UIComponent as the container for our scrolling items, and UIComponent
		 * doesn't handle clipping, we have to manage clipping manually.
		 */
		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if (_maskInvalid) {
				_mask.graphics.clear();
				_mask.graphics.beginFill(0xFFFFFF);
				_mask.graphics.drawRect(x, y, unscaledWidth, unscaledHeight);
				_mask.graphics.endFill();
				mask = _mask;
				_maskInvalid = false;
			}
		}		
	}
}