package org.papervision3d.core.proto
{
	import flash.geom.Rectangle;
	
	import org.papervision3d.Papervision3D;
	import org.papervision3d.core.culling.FrustumCuller;
	import org.papervision3d.core.math.Matrix3D;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.objects.DisplayObject3D;
	
	/**
	* The CameraObject3D class is the base class for all the cameras that can be placed in a scene.
	* <p/>
	* A camera defines the view from which a scene will be rendered. Different camera settings would present a scene from different points of view.
	* <p/>
	* 3D cameras simulate still-image, motion picture, or video cameras of the real world. When rendering, the scene is drawn as if you were looking through the camera lens.
	*/
	public class CameraObject3D extends DisplayObject3D
	{
		// __________________________________________________________________________
		//

		/**
		* This value specifies the scale at which the 3D objects are rendered. Higher values magnify the scene, compressing distance. Use it in conjunction with focus.
		*/
		public var zoom :Number;
	
	
		/**
		* This value is a positive number representing the distance of the observer from the front clipping plane, which is the closest any object can be to the camera. Use it in conjunction with zoom.
		* <p/>
		* Higher focus values tend to magnify distance between objects while allowing greater depth of field, as if the camera had a wider lenses. One result of using a wide angle lens in proximity to the subject is an apparent perspective distortion: parallel lines may appear to converge and with a fisheye lens, straight edges will appear to bend.
		* <p/>
		* Different lenses generally require a different camera to subject distance to preserve the size of a subject. Changing the angle of view can indirectly distort perspective, modifying the apparent relative size of the subject and foreground.
		*/
		public var focus :Number;
	
	
		/**
		* A Boolean value that determines whether the 3D objects are z-depth sorted between themselves when rendering.
		*/
		public var sort :Boolean;
		 
		/** 
		*  
		*/
		public var eye	:Matrix3D;
		
		/**
		* 
		*/
		public var viewport	:Rectangle;
		
		/** 
		 * 
		 */
		public var frustum	:FrustumCuller;
		
		/**
		 * 
		 */
		public var yUP:Boolean;
		 
		/**
		 * The default position for new cameras.
		 */
		public static var DEFAULT_POS :Number3D = new Number3D( 0, 0, -1000 );
	
		/**
		 * The default UP vector for new cameras.
		 */ 
		public static var DEFAULT_UP:Number3D = new Number3D(0, 1, 0);
		
		/** 
		 * The default viewport for new cameras.
		 */
		public static var DEFAULT_VIEWPORT:Rectangle = new Rectangle(0, 0, 550, 400);
		
		
		// __________________________________________________________________________
		//                                                                      N E W
		// NN  NN EEEEEE WW    WW
		// NNN NN EE     WW WW WW
		// NNNNNN EEEE   WWWWWWWW
		// NN NNN EE     WWW  WWW
		// NN  NN EEEEEE WW    WW
	
		/**
		* The CameraObject3D constructor lets you create cameras for setting up the view from which a scene will be rendered.
		*
		* @param	focus		This value is a positive number representing the distance of the observer from the front clipping plane, which is the closest any object can be to the camera. Use it in conjunction with zoom.
		* <p/>
		* @param	zoom		This value specifies the scale at which the 3D objects are rendered. Higher values magnify the scene, compressing distance. Use it in conjunction with focus.
		* <p/>
		*/
		public function CameraObject3D( focus:Number=500, zoom:Number=3 )
		{
			super();
	
			this.x = DEFAULT_POS.x;
			this.y = DEFAULT_POS.y;
			this.z = DEFAULT_POS.z;
			
			this.zoom  = zoom;
			this.focus = focus;
			this.eye = Matrix3D.IDENTITY;
			this.viewport = DEFAULT_VIEWPORT;
			this.sort = true;
			
			if(Papervision3D.useRIGHTHANDED)
			{
				DEFAULT_UP.y = -1;
				this.yUP = false;
				this.lookAt(DisplayObject3D.ZERO);
			}
			else
				this.yUP = true;
		}
		
		/**
		 * Lookat.
		 * 
		 * @param targetObject
		 * @param upAxis
		 */ 
		public override function lookAt(targetObject:DisplayObject3D, upAxis:Number3D=null):void
		{
			if(this.yUP)
			{
				super.lookAt(targetObject, upAxis);
			}	
			else
			{
				super.lookAt(targetObject, upAxis || DEFAULT_UP);
			}
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
		public function orbit(pitch:Number, yaw:Number, useDegrees:Boolean=true, target:DisplayObject3D=null):void
		{
		}
		
		// ___________________________________________________________________________________________________
		//                                                                                   T R A N S F O R M
		// TTTTTT RRRRR    AA   NN  NN  SSSSS FFFFFF OOOO  RRRRR  MM   MM
		//   TT   RR  RR  AAAA  NNN NN SS     FF    OO  OO RR  RR MMM MMM
		//   TT   RRRRR  AA  AA NNNNNN  SSSS  FFFF  OO  OO RRRRR  MMMMMMM
		//   TT   RR  RR AAAAAA NN NNN     SS FF    OO  OO RR  RR MM M MM
		//   TT   RR  RR AA  AA NN  NN SSSSS  FF     OOOO  RR  RR MM   MM
	
		/**
		* [internal-use] Transforms world coordinates into camera space.
		*/
		// TODO: OPTIMIZE (LOW) Resolve + inline
		public function transformView( transform:Matrix3D=null ):void
		{
			if(this.yUP)
			{
				eye.calculateMultiply(transform || this.transform, _flipY );
				eye.invert(); 
			}
			else
			{
				eye.calculateInverse(transform || this.transform);
			}
		}
	
		static private var _flipY :Matrix3D = Matrix3D.scaleMatrix( 1, -1, 1 );
	
	
		/**
		* Rotate the camera in its vertical plane.
		* <p/>
		* Tilting the camera results in a motion similar to someone nodding their head "yes".
		*
		* @param	angle	Angle to tilt the camera.
		*/
		public function tilt( angle:Number ):void
		{
			if(!_target)
				super.pitch( angle );
		}
	
		/**
		* Rotate the camera in its horizontal plane.
		* <p/>
		* Panning the camera results in a motion similar to someone shaking their head "no".
		*
		* @param	angle	Angle to pan the camera.
		*/
		public function pan( angle:Number ):void
		{
			if(_target)
				super.yaw( angle );
		}
		
		/**
		 * Unproject.
		 * 
		 * @param	mX
		 * @param	mY
		 */ 
		public function unproject(mX:Number, mY:Number):Number3D
		{	
			var persp:Number = (focus*zoom) / (focus);
			
			var vector:Number3D = new Number3D(mX/persp, -mY/persp, focus);

			Matrix3D.multiplyVector3x3(transform, vector);
			
			return vector;
		}
		
		/**
		 * Sets the vertical Field Of View in degrees.
		 * 
		 * @param	degrees
		 */ 
		public function set fov(degrees:Number):void
		{
			if(!viewport || viewport.isEmpty())
			{
				Papervision3D.log("[WARNING] CameraObject3D#viewport not set, can't set fov!");
				return;
			}
			
			var tx	:Number = 0;
			var ty	:Number = 0;
			var tz	:Number = 0;
			
			if(_target)
			{
				tx = _target.world.n14;
				ty = _target.world.n24;
				tz = _target.world.n34;
			}
			
			var vx	:Number = this.x - tx;
			var vy	:Number = this.y - ty;
			var vz	:Number = this.z - tz;

			var h:Number = viewport.height / 2;
			var d:Number = Math.sqrt(vx*vx + vy*vy + vz*vz) + this.focus;
			var r:Number = 180 / Math.PI;
			
			var vfov:Number = (degrees/2) * (Math.PI/180);
			
			this.focus = (h / Math.tan(vfov)) / this.zoom;
		}
		
		/**
		 * Gets the vertical Field Of View in degrees.
		 */ 
		public function get fov():Number
		{
			if(!viewport || viewport.isEmpty())
			{
				Papervision3D.log("[WARNING] CameraObject3D#viewport not set, can't calculate fov!");
				return NaN;
			}
				
			var tx	:Number = 0;
			var ty	:Number = 0;
			var tz	:Number = 0;
			
			if(_target)
			{
				tx = _target.world.n14;
				ty = _target.world.n24;
				tz = _target.world.n34;
			}
			
			var vx	:Number = this.x - tx;
			var vy	:Number = this.y - ty;
			var vz	:Number = this.z - tz;
			
			var f	:Number = this.focus;
			var z	:Number = this.zoom;
			var d	:Number = Math.sqrt(vx*vx + vy*vy + vz*vz) + f;	// distance along camera's z-axis
			var h	:Number = viewport.height / 2;
			var r	:Number = (180/Math.PI);
			
			return Math.atan((((d / f) / z) * h) / d) * r * 2;
		}

		/**
		 * Gets the target for this camera, if any.
		 * 
		 * @return DisplayObject3D
		 */ 
		public function get target():DisplayObject3D
		{
			return _target;	
		}
		
		/**
		 * Sets the target for this camera.
		 * 
		 * @param	object	A DisplayObject3D
		 */
		public function set target(object:DisplayObject3D):void
		{
			_target = object;
		}
		
		protected var _target			: DisplayObject3D;
	}
}