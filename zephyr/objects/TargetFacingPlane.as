package zephyr.objects
{
	import org.papervision3d.objects.primitives.Plane;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.core.proto.MaterialObject3D;
	
	public class TargetFacingPlane extends Plane
	{
		public var facingTarget:DisplayObject3D;
		private var _created:Boolean = false;
		
		public function TargetFacingPlane
			(
			facingTarget:DisplayObject3D, 
			material:MaterialObject3D=null, 
			width:Number=0, 
			height:Number=0, 
			segmentsW:Number=0, 
			segmentsH:Number=0, 
			initObject:Object=null
			)
		{
			super( material, width, height, segmentsW, segmentsH );
			this.facingTarget = facingTarget;
			this.lookAt( facingTarget );
			_created = true;
		}
		
		override public function get x():Number
		{
			return this.transform.n14;
		}
	
		override public function set x( value:Number ):void
		{
			this.transform.n14 = value;
			if (_created) this.lookAt( facingTarget );
		}
		
		override public function get y():Number
		{
			return this.transform.n24;
		}
	
		override public function set y( value:Number ):void
		{
			this.transform.n24 = value;
			if (_created) this.lookAt( facingTarget );
		}
	
		override public function get z():Number
		{
			return this.transform.n34;
		}
	
		override public function set z( value:Number ):void
		{
			this.transform.n34 = value;
			if (_created) this.lookAt( facingTarget );
		}
		
	}
}
