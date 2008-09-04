package zephyr
{
	import com.fontvirus.Canvas3D;
	
	import zephyr.BroadcastEvent;
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;
	import flash.events.*;
	
	public class PanoSaladoCanvas3D extends Canvas3D
	{	
		
		private var BroadcastEvent:Class;
		private var ModuleLoader:Class;
		private var PanoSalado:Class;
		
		private var moduleLoader:Object;
		private var layerByName:Dictionary;
		private var panoSalado:Object;
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
		
		private function stageReady(e:Event=null):void
		{ 
			BroadcastEvent = ApplicationDomain.currentDomain.getDefinition("zephyr.BroadcastEvent") as Class;
			
			ModuleLoader = ApplicationDomain.currentDomain.getDefinition("ModuleLoader") as Class;
			
			moduleLoader = ModuleLoader( parent.parent.parent );
			
			moduleLoader.addEventListener(BroadcastEvent.ALL_LAYERS_LOADED, layersReady, false, 0, true);
			
			layersReady();
		}
		
		protected function layersReady(e:Event=null):void
		{ 
			
			layerByName = Dictionary( moduleLoader.layerByName );
			
			PanoSalado = ApplicationDomain.currentDomain.getDefinition("PanoSalado") as Class;
			
			panoSalado = PanoSalado( layerByName["PanoSalado"] );
			
			settings = XML( moduleLoader["xmlByName"]["Interface"] );
			
			this.addChild( panoSalado.viewports );
			
		}
		
	}
}