package com.panosalado.event
{
	import flash.events.Event;

	public class ImageSourceEvent extends Event
	{
		public static const IMAGE_UPDATE:String = "imageUpdate";
		public static const PROJECTION_UPDATE:String = "projectionUpdate";

		public function ImageSourceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}