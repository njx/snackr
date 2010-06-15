////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2005-2007 Adobe Systems Incorporated
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

import mx.effects.IEffectInstance;
import mx.effects.TweenEffect;

/**
 *  The AnimateRectProperty effect animates a property or style of a component. 
 *  You specify the property name, start value, and end value
 *  of the property to animate. 
 *  The effect sets the property to the start value, and then updates
 *  the property value over the duration of the effect
 *  until it reaches the end value. 
 *
 *  <p>For example, to change the width of a Button control, 
 *  you can specify <code>width</code> as the property to animate, 
 *  and starting and ending width values to the effect.</p> 
 *
 *  @mxml
 *
 *  <p>The <code>&lt;mx:AnimateRectProperty&gt;</code> tag
 *  inherits all the tag attributes of its superclass
 *  and adds the following tag attributes:</p>
 *  
 *  <pre>
 *  &lt;mx:AnimateRectProperty 
 *    id="ID"
 *	  fromValue="0"
 *    isStyle="false|true"	 
 *    property="<i>required</i>"
 *    roundValue="false|true"
 *    toValue="0" 
 *  /&gt;
 *  </pre>
 *  
 *  @see mx.effects.effectClasses.AnimateRectPropertyInstance
 *
 *  @includeExample examples/AnimateRectPropertyEffectExample.mxml
 */
public class AnimateRectProperty extends TweenEffect
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
	public function AnimateRectProperty(target:Object = null)
	{
		super(target);
		
		instanceClass = AnimateRectPropertyInstance;
	}
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  toValue
	//----------------------------------

	[Inspectable(category="General", defaultValue="0")]

	/**
	 *  The ending value for the effect.
	 *  The default value is the target's current property value.
	 */
	public var toValue:Rectangle = null;
	
	//----------------------------------
	//  isStyle
	//----------------------------------

	[Inspectable(category="General", defaultValue="false")]

	/**
	 *  If <code>true</code>, the property attribute is a style and you set
	 *  it by using the <code>setStyle()</code> method. 
	 *  @default false
	 */
	public var isStyle:Boolean = false;

	//----------------------------------
	//  property
	//----------------------------------

	[Inspectable(category="General", defaultValue="")]

	/**
	 *  The name of the property on the target to animate.
	 *  This attribute is required.
	 */
	public var property:String;

	//----------------------------------
	//  roundValue
	//----------------------------------
	
	[Inspectable(category="General", defaultValue="false")]

	/**
	 *  If <code>true</code>, round off the interpolated tweened value
	 *  to the nearest integer. 
	 *  This property is useful if the property you are animating
	 *  is an int or uint.
	 *  @default false
	 */
	public var roundValue:Boolean = false;

	//----------------------------------
	//  fromValue
	//----------------------------------

	[Inspectable(category="General", defaultValue="0")]

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
	override public function getAffectedProperties():Array /* of String */
	{
		return [ property ];
	}

	/**
	 *  @private
	 */
	override public function get relevantStyles():Array /* of String */
	{
		return isStyle ? [ property ] : [];
	}
	
	/**
	 *  @private
	 */
	override protected function initInstance(instance:IEffectInstance):void
	{
		super.initInstance(instance);
		
		var animateRectPropertyInstance:AnimateRectPropertyInstance =
			AnimateRectPropertyInstance(instance);

		animateRectPropertyInstance.fromValue = fromValue;
		animateRectPropertyInstance.toValue = toValue;
		animateRectPropertyInstance.property = property;
		animateRectPropertyInstance.isStyle = isStyle;
		animateRectPropertyInstance.roundValue = roundValue;
	}
}
	
}
