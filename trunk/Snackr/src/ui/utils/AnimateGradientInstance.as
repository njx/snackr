package ui.utils
{
	import mx.core.mx_internal;
	import com.darronschall.util.ColorUtil;
	
	import mx.effects.effectClasses.TweenEffectInstance;

	public class AnimateGradientInstance extends TweenEffectInstance
	{
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
		public var toValue:Array = null;
		
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
		public var fromValue:Array = null;
		
		/** The start color values for each of the r, g, and b channels */
		protected var startValues:Array;
		
		/** The change in color value for each of the r, g, and b channels. */
		protected var delta:Array;
		
		public function AnimateGradientInstance(target:Object)
		{
			super(target);
		}

		/**
		 * @private
		 */
		override public function play():void
		{
			// We need to call play first so that the fromValue is
			// correctly set, but this has the side effect of calling
			// onTweenUpdate before startValues or delta can be set,
			// so we need to check for that in onTweenUpdate to avoid
			// run time errors.
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
			
			// Calculate the delta for each of the color values
			startValues = [ ColorUtil.intToRgb( fromValue[0] ), ColorUtil.intToRgb( fromValue[1] ) ];
			var stopValues:Array = [ ColorUtil.intToRgb( toValue[0] ), ColorUtil.intToRgb( toValue[1] ) ];
			if(delta == null) {
				delta = new Array(2);
			}
			delta[0] = {
						r: ( startValues[0].r - stopValues[0].r ) / duration,
						g: ( startValues[0].g - stopValues[0].g ) / duration,
						b: ( startValues[0].b - stopValues[0].b ) / duration
					};
			delta[1] = {
						r: ( startValues[1].r - stopValues[1].r ) / duration,
						g: ( startValues[1].g - stopValues[1].g ) / duration,
						b: ( startValues[1].b - stopValues[1].b ) / duration
					};
					
			tween = createTween(this, fromValue, toValue, duration);
	
			// If the caller supplied their own easing equation, override the
			// one that's baked into Tween.
			if (easingFunction != null)
				tween.easingFunction = easingFunction;
	
			mx_internal::applyTweenStartValues();
		}
		
		/**
		 * @private
		 */
		override public function onTweenUpdate( value:Object ):void
		{
			// Bail out if delta hasn't been set yet
			if ( delta == null )
			{
				return;
			}
			
			// Catch the situation in which the playheadTime is actually more
			// than duration, which causes incorrect colors to appear at the 
			// end of the animation.
			var playheadTime:int = this.playheadTime;
			if ( playheadTime > duration )
			{
				// Fix the local playhead time to avoid going past the end color
				playheadTime = duration;
			}
			
			// Calculate the new color value based on the elapased time and the change
			// in color values
			var colorValues:Array = [ ColorUtil.calculateNewColor(startValues[0], delta[0], playheadTime),
							  ColorUtil.calculateNewColor(startValues[1], delta[1], playheadTime) ];
			
			// Either set the property directly, or set it as a style
			if ( !isStyle )
			{
				target[ property ] = colorValues;
			}
			else
			{
				target.setStyle( property, colorValues );
			}
		}		

		private function roundGradientValues(value: Array): Array {
			return new Array(Math.round(value[0]), Math.round(value[1]));
		}
		
		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------
	
		/**
		 *  @private
		 */
		private function getCurrentValue():Array
		{
			var currentValue:Array;
			
			if (!isStyle)
				currentValue = target[property];
			else
				currentValue = target.getStyle(property);
			
			return roundValue ? roundGradientValues(currentValue) : currentValue;
		}

	}
}