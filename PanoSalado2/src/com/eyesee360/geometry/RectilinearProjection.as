package com.eyesee360.geometry
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	
	/**
	* This event is dispatched each time the projection updates.
	*
	* @eventType flash.events.Event
	**/
	[Event(name="change", type="flash.events.Event")]

	public class RectilinearProjection extends flash.events.EventDispatcher implements IProjection
	{
		private const D2R:Number = Math.PI/180.0;
		private const R2D:Number = 180.0/Math.PI;

		private const FOV_PRESERVE_VERTICAL:Number = 1;
		private const FOV_PRESERVE_HORIZONTAL:Number = 2;
		private const FOV_PRESERVE_DIAGONAL:Number = 3;

		private var _orientation:Orientation;
		private var _viewPlane:Rectangle;
		private var _preserveFOVDirection:Number;
		private var _FOV:Number;
		private var _aspectRatio:Number;
		private var _inConstrainView:Boolean;		
		
		public var minPan:Number = 9999;
		public var maxPan:Number = 9999;
		public var minTilt:Number = 9999;
		public var maxTilt:Number = 9999;
		public var minVFOV:Number = 9999;
		public var maxVFOV:Number = 9999;

		public function RectilinearProjection()
		{
			_orientation = new Orientation();
			_orientation.addEventListener(Event.CHANGE, orientationChanged);
			_aspectRatio = 1.0;
			_inConstrainView = false;
			this.verticalFOV = 70.0;
		}
		
		private function didChange():void
		{
			var event:Event = new Event(Event.CHANGE);
			this.dispatchEvent(event);
		}
		
		private function orientationChanged(e:Event):void
		{
			// relay the change.
			this.didChange();
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
			this.didChange();
		}
		
		public function get viewPlane():Rectangle
		{
			return _viewPlane;
		}
		
		public function set viewPlane(plane:Rectangle):void
		{
			_viewPlane = plane;
			this.didChange();
		}
		
		public function get bounds():Array
		{
			return [_viewPlane.x, _viewPlane.y, _viewPlane.width, _viewPlane.height];
		}
		
		public function set bounds(bounds:Array):void
		{
			this.viewPlane = new Rectangle(bounds[0], bounds[1], bounds[2], bounds[3]);
		}
		
		public function get boundsDeg():Array
		{
			return this.bounds;
		}
		
		public function get isCentered():Boolean
		{
			var isCentered:Boolean = (_viewPlane.left == -_viewPlane.right &&
			        				  _viewPlane.top == -_viewPlane.bottom);
			return isCentered;
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
			var height:Number = 2.0 * Math.tan(degrees * D2R / 2.0);
			var width:Number = height * _aspectRatio;
			_viewPlane = new Rectangle(-width/2.0, -height/2.0, width, height);
			_preserveFOVDirection = FOV_PRESERVE_VERTICAL;
			_FOV = degrees;
			this.constrainView();
			this.didChange();
		}
		
		public function get horizontalFOV():Number
		{
			return 2.0 * Math.atan(_viewPlane.width/2.0) * R2D;
		}
		
		public function set horizontalFOV(degrees:Number):void
		{
			var width:Number = 2.0 * Math.tan(degrees * D2R / 2.0);
			var height:Number = height / _aspectRatio;
			_viewPlane = new Rectangle(-width/2.0, -height/2.0, width, height); 
			_preserveFOVDirection = FOV_PRESERVE_HORIZONTAL;
			_FOV = degrees;
			this.constrainView();
			this.didChange();
		}
		
		public function get diagonalFOV():Number
		{
			var d:Number = Math.sqrt(_viewPlane.width * _viewPlane.width 
								   + _viewPlane.height * _viewPlane.height);
			return 2.0 * Math.atan(d/2.0) * R2D;
		}
		
		public function set diagonalFOV(degrees:Number):void
		{
			var d:Number = Math.sqrt(1.0 + _aspectRatio);
			var xScale:Number = _aspectRatio / d;
			var yScale:Number = 1.0 / d;
			
			var diagonal:Number = 2.0 * Math.tan(degrees * D2R / 2.0);
			var width:Number = diagonal * xScale;
			var height:Number = diagonal * yScale;
			_viewPlane = new Rectangle(-width/2.0, -height/2.0, width, height); 
			_preserveFOVDirection = FOV_PRESERVE_DIAGONAL;
			_FOV = degrees;
			this.constrainView();
			this.didChange();
		}
		
		public function get pan():Number
		{
			return this.orientation.pan;
		}
		
		public function set pan(degrees:Number):void
		{
			this.orientation.pan = degrees;
			this.constrainView();
		}
		
		public function get tilt():Number
		{
			return this.orientation.tilt;
		}
		
		public function set tilt(degrees:Number):void
		{
			this.orientation.tilt = degrees;
			this.constrainView();
		}
		
		public function get skew():Number
		{
			return this.orientation.skew;
		}
		
		public function set skew(degrees:Number):void
		{
			this.orientation.skew = degrees;
			this.constrainView();
		}

		public function setConstraintsFromProjection(proj:IProjection):void
		{
			var bounds:Array = proj.boundsDeg;
			
			// Check for pan constraint
			if (bounds[2] < 360.0) {
				minPan = bounds[0];
				maxPan = bounds[0] + bounds[2];
			}
			
			minTilt = bounds[1];
			maxTilt = bounds[1] + bounds[3];
			
			maxVFOV = bounds[3];
			if (maxVFOV > 120) {
				maxVFOV = 120;
			}
			
			minVFOV = 30.0;	// arbitrary
		}

		private function constrainView():void
		{
			// Prevent re-entry from FOV methods
			if (!_inConstrainView) {
				_inConstrainView = true;
				
	            if (maxVFOV == 9999) {
	                if (maxTilt != 9999 && minTilt != 9999) {
	                    maxVFOV = maxTilt - minTilt;
	                    if (maxVFOV > 100) maxVFOV = 100;
	                } else {
	                    maxVFOV = 100;
	                }
	            }
	            if (minVFOV == 9999) {
	                minVFOV = 30;
	            }
	            
	            if (this.verticalFOV > maxVFOV) {
	                this.verticalFOV = maxVFOV;
	            }
	            if (this.verticalFOV < minVFOV) {
	                this.verticalFOV = minVFOV;
	            }
	            
				var hfov:Number = this.horizontalFOV;
				var vfov:Number = this.verticalFOV;
	
	            if (minPan != 9999) {
	                if (this.orientation.pan - hfov * 0.5 < minPan) {
	                    this.orientation.pan = minPan + hfov * 0.5;
	                }
	            }
	            if (maxPan != 9999) {
	                if (this.orientation.pan + hfov * 0.5 > maxPan) {
	                    this.orientation.pan = maxPan - hfov * 0.5;
	                }
	            }
	
				if (maxTilt != 9999) {
				    if (maxTilt == 90 && this.orientation.tilt > 90) {
				        this.orientation.tilt = 90;
				    } else if (this.orientation.tilt + vfov * 0.5 > maxTilt) {
				        this.orientation.tilt = maxTilt - vfov * 0.5;
			        }
			    }
			    if (minTilt != 9999) {
				    if (minTilt == -90 && this.orientation.tilt < -90) {
				        this.orientation.tilt = -90;
				    } else if (this.orientation.tilt - vfov * 0.5 < minTilt) {
				        this.orientation.tilt = minTilt + vfov * 0.5;
			        }
		        }
		        
		        _inConstrainView = false;
			}
	    }
	    		
		// Could add conversion methods to/from PerpectiveProjection, if useful.
	}
}