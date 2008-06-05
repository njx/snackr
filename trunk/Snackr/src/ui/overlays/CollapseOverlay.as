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

package ui.overlays
{
	import mx.core.UIComponent;

	public class CollapseOverlay extends UIComponent
	{
		static private const TRI_WIDTH: Number = 10;
		static private const TRI_HEIGHT: Number = 3;
		static private const TRI_SPACING: Number = 100;
		static private const VERT_PADDING: Number = 2;
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number): void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			graphics.clear();
			graphics.beginFill(0x000000, 0.9);
			graphics.drawRect(0, unscaledHeight - TRI_HEIGHT - VERT_PADDING * 2, unscaledWidth, TRI_HEIGHT + VERT_PADDING * 2);
			graphics.endFill();
			
			var triX: Number = 
				(unscaledWidth - (Math.floor(unscaledWidth / (TRI_WIDTH + TRI_SPACING)) * (TRI_WIDTH + TRI_SPACING) + TRI_WIDTH)) / 2;
			while (triX + TRI_WIDTH < unscaledWidth) {
				graphics.beginFill(0x999999, 0.9);
				graphics.moveTo(triX, unscaledHeight - VERT_PADDING - TRI_HEIGHT);
				graphics.lineTo(triX + TRI_WIDTH / 2, unscaledHeight - VERT_PADDING);
				graphics.lineTo(triX + TRI_WIDTH, unscaledHeight - VERT_PADDING - TRI_HEIGHT);
				
				graphics.endFill();
				triX += TRI_WIDTH + TRI_SPACING;
			}
		}
	}
}