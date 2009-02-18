package commercial.flexinterfaces.elements
{
	import commercial.flexlib.controls.CanvasButton;
	import flash.events.*;
	//import zephyr.BroadcastEvent;
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;
	import flash.utils.*;
	import mx.styles.StyleManager;
	
	public class PanoSaladoEnhancedCanvasButton extends CanvasButton
	{
		protected var BroadcastEvent:Class;
		protected var ModuleLoader:Class;
		protected var PanoSalado:Class;
		
		protected var moduleLoader:Object;
		protected var layerByName:Dictionary;
		
		protected var panoSalado:Object;
		
		protected var settings:XML;
		
		public function PanoSaladoEnhancedCanvasButton()
		{
			super();
			
			setStyle( "skin", getDefinitionByName("commercial.flexlib.skins.EnhancedButtonSkin") as Class );
			
			buttonMode = true;
			
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
		
		private var _panoSaladoToolTip:String;
	
		[Bindable("panoSaladoToolTipChanged")]
		public function get panoSaladoToolTip():String
		{
			return _panoSaladoToolTip;
		}

		public function set panoSaladoToolTip(value:String):void
		{ 
			var oldValue:String = _panoSaladoToolTip;
			_panoSaladoToolTip = value;
			
			PanoSaladoToolTipManager.registerDisplayObjectToolTip(this, oldValue, value);
	
			dispatchEvent(new Event("panoSaladoToolTipChanged"));
		}
		
		//http://www.craftymind.com/2008/03/31/hacking-width-and-height-properties-into-flexs-css-model/
		override public function styleChanged(styleProp:String):void
		{
			super.styleChanged(styleProp);
			
			if(!styleProp || styleProp == "styleName"){ //if runtime css swap or direct change of stylename
				var dotSelector:Object = StyleManager.getStyleDeclaration("." + styleName);
				if(dotSelector != null){
					applyProperties(dotSelector, ["width", "height", "percentWidth", "percentHeight", "x", "y", "visible"]);
				}
				var classSelector:Object = StyleManager.getStyleDeclaration(className);
				if(classSelector != null){
					applyProperties(classSelector, ["width", "height", "percentWidth", "percentHeight", "x", "y", "visible"]);
				}
			}
		}
		private function applyProperties(styleObj:Object, arr:Array):void{
			for each (var item:String in arr){
				var prop:Object = styleObj.getStyle(item);
				if(prop != null) this[item] = prop;
			}
		}
	}
}