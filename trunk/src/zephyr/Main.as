package zephyr
{
	import flash.events.MouseEvent;

	import mx.controls.Button;
	import mx.containers.HBox;
	import mx.core.Application;
	import mx.events.FlexEvent;
	import flash.events.*;
	
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;

	public class Main extends Application
	{
		public var exampleButton:Button;
		
		public var layerByName:Dictionary;
		
		public var moduleLoader:Object;
		
		public var panoSalado:Object;
		
		public var settings:XML;
		
		public var PanoSalado:Class;
		
		public var ModuleLoader:Class;
		
		public var BroadcastEvent:Class;

		public function Main()
		{
			init();
		}
		
		protected function init():void
		{
			addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
		}
		
		protected function onCreationComplete(event:FlexEvent):void
		{
			addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true);
			
		}

		protected function onExampleButtonClick(event:MouseEvent):void
		{
			trace("example button clicked!");
			
			panoSalado.execute("toggleAutorotator");
		}


		
		protected function stageReady(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, stageReady);
			
			BroadcastEvent = ApplicationDomain.currentDomain.getDefinition("zephyr.BroadcastEvent") as Class;
			
			ModuleLoader = ApplicationDomain.currentDomain.getDefinition("ModuleLoader") as Class;
			
			moduleLoader = ModuleLoader( parent.parent );
			
			PanoSalado = ApplicationDomain.currentDomain.getDefinition("PanoSalado") as Class;
			
			layerByName = Dictionary( moduleLoader["layerByName"] );
			
			panoSalado = PanoSalado( layerByName["PanoSalado"] );
			
			settings = moduleLoader["xmlByName"]["Interface"];
			
			exampleButton.addEventListener(MouseEvent.CLICK, onExampleButtonClick);
			//exampleButton.x = stage.stageWidth-300;
			//exampleButton.y = stage.stageHeight-100;
		}
	}
}