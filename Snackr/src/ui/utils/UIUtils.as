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

package ui.utils
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.display.Graphics;
	import flash.display.NativeWindow;
	import flash.geom.Rectangle;
	import flash.text.Font;
	
	import model.feeds.FeedItem;
	
	import mx.core.UIComponent;
	import mx.effects.easing.Cubic;
	import mx.events.EffectEvent;
	
	public class UIUtils
	{
		static public const SIDE_TOP: Number = 0;
		static public const SIDE_BOTTOM: Number = 1;
		static public const SIDE_LEFT: Number = 2;
		static public const SIDE_RIGHT: Number = 3;
		
		static public function drawSpeechBalloon(graphics: Graphics, pointerSide: Number, bounds: Rectangle, pointerPos: Number,
			pointerWidth: Number, pointerHeight: Number): void {	
			graphics.lineStyle();
			graphics.beginFill(0x111111, 1.0);
			if (pointerSide == SIDE_TOP || pointerSide == SIDE_BOTTOM) {
				graphics.drawRoundRect(bounds.x, 
					(pointerSide == SIDE_TOP ? bounds.y + pointerHeight : bounds.y), 
					bounds.width, bounds.height - pointerHeight, 10);
			}
			else {
				graphics.drawRoundRect(
					(pointerSide == SIDE_LEFT ? bounds.x + pointerHeight : bounds.x),
					bounds.y,
					bounds.width - pointerHeight, bounds.height, 10);
			}
			graphics.endFill();
			
			var pointerBase: Number;
			var pointerSquareBase: Number;
			var pointerTip: Number;
			
			graphics.beginFill(0x111111, 1.0);
			if (pointerSide == SIDE_TOP || pointerSide == SIDE_BOTTOM) {
				pointerBase = (pointerSide == SIDE_TOP ? pointerHeight : bounds.height - pointerHeight);
				pointerSquareBase = (pointerSide == SIDE_TOP ? pointerBase + 10 : pointerBase - 10);
				pointerTip = (pointerSide == SIDE_TOP ? 0 : bounds.height);
				// We square off an area above the pointer in case it's too close to the corner.
				graphics.moveTo(pointerPos - (pointerWidth / 2), pointerSquareBase);
				graphics.lineTo(pointerPos - (pointerWidth / 2), pointerBase);
				graphics.lineTo(pointerPos, pointerTip);
				graphics.lineTo(pointerPos + (pointerWidth / 2), pointerBase);
				graphics.lineTo(pointerPos + (pointerWidth / 2), pointerSquareBase);
			}
			else {
				pointerBase = (pointerSide == SIDE_LEFT ? pointerHeight : bounds.width - pointerHeight);
				pointerSquareBase = (pointerSide == SIDE_LEFT ? pointerBase + 10 : pointerBase - 10);
				pointerTip = (pointerSide == SIDE_LEFT ? 0 : bounds.width);
				// We square off an area above the pointer in case it's too close to the corner.
				graphics.moveTo(pointerSquareBase, pointerPos - (pointerWidth / 2));
				graphics.lineTo(pointerBase, pointerPos - (pointerWidth / 2));
				graphics.lineTo(pointerTip, pointerPos);
				graphics.lineTo(pointerBase, pointerPos + (pointerWidth / 2));
				graphics.lineTo(pointerSquareBase, pointerPos + (pointerWidth / 2));
			}						
			graphics.endFill();		
		}
		
		static public function getURLFromClipboard(): String {
			var url: String = "";
			if (Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT)) {
				url = String(Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
			}
			else if (Clipboard.generalClipboard.hasFormat(ClipboardFormats.URL_FORMAT)) {
				url = String(Clipboard.generalClipboard.getData(ClipboardFormats.URL_FORMAT));
			}
			return fixupFeedURL(url, true);
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
		
		static public function animateToBounds(nativeWindow: NativeWindow, newBounds: Rectangle, duration: Number = 150, 
			easingFunction: Function = null, effectEndHandler: Function = null): void {
			var anim: AnimateRectProperty = new AnimateRectProperty(nativeWindow);
			anim.duration = duration;
			anim.property = "bounds";
			anim.toValue = newBounds;
			anim.easingFunction = (easingFunction == null ? mx.effects.easing.Cubic.easeOut : easingFunction);
			if (effectEndHandler != null) {
				anim.addEventListener(EffectEvent.EFFECT_END, effectEndHandler);
			}
			anim.play();
		}
		
		// TODO: this should probably turn into a generic ITickerItemData interface and an adapter that
		// glues a FeedItem into a TickerItem.
		static public function convertFeedItemsToTickerItems(feedItems: Array): Array {
			var result: Array = new Array();
			for each (var feedItem: FeedItem in feedItems) {
				var tickerItem: Object = new Object();
				tickerItem.feedItem = feedItem;
				var title: String = stripHTML(feedItem.title);
				if (title == null || title == "") {
					tickerItem.title = stripHTML(feedItem.description);
				}
				else {
					tickerItem.title = title;
				}
				tickerItem.link = feedItem.link;
				var imageURL: String = null;
				if (feedItem.imageURL != null && feedItem.imageURL != "") {
					imageURL = feedItem.imageURL;
				}
				else {
					if (feedItem.description != null) {
						var matchResult: Array = feedItem.description.match(/<img[^>]*src="([^"]*)"[^>]*>/i);
						if (matchResult != null && matchResult.length > 1 && String(matchResult[1]).indexOf("http://") == 0) {
							// If this is a tiny image (commonly some kind of 1-pixel tracking gif), ignore it.
							var widthResult: Array = String(matchResult[0]).match(/width="([^"]*)"/i);
							var heightResult: Array = String(matchResult[0]).match(/height="([^"]*)"/i);
							if (widthResult != null && widthResult.length > 1 && Number(String(widthResult[1])) < 5 ||
								heightResult != null && heightResult.length > 1 && Number(String(heightResult[1])) < 5) {
								imageURL = null;
							}
							else {	
								imageURL = matchResult[1];
							}
						}
					}
					if (imageURL == null) {
						imageURL = feedItem.feed.logoURL;
					}
				}
				tickerItem.imageURL = imageURL;

				tickerItem.info = feedItem.feed.name;
				if (feedItem.timestamp != null) {
					tickerItem.info2 = timeAgo(feedItem.timestamp);
				}
				tickerItem.description = feedItem.description;
				result.push(tickerItem);
			}
			
			return result;
		}
		
		// Not entirely accurate since it assumes 30-day months, 365-day years,
		// but it's close enough
		static public function timeAgo(date: Date): String {
			var currentDate: Date = new Date();
			var diffSecs: Number = Math.floor((currentDate.getTime() - date.getTime()) / 1000);
			if (diffSecs < 0) {
				// This shouldn't happen, but some feeds have invalid times (e.g. ones that don't
				// properly adjust for daylight savings time).
				return "<1h ago";
			}
			if (diffSecs < 60) { // < 1 min
				return String(diffSecs) + "s ago";
			}
			else if (diffSecs < 3600) { // < 1 hour
				return String(Math.floor(diffSecs / 60)) + "m ago";
			}
			else if (diffSecs < 86400) { // < 1 day
				return String(Math.floor(diffSecs / 3600)) + "h ago";
			}
			else if (diffSecs < 2592000) { // < 30 days
				return String(Math.floor(diffSecs / 86400)) + "d ago";
			}
			else if (diffSecs < 31536000) { // < 365 days
				return String(Math.floor(diffSecs / 2592000)) + "mo ago";
			}
			else {
				return String(Math.floor(diffSecs / 31536000)) + "y ago";
			}
		}

		static public function setFontForString(value: String, item: UIComponent): void {
			var font: Font = getEmbeddedFont("Myriad Web");
			if (font != null && !font.hasGlyphs(value)) {
				item.styleName = "nonWesternLabel";
			}
			else {
				item.styleName = "westernLabel";
			}
		}
		
		static public function getEmbeddedFont(fontName: String): Font {
			var fontArray: Array = Font.enumerateFonts(false);
			for (var i: int = 0; i < fontArray.length; i++) {
				if (Font(fontArray[i]).fontName == fontName) {
					return fontArray[i];
				}
			}
			return null;
		}
		
		static public function stripHTML(str: String): String {
			str = str.replace(/<[^>]*>/g, "");
			str = str.replace(/&[#A-Za-z0-9]*;/g, "");
			str = str.replace("&lt;", "<");
			str = str.replace("&gt;", ">");
			str = str.replace("&amp;", "&");
			return str;
		}
	}
}