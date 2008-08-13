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

	public class FlexInterface extends Application
	{
		public var buttonsContainer : HBox;
		
		public var autorotationToggle : Button;

		public var leftButton : Button;
		public var rightButton : Button;
		public var upButton : Button;
		public var downButton : Button;

		public var zoomInButton : Button;
		public var zoomOutButton : Button;

		public var fullscreenToggle : Button;
		
		public var hitAreaCanvas:Canvas;
		
		public var layerByName:Dictionary;
		
		public var moduleLoader:Object;
		
		public var panoSalado:Object;
		
		public var settings:XML;
		
		public var PanoSalado:Class;
		
		public var ModuleLoader:Class;
		
		public var BroadcastEvent:Class;

		public function FlexInterface()
		{
			addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete, false, 0, true);
			addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true);
		}
		
		protected function onCreationComplete(event:FlexEvent):void
		{
			
		}

		protected function buttonMouseDown(event:MouseEvent):void
		{			
			event.stopImmediatePropagation();
			
			switch (event.target.name)
			{
				case( "autorotationToggle" ) :
				panoSalado.execute("toggleAutorotator");
				break;
				case( "leftButton" ) :
				panoSalado.execute("keyDown:left");
				break;
				case( "rightButton" ) :
				panoSalado.execute("keyDown:right");
				break;
				case( "upButton" ) :
				panoSalado.execute("keyDown:up");
				break;
				case( "downButton" ) :
				panoSalado.execute("keyDown:down");
				break;
				case( "zoomInButton" ) :
				panoSalado.execute("keyDown:shift");
				break;
				case( "zoomOutButton" ) :
				panoSalado.execute("keyDown:control");
				break;
				case( "fullscreenToggle" ) :
				panoSalado.execute("toggleFullscreen");
				break;
			}
			
			
		}
		
		protected function buttonMouseUp(event:MouseEvent):void
		{			
			event.stopImmediatePropagation();
			
			switch (event.target.name)
			{
				case( "leftButton" ) :
				panoSalado.execute("keyUp:left");
				break;
				case( "rightButton" ) :
				panoSalado.execute("keyUp:right");
				break;
				case( "upButton" ) :
				panoSalado.execute("keyUp:up");
				break;
				case( "downButton" ) :
				panoSalado.execute("keyUp:down");
				break;
				case( "zoomInButton" ) :
				panoSalado.execute("keyUp:shift");
				break;
				case( "zoomOutButton" ) :
				panoSalado.execute("keyUp:control");
				break;
			}
			
			
		}
		
		protected function stageReady(e:Event):void
		{ 
			removeEventListener(Event.ADDED_TO_STAGE, stageReady);
			
			stage.addEventListener(Event.RESIZE, resizeHandler, false, 0, true);
			
			BroadcastEvent = ApplicationDomain.currentDomain.getDefinition("zephyr.BroadcastEvent") as Class;
			
			ModuleLoader = ApplicationDomain.currentDomain.getDefinition("ModuleLoader") as Class;
			
			moduleLoader = ModuleLoader( parent.parent );

			moduleLoader.addEventListener(BroadcastEvent.ALL_LAYERS_LOADED, layersReady, false, 0, true);
			
			layersReady();
			
			autorotationToggle.addEventListener(MouseEvent.MOUSE_DOWN, buttonMouseDown, false, 0, true);
			leftButton.addEventListener(MouseEvent.MOUSE_DOWN, buttonMouseDown, false, 0, true);
			rightButton.addEventListener(MouseEvent.MOUSE_DOWN, buttonMouseDown, false, 0, true);
			upButton.addEventListener(MouseEvent.MOUSE_DOWN, buttonMouseDown, false, 0, true);
			downButton.addEventListener(MouseEvent.MOUSE_DOWN, buttonMouseDown, false, 0, true);
			zoomInButton.addEventListener(MouseEvent.MOUSE_DOWN, buttonMouseDown, false, 0, true);
			zoomOutButton.addEventListener(MouseEvent.MOUSE_DOWN, buttonMouseDown, false, 0, true);
			fullscreenToggle.addEventListener(MouseEvent.MOUSE_DOWN, buttonMouseDown, false, 0, true);
			
			autorotationToggle.addEventListener(MouseEvent.MOUSE_UP, buttonMouseUp, false, 0, true);
			leftButton.addEventListener(MouseEvent.MOUSE_UP, buttonMouseUp, false, 0, true);
			rightButton.addEventListener(MouseEvent.MOUSE_UP, buttonMouseUp, false, 0, true);
			upButton.addEventListener(MouseEvent.MOUSE_UP, buttonMouseUp, false, 0, true);
			downButton.addEventListener(MouseEvent.MOUSE_UP, buttonMouseUp, false, 0, true);
			zoomInButton.addEventListener(MouseEvent.MOUSE_UP, buttonMouseUp, false, 0, true);
			zoomOutButton.addEventListener(MouseEvent.MOUSE_UP, buttonMouseUp, false, 0, true);
			fullscreenToggle.addEventListener(MouseEvent.MOUSE_UP, buttonMouseUp, false, 0, true);
	
			autorotationToggle.buttonMode = true ;
			leftButton.buttonMode = true ;
			rightButton.buttonMode = true ;
			upButton.buttonMode = true ;
			downButton.buttonMode = true ;
			zoomInButton.buttonMode = true ;
			zoomOutButton.buttonMode = true ;
			fullscreenToggle.buttonMode = true ;
		}

		protected function layersReady(e:Event=null):void
		{ 
			
			layerByName = Dictionary( moduleLoader["layerByName"] );
			
			PanoSalado = ApplicationDomain.currentDomain.getDefinition("PanoSalado") as Class;

			panoSalado = PanoSalado( layerByName["PanoSalado"] );

			settings = moduleLoader["xmlByName"]["Interface"];

		}
		
		protected function resizeHandler(e:Event):void
		{
			this.percentWidth=100;
			this.percentHeight=100;
		}
	}
}