package com.eyesee360.geometry
{
	import flash.geom.PerspectiveProjection;
	import flash.geom.Rectangle;
	
	public class RectilinearProjection implements IProjection
	{
		private const D2R = Math.PI/180.0;
		private const R2D = 180.0/Math.PI;

		private var _orientation:Orientation;
		private var _viewPlane:Rectangle;
		private var _preserveFOVDirection:Number;
		private var _FOV:Number;
		private var _aspectRatio:Number;
		
		private const FOV_PRESERVE_VERTICAL:Number = 1;
		private const FOV_PRESERVE_HORIZONTAL:Number = 2;
		private const FOV_PRESERVE_DIAGONAL:Number = 3;
		
		public function RectilinearProjection()
		{
			_orientation = new Orientation();
			_aspectRatio = 1.0;
			this.verticalFOV = 90.0;
		}

		public function get type():String
		{
			return Projection.RECTILINEAR;
		}
		
		public function get orientation():Orientation
		{
			return _orientation;
		}
		
		public function set orientation(o:Orientation):void
		{
			_orientation = o;
		}
		
		public function get viewPlane():Rectangle
		{
			return _viewPlane;
		}
		
		public function set viewPlane(plane:Rectangle):void
		{
			_viewPlane = plane;
		}
		
		public function get isCentered():Boolean
		{
			return (_viewPlane.left = -_viewPlane.right &&
			        _viewPlane.top = -_viewPlane.bottom);
		}
		
		public function get aspectRatio():Number
		{
			return _aspectRatio;
		}
		
		public function set aspectRatio(aspect:Number):void
		{
			_aspectRatio = aspect;
			
			switch (_preserveFOVDirection) {
				case FOV_PRESERVE_VERTICAL:
					this.verticalFOV = _FOV;
					break;
				case FOV_PRESERVE_HORIZONTAL:
					this.horizontalFOV = _FOV;
					break;
				case FOV_PRESERVE_DIAGONAL:
					this.diagonalFOV = _FOV;
					break;
			}
		}
		
		public function get verticalFOV():Number
		{
			return 2.0 * Math.atan(_viewPlane.height/2.0) * R2D;
		}
		
		public function set verticalFOV(degrees:Number):void
		{
			var height = 2.0 * Math.tan(degrees * D2R / 2.0);
			var width = height * _aspectRatio;
			_viewPlane = new Rectangle(-width/2.0, -height/2.0, width, height);
			_preserveFOVDirection = FOV_PRESERVE_VERTICAL;
			_FOV = degrees;
		}
		
		public function get horizontalFOV():Number
		{
			return 2.0 * Math.atan(_viewPlane.width/2.0) * R2D;
		}
		
		public function set horizontalFOV(degrees:Number):void
		{
			var width = 2.0 * Math.tan(degrees * D2R / 2.0);
			var height = height / _aspectRatio;
			_viewPlane = new Rectangle(-width/2.0, -height/2.0, width, height); 
			_preserveFOVDirection = FOV_PRESERVE_HORIZONAL;
			_FOV = degrees;
		}
		
		public function get diagonalFOV():Number
		{
			Math.
			var d = Math.sqrt(_viewPlane.width * _viewPlane.width 
							+ _viewPlane.height * _viewPlane.height);
			return 2.0 * Math.atan(d/2.0) * R2D;
		}
		
		public function set diagonalFOV(degrees:Number):void
		{
			var d = Math.sqrt(1.0 + _aspectRatio);
			var xScale = _aspectRatio / d;
			var yScale = 1.0 / d;
			
			var diagonal = 2.0 * Math.tan(degrees * D2R / 2.0);
			var width = diagonal * xScale;
			var height = diagonal * yScale;
			_viewPlane = new Rectangle(-width/2.0, -height/2.0, width, height); 
			_preserveFOVDirection = FOV_PRESERVE_DIAGONAL;
			_FOV = degrees;
		}
		
		// Could add conversion methods to/from PerpectiveProjection, if useful. 
	}
}