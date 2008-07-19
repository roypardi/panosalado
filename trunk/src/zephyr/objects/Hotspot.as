package zephyr.objects
{
	import org.papervision3d.objects.primitives.Plane;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.core.proto.MaterialObject3D;
	
	public class Hotspot extends Plane
	{
		//public var facingTarget:DisplayObject3D;
		//private var _created:Boolean = false;
		private var _pan:Number = 0;
		private var _tilt:Number = 0;
		
		private static var piOver180:Number = Math.PI/180
		
		public function Hotspot
			( 
			pan:Number, 
			tilt:Number,
			material:MaterialObject3D=null, 
			width:Number=0, 
			height:Number=0, 
			segmentsW:Number=0, 
			segmentsH:Number=0
			)
		{
			super( material, width, height, segmentsW, segmentsH );
			
			this.pan = pan;
			this.tilt = tilt;
		}
		
		public function set pan(value:Number):void
		{
			this._pan = value;
			
			var p:Number3D = pinToSphere(40000,_pan,_tilt);
			
			this.x = p.x;
			this.y = p.y;
			this.z = p.z;
		}
		public function get pan():Number
		{
			return _pan;
		}
		
		public function set tilt(value:Number):void
		{
			this._tilt = value;
			
			var p:Number3D = pinToSphere(40000,_pan,_tilt);
			
			this.x = p.x;
			this.y = p.y;
			this.z = p.z;
		}
		public function get tilt():Number
		{
			return _tilt;
		}
		
		override public function get x():Number
		{
			return this.transform.n14;
		}
	
		override public function set x( value:Number ):void
		{ 
			this.transform.n14 = value;
			this.rotationX = -tilt;
			this.rotationY = pan;
		}
		
		override public function get y():Number
		{
			return this.transform.n24;
		}
	
		override public function set y( value:Number ):void
		{ 
			this.transform.n24 = value;
			this.rotationX = -tilt;
			this.rotationY = pan;
		}
	
		override public function get z():Number
		{
			return this.transform.n34;
		}
	
		override public function set z( value:Number ):void
		{ 
			this.transform.n34 = value;
			this.rotationX = -tilt;
			this.rotationY = pan;
		}
		
		private function pinToSphere(r:Number, p:Number, t:Number):Number3D
		{
			var pr:Number	= (-1*(p - 90)) * piOver180; 
			var tr:Number	= t * piOver180;
			var xc:Number = r * Math.cos(pr) * Math.cos(tr);
			var yc:Number = r * Math.sin(tr);
			var zc:Number = r * Math.sin(pr) * Math.cos(tr);
			
			var n:Number3D = new Number3D();
			n.x = xc;
			n.y = yc;
			n.z = zc;
			return n;
		}
		
		
	}
}
