package com.panosalado.motion
{
	import com.gskinner.motion.GTween;

	public class GTweenVelocity extends GTween
	{
		// We re-use endValues[] as velocities.
		
		public function GTweenVelocity(target:Object=null, duration:Number=10, properties:Object=null, tweenProperties:Object=null)
		{
			super(target, duration, properties, tweenProperties);
		}

		// logic that runs each frame. Calculates eased position, updates properties, and reassigns the target if an assignmentTarget was set.
		/** @private **/
		override protected function updateProperties():void {
			for (var n:String in endValues) {
				updateVelocityProperty(n,endValues[n]);
			}
			if (assignmentTarget && assignmentProperty) { assignmentTarget[assignmentProperty] = _propertyTarget; }
		}
		
		// updates a single property. Mostly for overriding.
		/** @private **/
		private var lastTime:Number = 0;
		
		protected function updateVelocityProperty(property:String, velocity:Number):void {
			var dt:Number = _position - _previousPosition;
			var dv:Number = velocity*dt;
			_target[property] += dv;
		}

	}
}