package zephyr
{
	import flash.events.Event;
	
	public class BroadcastEvent extends Event
	{
		public static const ALL_LAYERS_LOADED : String = "allLayersLoaded";
		
		public static const HIDE_CURSOR : String = "hideCursor";
		public static const SHOW_CURSOR : String = "showCursor";
		
		public static const SHOW_TOOLTIP : String = "showTooltip";
		public static const HIDE_TOOLTIP : String = "hideTooltip";
		
		public var extra:Object;
		
		public function BroadcastEvent( type:String, extra:Object=null )
		{
			if (extra)
				this.extra = extra;
			
			super(type);
		}
		
		override public function clone():Event
		{
			return new BroadcastEvent( type, extra );
		}
		
		override public function toString():String
		{
			return formatToString("BroadcastEvent", "type", "bubbles", "cancelable", "eventPhase", "extra");
		}
		

	}
}