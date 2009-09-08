package com.eyesee360.geometry
{
	import com.adobe.serialization.json.JSON;
	
	import flash.display.BitmapData;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	dynamic public class Projection extends Proxy, IProjection
	{
		public const EQUIRECTANGULAR = "equirectangular";
		public const CYLINDRICAL = "cylindrical";
		public const RECTILINEAR = "rectilinear";
		
		private const D2R = Math.PI/180.0;
		private const R2D = 180.0/Math.PI;
		private var _data:Object;
		
		// Factory
		public static function projectionFromJSON(json:String):Projection
		{
			var projData:Object = JSON.decode(json);
			return new Projection(projData);
		}
		
		// Factory
		public static function guessProjectionFromBitmapData(bitmapData:BitmapData):Projection
		{
			var data:Object;
			if (bitmapData.width = 2*bitmapData.height) {
				// guess equirectangular (full sphere)
				data = { type:EQUIRECTANGULAR, bounds:[-180.0, -90.0, 360.0, 180.0] };
			} else {
				// guess cylindrical, centered on horizon
				var radius:Number = bitmapData.width / (2*Math.PI);
				var tiltLim:Number = R2D * Math.atan2(bitmapData.height/2, radius);
				data = { type:CYLINDRICAL, bounds:[-180.0, -tiltLim, 360.0, 2*tiltLim] };
			}
			var proj:Projection = new Projection(data);
			return proj;
		}

		private function Projection(data:Object)
		{
			_data = data;
		}
		
		public function get type():String
		{
			return _data.type;
		}
		
		public function get boundsRad():Array
		{
			var boundsDeg:* = this.bounds;
			var boundsRad = [
				boundsDeg[0] * D2R, boundsDeg[1] * D2R,
				boundsDeg[2] * D2R, boundsDeg[3] * D2R
			;
			return boundsRad;
		}
		
	    override flash_proxy function getProperty(name:*):* 
	    {
	        return _data[name];
	    }
	
	    override flash_proxy function setProperty(name:*, value:*):void 
	    {
	        _data[name] = value;
	    }
	}
}