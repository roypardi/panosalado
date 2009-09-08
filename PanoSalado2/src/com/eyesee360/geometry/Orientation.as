package com.eyesee360.geometry
{
	import __AS3__.vec.Vector;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class Orientation extends Matrix3D
	{
		private const D2R = Math.PI/180.0;
		private const R2D = 180.0/Math.PI;
		
		// a.k.a. pitch, yaw, roll
		public function Orientation(tilt:Number, pan:Number, skew:Number)
		{			
			this.orientationAngles = new Vector3D(tilt,pan,skew);
		}
		
		// ??? Should we override other Matrix3D methods to prevent scale or offset?
		
		public function get orientationAngles():Vector3D
		{
			var v:Vector.<Vector3D> = this.decompose();
			var orientation = v[1];
			
			orientation.x *= -R2D;
			orientation.y *= -R2D;
			orientation.z *= R2D;
			
			return orientation;
		}
		
		public function set orientationAngles(orientation:Vector3D):void
		{
			orientation.x *= -D2R;
			orientation.y *= -D2R;
			orientation.z *= D2R;
			
			var v:Vector.<Vector3D> = new Vector(3, true);
			v[1] = orientation;
			this.recompose(v);
		}
		
		public function get pan():Number
		{
			return this.orientationAngles.y;
		}
		
		public function set pan(degrees:Number):void
		{
			var orientation = this.orientationAngles;
			orientation.y = degrees;
			this.orientationAngles = orientation;
		}
		
		public function get tilt():Number
		{
			return this.orientationAngles.x;
		}
		
		public function set tilt(degrees:Number):void
		{
			var orientation = this.orientationAngles;
			orientation.x = degrees;
			this.orientationAngles = orientation;
		}

		public function get skew():Number
		{
			return this.orientationAngles.y;
		}
		
		public function set skew(degrees:Number):void
		{
			var orientation = this.orientationAngles;
			orientation.z = degrees;
			this.orientationAngles = orientation;
		}
	}
}