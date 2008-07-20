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

package ui.popups
{
	import flash.display.Graphics;
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.controls.Label;
	import mx.core.UIComponent;

	public class ScreenPicker extends UIComponent
	{
		static public const DEFAULT_PADDING: Number = 10;
		
		private var _screenRects: Array = new Array();
		private var _screenBounds: Array = new Array();
		private var _screenLabels: Array = new Array();
		private var _totalBounds: Rectangle = null;
		private var _selectedScreenIndex: Number = 0;
		private var _highlightedScreenIndex: Number = -1;
		
		[Bindable]
		public function get selectedScreenIndex(): Number {
			return _selectedScreenIndex;
		}		
		public function set selectedScreenIndex(value: Number): void {
			_selectedScreenIndex = value;
			invalidateDisplayList();
		}
		
		private function get highlightedScreenIndex(): Number {
			return _highlightedScreenIndex;
		}
		private function set highlightedScreenIndex(value: Number): void {
			_highlightedScreenIndex = value;
			invalidateDisplayList();
		}
		
		override protected function createChildren(): void {
			rebuild();
		}
		
		public function rebuild(): void {
			var rect: Sprite;
			var label: Label;
			for each (rect in _screenRects) {
				removeChild(rect);
			}
			for each (label in _screenLabels) {
				removeChild(label);
			}
			_screenRects = new Array();
			_screenBounds = new Array();
			_screenLabels = new Array();
			for (var i: Number = 0; i < Screen.screens.length; i++) {
				rect = new Sprite();
				addChild(rect);
				_screenRects.push(rect);
				label = new Label();
				addChild(label);
				_screenLabels.push(label);
				
				var bounds: Rectangle = Screen(Screen.screens[i]).bounds;
				_screenBounds.push(bounds);
				if (_totalBounds == null) {
					_totalBounds = new Rectangle(bounds.x, bounds.y, bounds.width, bounds.height);
				}
				if (bounds.x < _totalBounds.x) {
					_totalBounds.width += _totalBounds.x - bounds.x;
					_totalBounds.x = bounds.x;
				}
				if (bounds.y < _totalBounds.y) {
					_totalBounds.height += _totalBounds.y - bounds.y;
					_totalBounds.y = bounds.y;
				}
				if (bounds.x + bounds.width > _totalBounds.x + _totalBounds.width) {
					_totalBounds.width = bounds.x + bounds.width - _totalBounds.x;
				}
				if (bounds.y + bounds.height > _totalBounds.y + _totalBounds.height) {
					_totalBounds.height = bounds.y + bounds.height - _totalBounds.y;
				}
				
				rect.addEventListener(MouseEvent.CLICK, handleItemClick);
				rect.addEventListener(MouseEvent.ROLL_OVER, handleItemRollOver);
				rect.addEventListener(MouseEvent.ROLL_OUT, handleItemRollOut);
				label.addEventListener(MouseEvent.CLICK, handleItemClick);
				label.addEventListener(MouseEvent.ROLL_OVER, handleItemRollOver);
				label.addEventListener(MouseEvent.ROLL_OUT, handleItemRollOut);
			}
			invalidateDisplayList();
		}
		
		private function handleItemClick(event: MouseEvent): void {
			var index: Number = getItemIndex(event.currentTarget);
			if (index != -1) {
				selectedScreenIndex = index;
			}
		}
		
		private function handleItemRollOver(event: MouseEvent): void {
			var index: Number = getItemIndex(event.currentTarget);
			if (index != -1) {
				highlightedScreenIndex = index;
			}
		}
		
		private function handleItemRollOut(event: MouseEvent): void {
			var index: Number = getItemIndex(event.currentTarget);
			if (index == _highlightedScreenIndex) {
				highlightedScreenIndex = -1;
			}
		}
		
		private function getItemIndex(item: Object): Number {
			return (item is Label ? _screenLabels.indexOf(item) : _screenRects.indexOf(item));
		}
		
		private function hasNewScreenConfiguration(): Boolean {
			if (_totalBounds == null || _screenRects.length != Screen.screens.length) {
				return true;
			}
			else {
				for (var i: Number = 0; i < Screen.screens.length; i++) {
					if (!Screen(Screen.screens[i]).bounds.equals(_screenBounds[i])) {
						return true;
					}
				}
			}
			return false;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number): void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (unscaledWidth == 0 || unscaledHeight == 0) {
				return;
			}
			
			if (hasNewScreenConfiguration()) {
				rebuild();
			}
			else {
				// Figure out how much we have to scale to fit the actual bounds in the current width/height
				// of this control. We need to preserve aspect ratio.
				var scale: Number = Math.min(unscaledWidth / _totalBounds.width, unscaledHeight / _totalBounds.height);
				
				graphics.clear();
				graphics.lineStyle(1, 0x999999);
				graphics.drawRect(0, 0, _totalBounds.width * scale, _totalBounds.height * scale);
			
				for (var i: Number = 0; i < _screenRects.length; i++) {
					var rect: Sprite = _screenRects[i];
					var bounds: Rectangle = _screenBounds[i];
					var g: Graphics = rect.graphics;
					g.clear();
					g.lineStyle();
					var fillColor: Number;
					if (i == _selectedScreenIndex) {
						fillColor = 0xFFFFFF;
					}
					else if (i == _highlightedScreenIndex) {
						fillColor = 0x999999;
					}
					else {
						fillColor = 0x444444;
					}
					g.beginFill(fillColor, 1.0);
					g.drawRect(Math.floor((bounds.x - _totalBounds.x) * scale + DEFAULT_PADDING / 2), Math.floor((bounds.y - _totalBounds.y)* scale + DEFAULT_PADDING / 2), 
						Math.floor(bounds.width * scale - DEFAULT_PADDING), Math.floor(bounds.height * scale - DEFAULT_PADDING));
					g.endFill();
					if (i == _selectedScreenIndex) {
						g.beginFill(0x999999);
						g.drawRect(Math.floor((bounds.x - _totalBounds.x) * scale + DEFAULT_PADDING / 2 + 2), Math.floor((bounds.y - _totalBounds.y) * scale + DEFAULT_PADDING / 2 + 2), 
							Math.floor(bounds.width * scale - DEFAULT_PADDING - 4), Math.floor(bounds.height * scale - DEFAULT_PADDING - 4));
						g.endFill();
					}
					
					var label: Label = _screenLabels[i];
					label.setStyle("fontFamily", "Myriad Pro");
					label.setStyle("fontSize", 24);
					label.setStyle("fontWeight", "bold");
					label.setStyle("color", 0xFFFFFF);
					label.setStyle("textAlign", "center");
					label.text = String(i + 1);
					label.validateNow();
					// For some reason we have to pad this a bit--otherwise the text gets clipped.
					label.width = label.textWidth + 20;
					label.height = label.textHeight;
					label.x = Math.floor(((bounds.x - _totalBounds.x) * scale) + (bounds.width * scale - label.width) / 2);
					label.y = Math.floor(((bounds.y - _totalBounds.y) * scale) + (bounds.height * scale - label.height) / 2);
				}
			}
		}
		
	}
}