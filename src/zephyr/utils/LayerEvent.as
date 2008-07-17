package zephyr.utils
{
	import flash.events.Event;
	
	public class LayerEvent extends Event
	{
		public static const ALL_LAYERS_LOADED:String = "all_layers_loaded";
		
		public function LayerEvent( type:String )
		{
			super(type);
		}
		
		override public function clone():Event
		{
			return new LayerEvent(type);
		}
		
		override public function toString():String
		{
			return formatToString("LayerEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
		
	}
}