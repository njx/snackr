package ui.utils
{
	import mx.effects.IEffectInstance;
	import mx.effects.TweenEffect;

	public class AnimateGradient extends TweenEffect
	{
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
		public var toValue:Array = null;
		
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
		public var fromValue:Array = null;
	
		public function AnimateGradient(target:Object=null)
		{
			super(target);
			
			instanceClass = AnimateGradientInstance;
		}
		
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
			
			var animateGradientInstance:AnimateGradientInstance =
				AnimateGradientInstance(instance);
	
			animateGradientInstance.fromValue = fromValue;
			animateGradientInstance.toValue = toValue;
			animateGradientInstance.property = property;
			animateGradientInstance.isStyle = isStyle;
			animateGradientInstance.roundValue = roundValue;
		}
		
		
	}
}