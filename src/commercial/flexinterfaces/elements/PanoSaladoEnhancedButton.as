package commercial.flexinterfaces.elements
{
	import commercial.flexinterfaces.elements.EnhancedButton;
	import flash.events.*;
	//import zephyr.BroadcastEvent;
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;
	import flash.utils.*;
	
	public class PanoSaladoEnhancedButton extends EnhancedButton
	{
		protected var BroadcastEvent:Class;
		protected var ModuleLoader:Class;
		protected var PanoSalado:Class;
		
		protected var moduleLoader:Object;
		protected var layerByName:Dictionary;
		
		protected var panoSalado:Object;
		
		protected var settings:XML;
		
		public function PanoSaladoEnhancedButton()
		{
			super();
			
			init();
		}
		
		protected function panoSaladoExecute(str:String):void
		{
			panoSalado.execute( str );
		}
		
		private function init():void
		{
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