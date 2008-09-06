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
		
		public static const LOAD_PROGRESS : String = "loadProgress";
		
		public var info:Object;
		
		public function BroadcastEvent( type:String, info:Object=null )
		{
			if (info)
				this.info = info;
			
			super(type);
		}
		
		override public function clone():Event
		{
			return new BroadcastEvent( type, info );
		}
		
		override public function toString():String
		{
			return formatToString("BroadcastEvent", "type", "bubbles", "cancelable", "eventPhase", "info");
		}
		

	}
}