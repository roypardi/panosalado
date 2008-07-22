package
{
		
	import zephyr.utils.LayerEvent;
	import flash.ui.Mouse;
	import flash.events.*;
	import flash.display.*;
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;
	import zephyr.BroadcastEvent;
	
	public class Cursor extends Sprite
	{
		[Embed(source="pointers/c_c.png")]
		public var Cursor_MouseDown:Class;
		[Embed(source="pointers/c_t.png")]
			public var Cursor_MouseUp:Class;
			
		[Embed(source="pointers/n_o.png")]
			public var Cursor_UR:Class;
			
		[Embed(source="pointers/n.png")]
			public var Cursor_U:Class;
			
		[Embed(source="pointers/n_w.png")]
			public var Cursor_UL:Class;
			
		[Embed(source="pointers/o.png")]
			public var Cursor_R:Class;
			
		[Embed(source="pointers/s_o.png")]
			public var Cursor_DR:Class;
			
		[Embed(source="pointers/s.png")]
			public var Cursor_D:Class;
			
		[Embed(source="pointers/s_w.png")]
			public var Cursor_DL:Class;	
			
		[Embed(source="pointers/w.png")]
			public var Cursor_L:Class;	
		
		private var PanoSalado:Class;
		private var ModuleLoader:Class;
		private var ViewportBaseLayer:Class;
		
		private var layerByName:Dictionary;
		private var panoSalado:Object;
		private var moduleLoader:Object;
		private var buttons:Object;
		
		private var cursor:Bitmap;
		
		public function Cursor(settingsXML:XML=null)
		{
			addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true);
			
			cursor = new Bitmap( new Cursor_MouseUp().bitmapData );
			cursor.visible=false;
			addChild(cursor);
		}
		
		private function stageReady(e:Event):void
		{
			parent.addEventListener(LayerEvent.ALL_LAYERS_LOADED, layersReady, false, 0, true);
		}
		
		private function layersReady(e:Event):void
		{
			PanoSalado = ApplicationDomain.currentDomain.getDefinition("PanoSalado") as Class;
			ModuleLoader = ApplicationDomain.currentDomain.getDefinition("ModuleLoader") as Class;
			ViewportBaseLayer = ApplicationDomain.currentDomain.getDefinition("org.papervision3d.view.layer.ViewportBaseLayer") as Class;
			
			parent.removeEventListener(LayerEvent.ALL_LAYERS_LOADED, layersReady);
			
			layerByName = Dictionary( parent["layerByName"] );
			panoSalado = PanoSalado( layerByName["PanoSalado"] );
			buttons = layerByName["Interface"];
			moduleLoader = ModuleLoader( parent );
			
			stage.addEventListener(MouseEvent.MOUSE_OVER, checkOver, true, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_OUT, checkOut, true, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true);
			
			moduleLoader.addEventListener(BroadcastEvent.SHOW_CURSOR, show, false, 0, true);
			moduleLoader.addEventListener(BroadcastEvent.HIDE_CURSOR, hide, false, 0, true);
			
		}
		
		private var mouseIsDown:Boolean = false;
		private var lastMouseX:Number = mouseX;
		private var lastMouseY:Number = mouseY;
		private var rToD:Number = 180/Math.PI;
		
		private function checkOver(e:Event):void
		{
			if (e.target is ViewportBaseLayer)
				show();
		}
		private function checkOut(e:Event):void
		{
			if (e.target is ViewportBaseLayer)
				hide();
		}
		
		private function show(e:Event=null):void
		{
			Mouse.hide();
			cursor.visible = true;
		}
		
		private function hide(e:Event=null):void
		{
			Mouse.show();
			cursor.visible = false;
		}
		
		private function mouseMoveHandler(e:MouseEvent):void
		{
			cursor.x = mouseX - cursor.width * 0.5;
			cursor.y = mouseY - cursor.height * 0.5;
			
			 
			if (mouseIsDown)
			{
				var dx:Number = mouseX - lastMouseX;
				var dy:Number = mouseY - lastMouseY;
				
				var angle:Number = Math.atan2(dy, dx) * rToD;
				
				if (angle < 22.5 && angle > -22.5)		{ cursor.bitmapData = new Cursor_R().bitmapData; }
				else if (angle < -22.5 && angle > -67.5)	{ cursor.bitmapData = new Cursor_UR().bitmapData; }
				else if (angle < -67.5 && angle > -112.5)	{ cursor.bitmapData = new Cursor_U().bitmapData; }
				else if (angle < -112.5 && angle > -157.5){ cursor.bitmapData = new Cursor_UL().bitmapData; }
				else if (angle < -157.5 || angle > 157.5){ cursor.bitmapData = new Cursor_L().bitmapData; }
				else if (angle < 157.5 && angle > 112.5){ cursor.bitmapData = new Cursor_DL().bitmapData; }
				else if (angle < 112.5 && angle > 67.5){ cursor.bitmapData = new Cursor_D().bitmapData; }
				else if (angle < 67.5 && angle > 22.5){ cursor.bitmapData = new Cursor_DR().bitmapData; }
			}
			
		}
		
		private function mouseDownHandler(e:MouseEvent):void 
		{ 
			cursor.bitmapData = new Cursor_MouseDown().bitmapData; 
			mouseIsDown = true;
			lastMouseX = mouseX;
			lastMouseY = mouseY;
		}
		private function mouseUpHandler(e:MouseEvent):void 
		{ 
			cursor.bitmapData = new Cursor_MouseUp().bitmapData; 
			mouseIsDown = false;
		}
		
// 		public function show(e:Event=null):void
// 		{
// 			Mouse.hide();
// 			addChild(cursor);
// 			cursor.visible = true;
// 		}
// 		
// 		public function hide(e:Event=null):void
// 		{
// 			Mouse.show();
// 			removeChild(cursor);
// 			cursor.visible = false;
// 		}
		
	}
}
