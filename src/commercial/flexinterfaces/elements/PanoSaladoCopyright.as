package commercial.flexinterfaces.elements
{
	import flash.events.*;
	import mx.controls.*;
	import zephyr.BroadcastEvent;
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;
	import flash.utils.*;
	import mx.events.ListEvent;
	import mx.styles.StyleManager;
	
	public class PanoSaladoCopyright extends Text
	{
		protected var ModuleLoader:Class;
		protected var PanoSalado:Class;
		
		protected var moduleLoader:Object;
		protected var layerByName:Dictionary;
		
		protected var panoSalado:Object;
		
		protected var settings:XML;
		
		protected var spacesList:XMLList;
		
		protected var previewsList:XMLList;
		
		protected var globalCopyright:String = "";
		
		protected var localCopyright:String;
		
		internal var __len:int;
		
		public function PanoSaladoCopyright()
		{
			super();
			
			styleName = 'PanoSaladoCopyright';
			
			addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true);
		}
		
		protected function stageReady(e:Event):void
		{
			//BroadcastEvent = ApplicationDomain.currentDomain.getDefinition("zephyr.BroadcastEvent") as Class;
			
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
			
			init();
			
		}
		
		protected function init():void
		{ 
			var foreignXML:XML = moduleLoader.xmlByName["PanoSalado"] as XML;
			
			spacesList = foreignXML.spaces.space.( @id.search(/\.preview$/) == -1 );
			
			previewsList = foreignXML.spaces.space.( @id.search(/\.preview$/) > -1 );
			
			moduleLoader.addEventListener(BroadcastEvent.SPACE_LOADED, updateOnNewPano, false, 0, true);
			
			globalCopyright = (settings.Copyright.@copyright != undefined) ? settings.Copyright.@copyright : "";
			
			updateOnNewPano();
		}
		
		protected function updateOnNewPano(e:BroadcastEvent=null):void
		{ 
			var spaceLoaded:String = String(panoSalado.currentSpace);
			
			if (spaceLoaded.search(/\.preview$/) > -1)
				spaceLoaded = spaceLoaded.substring( 0 , spaceLoaded.search(/\.preview$/) );
			
			localCopyright = spacesList.(hasOwnProperty("@id") && @id == spaceLoaded).Copyright.@copyright;
			
			this.text = (localCopyright != "" && localCopyright != null) ? localCopyright : globalCopyright;
			
			if (this.text != "")
				this.text = "\u00A9" + this.text;
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