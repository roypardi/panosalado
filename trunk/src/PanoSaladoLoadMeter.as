package
{
	
	import flash.display.Sprite;
	import com.leebrimelow.drawing.*;
	import flash.events.*;
	import flash.system.ApplicationDomain;
	import zephyr.BroadcastEvent;
	
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	import flash.filters.DropShadowFilter;
	
	public class PanoSaladoLoadMeter extends Sprite
	{
		
		private var ModuleLoader:Class;
		
		//private var BroadcastEvent:Class;
		
		private var moduleLoader:Object;
		
		private var meter:Sprite = new Sprite();
		
		private var percentages:Object = new Object();
		
		public function PanoSaladoLoadMeter()
		{
			addChild( meter );
			
			meter.filters = [new DropShadowFilter(10, 45, 0x000000, 0.5)];
			
			addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true );
		}
		
		private function stageReady(e:Event):void
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			ModuleLoader = ApplicationDomain.currentDomain.getDefinition("ModuleLoader") as Class;
			
			//BroadcastEvent = ApplicationDomain.currentDomain.getDefinition("zephyr.BroadcastEvent") as Class;
			
			moduleLoader = ModuleLoader( parent );
			
			moduleLoader.addEventListener(BroadcastEvent.LOAD_PROGRESS, onProgress, false, 0, true);
		}
		
		private function onProgress(e:BroadcastEvent):void
		{
			
			percentages[e.info.id] = e.info.percentLoaded;
			
			var bytesTotal:Number = 0;
			
			var overItems:int = 0;
			
			for (var id:String in percentages)
			{
				bytesTotal += Number( percentages[id] );
				
				overItems++;
			}
			
			var displayPercentage:Number = bytesTotal/overItems;
			
			var radius:Number = 25;
			
			meter.graphics.clear();
			
			//meter.graphics.beginFill(0xFF0000);
			
			meter.graphics.lineStyle(5, 0xFFFFFF);
			
			WedgePerimeter.draw(meter, stage.stageWidth*0.5, stage.stageHeight*0.5, radius, displayPercentage*360, 0 );
			
			meter.graphics.lineStyle(3, 0x000000);
			
			WedgePerimeter.draw(meter, stage.stageWidth*0.5, stage.stageHeight*0.5, radius, displayPercentage*360, 0 );
			
			//meter.graphics.endFill();
			
			if (displayPercentage > 0.999)
				percentages = new Object();
			
			if (displayPercentage > 0.999 || displayPercentage < 0.001)
				meter.visible = false;
			else
				meter.visible = true;
			
		}
	}
}