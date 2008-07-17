package zephyr.cameracontrol
{
	import flash.events.Event;
	
	import org.papervision3d.core.render.data.RenderSessionData;

	public class CameraControllerEvent extends Event
	{
		public static const DECELERATING:String = "gliding";
		public static const ACCELERATING:String = "accelerating";
		public static const STOPPED:String = "stopped";
		public static const MOVING:String = "moving";
		public static const AUTOROTATING:String = "autorotating";
		
		public var deltaPan:Number = 0;
		
		public var deltaTilt:Number = 0;
		
		public var deltaZoom:Number = 0;
		
		public function CameraControllerEvent( type:String, dp:Number=0, dt:Number=0, dz:Number=0 )
		{
			super(type);
			this.deltaPan = dp;
			this.deltaTilt = dt;
			this.deltaZoom = dz;
		}
		
		override public function clone():Event
		{
			return new CameraControllerEvent(type, deltaPan, deltaTilt, deltaZoom);
		}
		
		override public function toString():String
		{
			return formatToString("CameraControllerEvent", "type", "bubbles", "cancelable", "eventPhase", "deltaPan", "deltaTilt", "deltaZoom");
		}
		
	}
}