package org.papervision3d.cameras
{
	import flash.geom.Rectangle;
	
	import org.papervision3d.core.culling.FrustumCuller;
	import org.papervision3d.core.math.Matrix3D;
	import org.papervision3d.core.proto.CameraObject3D;
	import org.papervision3d.objects.DisplayObject3D;
	
	import org.papervision3d.core.math.Number3D;
	
	/**
	 * Camera3D
	 * <p>
	 * Camera3D is the basic camera used by Papervision3D.
	 * </p>
	 * 
	 * @author Tim Knip
	 */ 
	public class Camera3D extends CameraObject3D
	{	
		/** The default distance to the far plane. */
		public static var DEFAULT_FAR:Number = 20000;
		
		/**
		 * Constructor.
		 * 
		 * @param	focus		This value is a positive number representing the distance of the observer from the front clipping plane, which is the closest any object can be to the camera. Use it in conjunction with zoom.
		 * <p/>
		 * @param	zoom		This value specifies the scale at which the 3D objects are rendered. Higher values magnify the scene, compressing distance. Use it in conjunction with focus.
		 * <p/>		 
		 * @param	useFrustum	Boolean indicating whether to use frustum culling. When true all objects outside the view will be culled.
		 * <p/>
		 */ 
		public function Camera3D(focus:Number=10, zoom:Number=40, useFrustum:Boolean=false)
		{
			super(focus, zoom);
			
			_prevFocus = 0;
			_prevZoom = 0;
			_frustumCulling = useFrustum;
			_far = DEFAULT_FAR;
			_focusFix = Matrix3D.IDENTITY;
		}
		
		/**
		 * Orbits the camera around the specified target. If no target is specified the 
		 * camera's #target property is used. If this camera's #target property equals null
		 * the camera orbits the origin (0, 0, 0).
		 * 
		 * @param	pitch	Rotation around X=axis (looking up or down).
		 * @param	yaw		Rotation around Y-axis (looking left or right).
		 * @param	useDegrees 	Whether to use degrees for pitch and yaw (defaults to 'true').
		 * @param	target	An optional target to orbit around.
		 */ 
		public override function orbit(pitch:Number, yaw:Number, useDegrees:Boolean=true, target:DisplayObject3D=null):void
		{
			target = target || _target;
			target = target || DisplayObject3D.ZERO;
			
			if(useDegrees)
			{
				pitch *= (Math.PI/180);
				yaw *= (Math.PI/180);
			}
			
			// Number3D.sub
			var dx 			:Number = target.world.n14 - this.x;
			var dy 			:Number = target.world.n24 - this.y;
			var dz 			:Number = target.world.n34 - this.z;
			
			// Number3D.modulo
			var distance 	:Number = Math.sqrt(dx*dx+dy*dy+dz*dz);

			// Rotations
			var rx :Number = Math.cos(yaw) * Math.sin(pitch);
			var rz :Number = Math.sin(yaw) * Math.sin(pitch);
			var ry :Number = Math.cos(pitch);
			
			// Move to specified location
			this.x = target.world.n14 + (rx * distance);
			this.y = target.world.n24 + (ry * distance);
			this.z = target.world.n34 + (rz * distance);
			
			this.lookAt(target);
		}
		
		/**
		 * Updates the internal camera settings.
		 * 
		 * @param	viewport
		 */ 
		public function update(viewport:Rectangle):void
		{
			if(!viewport)
				throw new Error("Camera3D#update: Invalid viewport rectangle! " + viewport);
	
			this.viewport = viewport;

			// used to detect value changes
			_prevFocus = this.focus;
			_prevZoom = this.zoom;
			_prevWidth = this.viewport.width;
			_prevHeight = this.viewport.height;
			
			this.frustumCulling = _frustumCulling;
		}
		
		/**
		 * [INTERNAL-USE] Transforms world coordinates into camera space.
		 * 
		 * @param	transform	An optional transform.
		 */ 
		public override function transformView(transform:Matrix3D=null):void
		{	
			// check whether camera internals need updating
			if(focus != _prevFocus || zoom != _prevZoom || viewport.width != _prevWidth || viewport.height != _prevHeight)
			{
				update(viewport);
			}
			
			// handle camera 'types'
			if(_target)
			{
				// Target camera...
				lookAt(_target);
			}
			else if(_transformDirty)
			{
				// Free camera...
				updateTransform();
			}
			
			_focusFix.copy(this.transform);
			_focusFix.n14 += focus * this.transform.n13;
			_focusFix.n24 += focus * this.transform.n23;
			_focusFix.n34 += focus * this.transform.n33;
			
			super.transformView(_focusFix);
			
			// handle frustum if available
			if(frustum is FrustumCuller)
			{
				// The frustum culler simply uses the camera transform
				frustum.transform.copy(this.transform);
			}
		}
		
		/**
		 * Whether this camera uses frustum culling.
		 * 
		 * @return Boolean
		 */ 
		public function get frustumCulling():Boolean
		{
			return _frustumCulling;	
		}
		
		/**
		 * Whether this camera uses frustum culling.
		 * 
		 * @return Boolean
		 */ 
		public function set frustumCulling(value:Boolean):void
		{
			_frustumCulling = value;
			
			if(_frustumCulling)
			{
				if(!this.frustum)
					this.frustum = new FrustumCuller();
					
				this.frustum.initialize(this.fov, this.viewport.width/this.viewport.height, this.focus/this.zoom, _far);
			}
			else
				this.frustum = null;	
		}
		
		/**
		 * Gets the distance to the far plane.
		 */ 
		public function get far():Number
		{
			return _far;
		}
		
		/**
		 * Sets the distance to the far plane.
		 * 
		 * @param	value
		 */ 
		public function set far(value:Number):void
		{
			if(value > this.focus)
			{
				_far = value;
				this.update(this.viewport);
			}
		}
		
		/**
		 * Gets the distance to the near plane (note that this simply is an alias for #focus).
		 */ 
		public function get near():Number
		{
			return this.focus;
		}
		
		/**
		 * Sets the distance to the near plane (note that this is simply an alias for #focus).
		 * 
		 * @param	value
		 */  
		public function set near(value:Number):void
		{
			if(value > 0)
			{
				this.focus = value;
				this.update(this.viewport);
			}
		}

		private var _frustumCulling	: Boolean;
		private var _far			: Number;
		private var _prevFocus		: Number;
		private var _prevZoom		: Number;
		private var _prevWidth		: Number;
		private var _prevHeight		: Number;
		private var _focusFix		: Matrix3D;
		
		
		
		// modifications by zephyr renner
		
		private var _hfov:Number = 0;
		private var _vfov:Number = 0;
		
		protected var toDoubledDegrees:Number = 360/Math.PI;
		
		public function get hfov():Number
		{
			var cameraPosition:Number3D = new Number3D(),
			pt1:Number3D,
			pt2:Number3D,
			delta:Number3D,
			oppo:Number;
			
			cameraPosition.x = this.x;
			cameraPosition.y = this.y;
			cameraPosition.z = this.z;
			
			pt1 = unproject(0,0);
			pt2 = unproject(viewport.width*0.5, 0);
			pt1.plusEq(cameraPosition);
			pt2.plusEq(cameraPosition);
			
			delta = Number3D.sub(pt2, pt1);
			oppo = Math.sqrt(delta.x*delta.x + delta.y*delta.y + delta.z*delta.z);
	
			_hfov = Math.atan2(oppo,this.focus) * toDoubledDegrees;
			
			return _hfov;
		}
		public function get vfov():Number
		{
			var cameraPosition:Number3D = new Number3D(),
			pt1:Number3D,
			pt2:Number3D,
			delta:Number3D,
			oppo:Number;
			
			cameraPosition.x = this.x;
			cameraPosition.y = this.y;
			cameraPosition.z = this.z;
			
			pt1 = unproject(0,0);
			pt2 = unproject(0, viewport.height*0.5);
			pt1.plusEq(cameraPosition);
			pt2.plusEq(cameraPosition);
			
			delta = Number3D.sub(pt2, pt1);
			oppo = Math.sqrt(delta.x*delta.x + delta.y*delta.y + delta.z*delta.z);
	
			_vfov = Math.atan2(oppo,this.focus) * toDoubledDegrees;
			
			return _vfov;
		}
	}
}
