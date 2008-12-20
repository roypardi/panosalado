package
{
import flash.display.*;
import flash.events.*;
import flash.utils.Dictionary;
import flash.system.ApplicationDomain;
import zephyr.BroadcastEvent;
import flash.text.*
//import fl.managers.StyleManager;

	public class UserInterface extends MovieClip
	{
	private var moduleLoader:Object;
	private var layerByName:Dictionary;
	private var panoSalado:Object;
	private var theNavigation:Object;
	
	private var PanoSalado:Class;
	private var ModuleLoader:Class;
	private var BulkLoader:Class;
	private var BulkProgressEvent:Class;
	private var TweenLite:Class;
	private var DisplayObject3D:Class;
	private var InteractiveScene3DEvent:Class;
	private var Viewport3D:Class;
	private var BroadcastEvent:Class;
	
	private var TweenLiteTo:Function;
		
	//init our buttons, background and text
	private var container:MovieClip = new MovieClip();
	private var buttons_bg:Bg;
	private var buttons_container:Container;
	private var loadingText:TextField = new TextField();
	private var loadingTextFormat:TextFormat = new TextFormat();
	
	private var settings:XML;
	
		public function UserInterface()
		{
			buttons_container = new Container();
			buttons_bg = new Bg()
			
			// set up textfield format
			loadingTextFormat.font= "Verdana";
			loadingTextFormat.color = 0xFFFFFF;
			loadingTextFormat.size = 14;
			loadingTextFormat.underline = false;
			loadingTextFormat.align = "left";
			loadingTextFormat.bold = true;
			loadingTextFormat.italic = false;
			loadingTextFormat.kerning = true;
			loadingTextFormat.letterSpacing = 2;
			
			loadingText.defaultTextFormat = loadingTextFormat;
			loadingText.autoSize = TextFieldAutoSize.LEFT;
			
			// hide our interface elements until we're ready for them
			buttons_container.alpha = 0;
			buttons_container.visible = false;
			buttons_bg.alpha = 0;
			buttons_bg.visible = false;
			loadingText.visible = false;
			
			//
			addChild(container);
			container.addChild(buttons_bg);
			container.addChild(buttons_container);
			container.addChild(loadingText);
			
			// stageReady let's us know that this .swf has been added to stage, 
			// so we can do things at an appropriate time
			this.addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true);
			
			buttons_container.autorotate.addEventListener(MouseEvent.MOUSE_DOWN, autorotatePress, false, 0, true);
			buttons_container.autorotate.useHandCursor = true;

			buttons_container.zoomin.addEventListener(MouseEvent.MOUSE_DOWN, zoominPress, false, 0, true);
			buttons_container.zoomin.addEventListener(MouseEvent.MOUSE_UP, zoominRelease, false, 0, true);
			buttons_container.zoomin.addEventListener(MouseEvent.MOUSE_OUT, zoominRelease, false, 0, true);
			buttons_container.zoomin.useHandCursor = true;
			
			buttons_container.zoomout.addEventListener(MouseEvent.MOUSE_DOWN, zoomoutPress, false, 0, true);
			buttons_container.zoomout.addEventListener(MouseEvent.MOUSE_UP, zoomoutRelease, false, 0, true);
			buttons_container.zoomout.addEventListener(MouseEvent.MOUSE_OUT, zoomoutRelease, false, 0, true);
			buttons_container.zoomout.useHandCursor = true;
			
			buttons_container.tiltup.addEventListener(MouseEvent.MOUSE_DOWN, upPress, false, 0, true);
			buttons_container.tiltup.addEventListener(MouseEvent.MOUSE_UP, upRelease, false, 0, true);
			buttons_container.tiltup.addEventListener(MouseEvent.MOUSE_OUT, upRelease, false, 0, true);
			buttons_container.tiltup.useHandCursor = true;
			
			buttons_container.tiltdown.addEventListener(MouseEvent.MOUSE_DOWN, downPress, false, 0, true);
			buttons_container.tiltdown.addEventListener(MouseEvent.MOUSE_UP, downRelease, false, 0, true);
			buttons_container.tiltdown.addEventListener(MouseEvent.MOUSE_OUT, downRelease, false, 0, true);
			buttons_container.tiltdown.useHandCursor = true;
			
			buttons_container.panleft.addEventListener(MouseEvent.MOUSE_DOWN, leftPress, false, 0, true);
			buttons_container.panleft.addEventListener(MouseEvent.MOUSE_UP, leftRelease, false, 0, true);
			buttons_container.panleft.addEventListener(MouseEvent.MOUSE_OUT, leftRelease, false, 0, true);
			buttons_container.panleft.useHandCursor = true;
			
			buttons_container.panright.addEventListener(MouseEvent.MOUSE_DOWN, rightPress, false, 0, true);
			buttons_container.panright.addEventListener(MouseEvent.MOUSE_UP, rightRelease, false, 0, true);
			buttons_container.panright.addEventListener(MouseEvent.MOUSE_OUT, rightRelease, false, 0, true);
			buttons_container.panright.useHandCursor = true;
			
			buttons_container.gofullscreen.addEventListener(MouseEvent.MOUSE_DOWN, fullscreenPress, false, 0, true);
			buttons_container.gofullscreen.useHandCursor = true;
		}
		
		private function stageReady(e:Event):void 
		{
			BroadcastEvent = ApplicationDomain.currentDomain.getDefinition("zephyr.BroadcastEvent") as Class;
			
			parent.addEventListener(BroadcastEvent.ALL_LAYERS_LOADED, layersReady, false, 0, true);
			
			settings = parent["xmlByName"]["Interface"];
		}
		
		private function layersReady(e:Event):void 
		{
			PanoSalado = ApplicationDomain.currentDomain.getDefinition("PanoSalado") as Class;
			ModuleLoader = ApplicationDomain.currentDomain.getDefinition("ModuleLoader") as Class;
			BulkLoader = ApplicationDomain.currentDomain.getDefinition("br.com.stimuli.loading.BulkLoader") as Class;
			BulkProgressEvent = ApplicationDomain.currentDomain.getDefinition("br.com.stimuli.loading.BulkProgressEvent") as Class;
			DisplayObject3D = ApplicationDomain.currentDomain.getDefinition("org.papervision3d.objects.DisplayObject3D") as Class;
			TweenLite = ApplicationDomain.currentDomain.getDefinition("gs.TweenLite") as Class;
			InteractiveScene3DEvent = ApplicationDomain.currentDomain.getDefinition("org.papervision3d.events.InteractiveScene3DEvent") as Class;
			Viewport3D = ApplicationDomain.currentDomain.getDefinition("org.papervision3d.view.Viewport3D") as Class;
			
			
			TweenLiteTo = TweenLite["to"];
			
			stage.addEventListener(Event.RESIZE, resizeHandler, false, 0, true);
		
			resizeHandler();
		
			// now that we're on the stage
			// and have received the All OK from our container,
			// let's set our targets for:
			// the container...
			moduleLoader = ModuleLoader.moduleLoader;
		
			layerByName = Dictionary( parent["layerByName"] );
			// the panorama...
			panoSalado = PanoSalado( layerByName["PanoSalado"] );
			// and ourself...
			theNavigation = layerByName["Interface"];
		
			// hook into the BulkLoader load events, so we can give some feedback to the user
			BulkLoader(panoSalado.bulkLoader).addEventListener(BulkLoader.PROGRESS, progressHandler, false, 0, true);
			BulkLoader(panoSalado.bulkLoader).addEventListener(BulkLoader.COMPLETE, completeHandler, false, 0, true);
		
			// clean up after ourselves
			parent.removeEventListener(BroadcastEvent.ALL_LAYERS_LOADED, layersReady);
		}
		
		// let's give some "load progress" feedback:
		private function progressHandler(e : *):void {
			e = e as BulkProgressEvent;
		
			var theWeightLoaded =  int(e.weightPercent*100+0.5);
			// set our text to show progress; this could be a ProgressBar or whatever you want:
		
			if ( e.itemsTotal > 1 ) {
				loadingText.text = "LOADING: "+theWeightLoaded+"% (cube face "+e.itemsLoaded+" of "+[e.itemsTotal-1]+")";
			} else {
				loadingText.text = "Loading Preview ";
			}
		
			if ( theWeightLoaded >= 99 && e.itemsTotal > 1) {
				// set the stage with our buttons and such:
				resizeHandler();
				// hide this text:
				loadingText.visible = false;
			}
		}
		
		private function resetLoadingText(e:Event=null):void {
			var obj = e.target;
		
			loadingText.text = "";
			loadingText.visible = true;
			obj.removeEventListener(InteractiveScene3DEvent.OBJECT_CLICK, resetLoadingText);
		}
		
		private function completeHandler(e : Event):void {
			resizeHandler();
		
// 			/* ZEPHYR:
// 			
// 			Now that we've stripped down Interface to the bare essentials... 
// 			Does it make sense to allow the <hotspot/> elements in PanoSalado.xml have
// 			attributes such as "useHandCursor", "buttonMode", and so on?
// 			
// 			This would let the functions here in the completeHandler be collapsed
// 			into one loop, which could iterate through the <hotspot/> elements, and
// 			add or not add the EventListeners as dictated...
// 			
// 			?
// 			
// 			On that note, correct me where I'm wrong...
// 			Each time we load a new pano (loadSpace:blah), are the event listeners being garbage collected,
// 			and then reintroduced a la this completeHandler? That seems to be the case... Is this
// 			heavy-handed? Necessary evil? My wrong thinking?
// 			
// 			*/
// 			var spot:Object = DisplayObject3D( panoSalado.getDisplayObject3dByName("toConcert2") );
// 			var spot2:Object = DisplayObject3D( panoSalado.getDisplayObject3dByName("toConcert1") );
// 			if (spot) {
// 				spot.addEventListener(InteractiveScene3DEvent.OBJECT_OVER, mouseOver3dSpot, false, 0, true);
// 				spot.addEventListener(InteractiveScene3DEvent.OBJECT_OUT, mouseOut3dSpot, false, 0, true);
// 		
// 				spot.addEventListener(InteractiveScene3DEvent.OBJECT_CLICK, resetLoadingText, false, 0, true);
// 			}
// 			if (spot2) {
// 				spot2.addEventListener(InteractiveScene3DEvent.OBJECT_OVER, mouseOver3dSpot, false, 0, true);
// 				spot2.addEventListener(InteractiveScene3DEvent.OBJECT_OUT, mouseOut3dSpot, false, 0, true);
// 				//
// 				spot2.addEventListener(InteractiveScene3DEvent.OBJECT_CLICK, resetLoadingText, false, 0, true);
// 			}
		}
		
		// resizeHandler fires off when the stage is resized. This lets us, for instance, position buttons on-the-fly.
		// we also call it from above at various points while loading.
		private function resizeHandler(e:Event=null):void {
			buttons_container.x = stage.stageWidth - buttons_container.width;
			buttons_container.y = stage.stageHeight - (buttons_container.height+28);
			buttons_bg.x = 0;
			buttons_bg.y = stage.stageHeight - (buttons_bg.height+20);
			buttons_bg.width = stage.stageWidth+5;
			loadingText.x = 10;
			loadingText.y = (buttons_bg.y+14);
		
			if (!buttons_bg.visible) {
				buttons_bg.visible = true;
				TweenLiteTo(buttons_bg, 0.25, { alpha:1 } );
				loadingText.visible = true;
			} else {
				buttons_container.visible = true;
				TweenLiteTo(buttons_container, 1.0, { alpha:1 } );
			}
		}
		
		private function mouseOver3dSpot(e:*):void {
			e = e as InteractiveScene3DEvent;
			//cursor.hide();
			moduleLoader.dispatchEvent( new BroadcastEvent(BroadcastEvent.HIDE_CURSOR) );
			Viewport3D(panoSalado.getSpaceByName(panoSalado.currentSpace).viewport).buttonMode = true;
			Viewport3D(panoSalado.getSpaceByName(panoSalado.currentSpace).viewport).useHandCursor = true;
		}
		
		private function mouseOut3dSpot(e:*):void {
			e = e as InteractiveScene3DEvent;
			//cursor.show();
			moduleLoader.dispatchEvent( new BroadcastEvent(BroadcastEvent.SHOW_CURSOR) );
			Viewport3D(panoSalado.getSpaceByName(panoSalado.currentSpace).viewport).buttonMode = false;
			Viewport3D(panoSalado.getSpaceByName(panoSalado.currentSpace).viewport).useHandCursor = false;
		}
		
		
		
		private function autorotatePress(e:MouseEvent):void {
			panoSalado.execute("toggleAutorotator");
		}
		private function zoominPress(e:MouseEvent):void {
			panoSalado.execute("keyDown:shift");
		}
		private function zoominRelease(e:MouseEvent):void {
			panoSalado.execute("keyUp:shift");
		}
		
		private function zoomoutPress(e:MouseEvent):void {
			panoSalado.execute("keyDown:control");
		}
		private function zoomoutRelease(e:MouseEvent):void {
			panoSalado.execute("keyUp:control");
		}
		
		private function upPress(e:MouseEvent):void {
			panoSalado.execute("keyDown:up");
		}
		private function upRelease(e:MouseEvent):void {
			panoSalado.execute("keyUp:up");
		}
		
		private function downPress(e:MouseEvent):void {
			panoSalado.execute("keyDown:down");
		}
		private function downRelease(e:MouseEvent):void {
			panoSalado.execute("keyUp:down");
		}
		
		private function leftPress(e:MouseEvent):void {
			panoSalado.execute("keyDown:left");
		}
		private function leftRelease(e:MouseEvent):void {
			panoSalado.execute("keyUp:left");
		}
		
		private function rightPress(e:MouseEvent):void {
			panoSalado.execute("keyDown:right");
		}
		private function rightRelease(e:MouseEvent):void {
			panoSalado.execute("keyUp:right");
		}
		
		private function fullscreenPress(e:MouseEvent):void {
			panoSalado.execute("toggleFullscreen");
		}
	}
}