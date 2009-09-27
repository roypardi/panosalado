package com.eyesee360.geometry
{
	import __AS3__.vec.Vector;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	/**
	* This event is dispatched each time the orientation updates.
	*
	* @eventType flash.events.Event
	**/
	[Event(name="change", type="flash.events.Event")]

	public class Orientation extends flash.events.EventDispatcher
	{
		private const D2R:Number = Math.PI/180.0;
		private const R2D:Number = 180.0/Math.PI;
		
		private var _matrix:Matrix3D;
		
		// a.k.a. pitch, yaw, roll
		public function Orientation(tilt:Number = 0.0, pan:Number = 0.0, skew:Number = 0.0)
		{
			_matrix = new Matrix3D();
			this.orientationAngles = new Vector3D(tilt,pan,skew);
		}
		
		public function get orientationAngles():Vector3D
		{
			var m:Matrix3D = _matrix.clone();
			m.prependRotation(90.0, Vector3D.Z_AXIS);
			var v:Vector.<Vector3D> = m.decompose();
			var orientation:Vector3D = v[1];
			
			orientation.x *= R2D;
			orientation.y *= R2D;
			orientation.z *= R2D;
			orientation.z -= 90.0;
			
			return orientation;
		}
		
		private function didChange():void
		{
			var event:Event = new Event(Event.CHANGE);
			this.dispatchEvent(event);
		}
		
		public function set orientationAngles(orientation:Vector3D):void
		{
			orientation.x *= D2R;
			orientation.y *= D2R;
			orientation.z += 90.0;
			orientation.z *= D2R;
			
			// we want x = pan, y = tilt and z = skew
			var v:Vector.<Vector3D> = _matrix.decompose();
			
			v[1] = orientation;
			
			_matrix.recompose(v);
			_matrix.prependRotation(-90.0, Vector3D.Z_AXIS);
			
			this.didChange();
		}
		
		public function get pan():Number
		{
			return this.orientationAngles.x;
		}
		
		public function set pan(degrees:Number):void
		{
			var orientation:Vector3D = this.orientationAngles;
			orientation.x = degrees;
			this.orientationAngles = orientation;
		}
		
		public function panBy(degrees:Number):void
		{
			this.appendRotation(degrees, Vector3D.Y_AXIS);
		}
		
		public function get tilt():Number
		{
			return this.orientationAngles.y;
		}
		
		public function set tilt(degrees:Number):void
		{
			var orientation:Vector3D = this.orientationAngles;
			if (degrees > 90) degrees = 90;
			if (degrees < -90) degrees = -90;
			orientation.y = degrees;
			this.orientationAngles = orientation;
		}
		
		public function tiltBy(degrees:Number):void
		{
			this.appendRotation(-degrees, Vector3D.X_AXIS);
		}

		public function get skew():Number
		{
			return this.orientationAngles.z;
		}
		
		public function set skew(degrees:Number):void
		{
			var orientation:Vector3D = this.orientationAngles;
			orientation.z = degrees;
			this.orientationAngles = orientation;
		}

		public function skewBy(degrees:Number):void
		{
			this.appendRotation(degrees, Vector3D.Z_AXIS);
		}		
		
		
		// Relay methods for the Matrix3D
		public function get rawData():Vector.<Number>
		{
			return _matrix.rawData;
		}
		
		
		// Additional mutators
		public function appendRotation(degrees:Number, axis:Vector3D, pivotPoint:Vector3D = null):void
		{
			_matrix.appendRotation(degrees, axis, pivotPoint);
			this.didChange();
		}
		
		private static function orientationFromMatrix3D(matrix:Matrix3D):Orientation
		{
			var orientation:Orientation = new Orientation();
			orientation._matrix = matrix;
			return orientation;
		}
		
		public function clone():Orientation
		{
			return Orientation.orientationFromMatrix3D(_matrix.clone());
		}
		
		public static function interpolate(thisOrientation:Orientation, toOrientation:Orientation, percent:Number):Orientation
		{
			var interpolatedMatrix:Matrix3D = Matrix3D.interpolate(thisOrientation._matrix, toOrientation._matrix, percent);
			return Orientation.orientationFromMatrix3D(interpolatedMatrix);
		}
		
		public function interpolateTo(toOrientation:Orientation, percent:Number):void
		{
			_matrix.interpolateTo(toOrientation._matrix, percent);
			this.didChange();
		}
		
		public function identity():void
		{
			_matrix.identity();
			this.didChange();
		}
	}
}