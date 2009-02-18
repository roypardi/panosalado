package commercial.flexinterfaces.elements
{
	import flash.events.Event;

	public class CSSWeightBoxLayoutEvent extends Event
	{
		public static var EXCEEDS_WIDTH:String = "exceedsWidth";
		
		public static var FITS_IN_WIDTH:String = "fitsInWidth";
		
		public static var EXCEEDS_HEIGHT:String = "exceedsHeight";
		
		public static var FITS_IN_HEIGHT:String = "fitsInHeight";
		
		public function CSSWeightBoxLayoutEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}