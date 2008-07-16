package zephyr.objects
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class StageAlignedSprite extends Sprite
	{
		
		private var _alignment:String = "tl";
		
		private var _offsetX:Number = 0;
		
		private var _offsetY:Number = 0;
		
		public function StageAlignedSprite()
		{
			super();
			
			this.addEventListener(Event.ADDED_TO_STAGE, setUpListener, false, 0, true);
			this.addEventListener(Event.ADDED_TO_STAGE, align, false, 0, true);
			this.addEventListener(Event.REMOVED_FROM_STAGE, removeListener, false, 0, true);
		}
		
		private function setUpListener(e:Event):void
		{
			this.stage.addEventListener(Event.RESIZE, align, false, 0, true);
		}
		
		private function removeListener(e:Event):void
		{
			this.stage.removeEventListener(Event.RESIZE, align);
		}
		
		public function align(e:Event=null):void
		{
			var startingPoints:Object = resolveAlignment( _alignment );
			x = startingPoints["startX"] + offsetX;
			y = startingPoints["startY"] + offsetY;
		}
		
		private function resolveAlignment(align:String):Object
		{
			var sx:Number = 0;
			var sy:Number = 0;
			if (stage != null)
			{
				if      ( align == "c" )  { sx = int(stage.stageWidth/2); sy = int(stage.stageHeight/2); }
				else if ( align == "tl" ) { sx = 0; sy = 0; }
				else if ( align == "tc" ) { sx = int(stage.stageWidth/2); sy = 0; }
				else if ( align == "tr" ) { sx = int(stage.stageWidth); sy = 0; }
				else if ( align == "lc" ) { sx = 0; sy = int(stage.stageHeight/2); }
				else if ( align == "rc" ) { sx = int(stage.stageWidth); sy = int(stage.stageHeight/2); }
				else if ( align == "bl" ) { sx = 0; sy = int(stage.stageHeight); }
				else if ( align == "bc" ) { sx = int(stage.stageWidth/2); sy = int(stage.stageHeight); }
				else if ( align == "br" ) { sx = int(stage.stageWidth); sy = int(stage.stageHeight); }
				else { sx = 0; sy = 0; }
			}
			
			return {startX:sx, startY:sy}
		}
		
		public function get alignment():String
		{
			return _alignment;
		}
		
		public function set alignment(str:String):void
		{
			_alignment = str.toLowerCase();
			align();
		}
		
		public function get offsetX():Number
		{
			return _offsetX;
		}
		
		public function set offsetX(offset:Number):void
		{
			_offsetX = offset;
			align();
		}
		
		public function get offsetY():Number
		{
			return _offsetY;
		}
		
		public function set offsetY(offset:Number):void
		{
			_offsetY = offset;
			align();
		}
	}
}