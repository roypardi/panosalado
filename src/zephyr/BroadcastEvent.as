package zephyr
{
	import flash.events.Event;
	
	public class BroadcastEvent extends Event
	{
		public static const ALL_LAYERS_LOADED : String = "allLayersLoaded";
		
		public static const STYLE_SHEET_LOADED : String = "styleSheetLoaded";
		public static const OVERRIDE_STYLE_SHEET_LOADED : String = "overrideStyleSheetLoaded";
		public static const STYLING_COMPLETE : String = "stylingComplete";
		
		public static const HIDE_CURSOR : String = "hideCursor";
		public static const SHOW_CURSOR : String = "showCursor";
		
		public static const SHOW_TOOLTIP : String = "showTooltip";
		public static const HIDE_TOOLTIP : String = "hideTooltip";
		
		public static const LOAD_PROGRESS : String = "loadProgress";
		
		public static const LOADING_SPACE : String = "loadingSpace";
		
		public static const SPACE_LOADED : String = "spaceLoaded";
		
		public static const AUTOROTATION_ON : String = "autorotationOn";
		public static const AUTOROTATION_OFF : String = "autorotationOff";
		
		public static const ENTER_FULLSCREEN : String = "enterFullscreen";
		public static const EXIT_FULLSCREEN : String = "exitFullscreen";
		
		public static const PLAY_VIDEO : String = "playVideo";
		public static const STOP_VIDEO : String = "stopVideo";
		public static const VIDEO_PLAYING : String = "videoPlaying";
		public static const VIDEO_STOPPED : String = "videoStopped";
		public static const ENABLE_VIDEO_TOGGLE_BUTTON : String = "enableVideoToggleButton";
		public static const DISABLE_VIDEO_TOGGLE_BUTTON : String = "disableVideoToggleButton";
		
		public static const PLAY_AUDIO : String = "playAudio";
		public static const STOP_AUDIO : String = "stopAudio";
		public static const AUDIO_PLAYING : String = "audioPlaying";
		public static const AUDIO_STOPPED : String = "audioStopped";
		
		public static const SHOW_FLOORPLAN : String = "showFloorplan";
		public static const HIDE_FLOORPLAN : String = "hideFloorplan";
		public static const FLOORPLAN_SHOWING : String = "floorplanShowing";
		public static const FLOORPLAN_HIDDEN : String = "floorplanHidden";
		
		public static const SHOW_THUMBNAIL_LIST : String = "showThumbnailList";
		public static const HIDE_THUMBNAIL_LIST : String = "hideThumbnailList";
		public static const THUMBNAIL_LIST_SHOWING : String = "thumbnailListShowing";
		public static const THUMBNAIL_LIST_HIDDEN : String = "thumbnailListHidden";
		
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