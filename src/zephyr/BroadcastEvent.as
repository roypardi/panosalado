package zephyr
{
	import flash.events.Event;
	
	public class BroadcastEvent extends Event
	{
		public static const HIDE_CURSOR:String = "hideCursor";
		public static const SHOW_CURSOR:String = "showCursor";
		
		public function BroadcastEvent( type:String )
		{
			super(type);
		}
		
		override public function clone():Event
		{
			return new BroadcastEvent( type );
		}
		
		override public function toString():String
		{
			return formatToString("BroadcastEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
		
	}
}