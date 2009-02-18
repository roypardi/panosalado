package zephyr.cameras
{
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.math.Number3D;

	public class PSCamera3D extends Camera3D
	{
		
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