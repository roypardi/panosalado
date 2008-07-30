package zephyr
{
	import flash.events.MouseEvent;

	import mx.controls.*;
	import mx.containers.*;
	import mx.core.Application;
	import mx.events.FlexEvent;
	import flash.events.*;
	import flash.display.Sprite;
	
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;

	public class Main extends Application
	{
		public var exampleButton:Button;
		
		public var hitAreaCanvas:Canvas;
		
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
			trace("example button clicked!", event.target);
			
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
			
			//hitAreaCanvas.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true)
			
			settings = moduleLoader["xmlByName"]["Interface"];
			
			exampleButton.addEventListener(MouseEvent.CLICK, onExampleButtonClick);
			//exampleButton.x = stage.stageWidth-300;
			//exampleButton.y = stage.stageHeight-100;
			
			
		}
		
		protected function mouseDownHandler(e:MouseEvent):void
		{
			trace("canvas clicked!", e.target);
			panoSalado.mouseDownEvent( e );
		}
	}
}