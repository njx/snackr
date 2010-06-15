////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2005-2006 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

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

import flash.geom.Rectangle;

import mx.core.mx_internal;
import mx.effects.effectClasses.TweenEffectInstance;

/**
 *  The AnimateRectPropertyInstance class implements the instance class
 *  for the AnimateRectProperty effect.
 *  Flex creates an instance of this class when it plays an AnimateRectProperty
 *  effect; you do not create one yourself.
 *
 *  <p>Every effect class that is a subclass of the TweenEffect class 
 *  supports the following events:</p>
 *  
 *  <ul>
 *    <li><code>tweenEnd</code>: Dispatched when the tween effect ends. </li>
 *  
 *    <li><code>tweenUpdate</code>: Dispatched every time a TweenEffect 
 *      class calculates a new value.</li> 
 *  </ul>
 *  
 *  <p>The event object passed to the event listener for these events is of type TweenEvent. 
 *  The TweenEvent class defines the property <code>value</code>, which contains 
 *  the tween value calculated by the effect. 
 *  For the AnimateRectProperty effect, 
 *  the <code>TweenEvent.value</code> property contains a Number between the values of 
 *  the <code>AnimateRectProperty.fromValue</code> and 
 *  <code>AnimateRectProperty.toValue</code> properties, for the target 
 *  property specified by <code>AnimateRectProperty.property</code>.</p>
 *
 *  @see mx.effects.AnimateRectProperty
 *  @see mx.events.TweenEvent
 */  
public class AnimateRectPropertyInstance extends TweenEffectInstance
{
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

	/**
	 *  Constructor.
	 *
	 *  @param target The Object to animate with this effect.
	 */
	public function AnimateRectPropertyInstance(target:Object)
	{
		super(target);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  toValue
	//----------------------------------

	/**
	 *  The ending value for the effect.
	 *  The default value is the target's current property value.
	 */
	public var toValue:Rectangle = null;
	
	//----------------------------------
	//  isStyle
	//----------------------------------

	/**
	 *  If <code>true</code>, the property attribute is a style and you
	 *  set it by using the <code>setStyle()</code> method. 
	 *  
	 *  @default false
	 */
	 public var isStyle:Boolean = false;
		
	//----------------------------------
	//  property
	//----------------------------------

	/**
	 *  The name of the property on the target to animate.
	 *  This attribute is required.
	 */
	public var property:String;
	
	//----------------------------------
	//  roundValue
	//----------------------------------
	
	/**
	 *  If <code>true</code>, round off the interpolated tweened value
	 *  to the nearest integer. 
	 *  This property is useful if the property you are animating
	 *  is an int or uint.
	 *  
	 *  @default false
	 */
	public var roundValue:Boolean = false;	
		
	//----------------------------------
	//  fromValue
	//----------------------------------

	/**
	 *  The starting value of the property for the effect.
	 *  The default value is the target's current property value.
	 */
	public var fromValue:Rectangle = null;
	
	//--------------------------------------------------------------------------
	//
	//  Overridden methods
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 */
	override public function play():void
	{
		// Do what effects normally do when they start, namely
		// dispatch an 'effectStart' event from the target.
		super.play();
		
		if (fromValue == null)
		{
			fromValue = getCurrentValue();
		}
		
		if (toValue == null)
		{
			if (propertyChanges && propertyChanges.end[property] !== undefined)
				toValue = propertyChanges.end[property];
			else
				toValue = getCurrentValue();
		}
		
		// Create a Tween object to interpolate the verticalScrollPosition.
		tween = createTween(this, [fromValue.x, fromValue.y, fromValue.width, fromValue.height], 
			[toValue.x, toValue.y, toValue.width, toValue.height], duration);

		// If the caller supplied their own easing equation, override the
		// one that's baked into Tween.
		if (easingFunction != null)
			tween.easingFunction = easingFunction;

		mx_internal::applyTweenStartValues();
	}
	
	
	/**
	 *  @private
	 */
	override public function onTweenUpdate(value:Object):void
	{
		var rect: Rectangle;
		if (value is Array) {
			var array: Array = value as Array;
			rect = new Rectangle(value[0], value[1], value[2], value[3]);
			if (!isStyle)
				target[property] = roundValue ? roundRectValues(rect) : rect;	
			else
				target.setStyle(property, rect);
		}
	}
	
	private function roundRectValues(value: Rectangle): Rectangle {
		var rect: Rectangle = Rectangle(value);
		return new Rectangle(Math.round(rect.x), Math.round(rect.y), Math.round(rect.width), Math.round(rect.height));
	}
	
	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 */
	private function getCurrentValue():Rectangle
	{
		var currentValue:Rectangle;
		
		if (!isStyle)
			currentValue = target[property];
		else
			currentValue = target.getStyle(property);
		
		return roundValue ? roundRectValues(currentValue) : currentValue;
	}
}

}
