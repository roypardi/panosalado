package commercial.flexinterfaces.elements
{
	import mx.containers.Box;
	import commercial.flexinterfaces.elements.BetterBox;
	import flash.events.*;
	import zephyr.BroadcastEvent;
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;
	import flash.utils.*;
	
	
	public class PanoSaladoControlBar extends CSSWeightBox
	{
		protected var BroadcastEvent:Class;
		protected var ModuleLoader:Class;
		protected var PanoSalado:Class;
		
		protected var moduleLoader:Object;
		protected var layerByName:Dictionary;
		
		protected var panoSalado:Object;
		
		protected var settings:XML;
		
		public function PanoSaladoControlBar()
		{
			super();
			
			styleName="PanoSaladoControlBar";
			
			addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true);
		}
		
		protected function stageReady(e:Event):void
		{ 
			BroadcastEvent = ApplicationDomain.currentDomain.getDefinition("zephyr.BroadcastEvent") as Class;
			
			ModuleLoader = ApplicationDomain.currentDomain.getDefinition("ModuleLoader") as Class;
			
			moduleLoader = ModuleLoader( parentApplication.moduleLoader );
			
			moduleLoader.addEventListener(BroadcastEvent.ALL_LAYERS_LOADED, layersReady, false, 0, true);
			
			settings = moduleLoader.xmlByName["Interface"] as XML;
			
			layersReady();
		}
		
		protected function layersReady(e:Event=null):void
		{ 
			
			layerByName = Dictionary( moduleLoader.layerByName );
			
			PanoSalado = ApplicationDomain.currentDomain.getDefinition("PanoSalado") as Class;
			
			panoSalado = PanoSalado( layerByName["PanoSalado"] );
			
		}
	}
}