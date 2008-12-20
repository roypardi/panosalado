package zephyr
{
	import com.fontvirus.Canvas3D;
	
	import zephyr.BroadcastEvent;
    import mx.events.MetadataEvent;
    import mx.events.VideoEvent;
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;
	import flash.events.*;
	import flash.display.Sprite;
	import com.eyesee360.VideoDisplaySprite;
	
    [Event(name="playheadUpdate", type="mx.events.VideoEvent")]
    [Event(name="progress", type="flash.events.ProgressEvent")]
    [Event(name="ready", type="mx.events.VideoEvent")]


	public class PanoSaladoCanvas3D extends Canvas3D
	{	
		
		private var BroadcastEvent:Class;
		private var ModuleLoader:Class;
		private var PanoSalado:Class;
		
		private var moduleLoader:Object;
		private var layerByName:Dictionary;
		
		private var _panoSalado:Object = null;
		private var loadViewports:Boolean = false;
		
		[Bindable]
		public var currentVideo:VideoDisplaySprite;
		
		private var settings:XML;
		
		public function PanoSaladoCanvas3D()
		{
			super();
			init();
		}
		
		private function init():void
		{
			addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true);
		}
		
		[Bindable]
		public function get panoSalado():Object
		{
		    return _panoSalado;
	    }
	    
		public function set panoSalado(ps:Object):void
		{
		    _panoSalado = ps;
			_panoSalado.addEventListener("videoLoaded", videoReady);
			if (loadViewports) {
			    this.addChild( _panoSalado.viewports );
			} else {
			    this.addChild( Sprite(_panoSalado) );
		    }
			if (_panoSalado.currentVideo) {
			    this.videoReady();
			}
	    }
		
		private function stageReady(e:Event=null):void
		{             
    		if (ApplicationDomain.currentDomain.hasDefinition("ModuleLoader")) {
    			// Support for being loaded from a ModuleLoader
    			ModuleLoader = ApplicationDomain.currentDomain.getDefinition("ModuleLoader") as Class;
			    moduleLoader = ModuleLoader.moduleLoader;
			    if (moduleLoader) {
		            if (moduleLoader.allLayersLoaded) {
			            layersReady();
			        } else {
            			BroadcastEvent = ApplicationDomain.currentDomain.getDefinition("zephyr.BroadcastEvent") as Class;
            			if (BroadcastEvent) {
    			            moduleLoader.addEventListener(BroadcastEvent.ALL_LAYERS_LOADED, layersReady, false, 0, true);
    		            }
    		        }
	            }
	        }
		}
		
		protected function layersReady(e:Event=null):void
		{ 
			layerByName = Dictionary( moduleLoader.layerByName );
			settings = XML( moduleLoader["xmlByName"]["Interface"] );
			
			loadViewports = true;
			PanoSalado = ApplicationDomain.currentDomain.getDefinition("PanoSalado") as Class;
			panoSalado = PanoSalado( layerByName["PanoSalado"] );
		}
		
		protected function videoReady(e:Event=null):void
		{
		    this.currentVideo = panoSalado.currentVideo;
			currentVideo.addEventListener(VideoEvent.PLAYHEAD_UPDATE, relayEvent);
			currentVideo.addEventListener(ProgressEvent.PROGRESS, relayEvent);
			dispatchEvent(new VideoEvent(VideoEvent.READY));
	    }
		
		protected function relayEvent(e:Event):void
		{
		    // Re-sends an event as our own.
		    dispatchEvent(e.clone());
	    }
	}
}