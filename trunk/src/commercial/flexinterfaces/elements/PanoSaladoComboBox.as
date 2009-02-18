package commercial.flexinterfaces.elements
{
	import flash.events.*;
	import mx.controls.ComboBox;
	import zephyr.BroadcastEvent;
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;
	import flash.utils.*;
	import mx.events.ListEvent;
	import mx.styles.StyleManager;
	
	public class PanoSaladoComboBox extends ComboBox
	{
		protected var ModuleLoader:Class;
		protected var PanoSalado:Class;
		
		protected var moduleLoader:Object;
		protected var layerByName:Dictionary;
		
		protected var panoSalado:Object;
		
		protected var settings:XML;
		
		
		protected var spacesList:XMLList;
		
		protected var previewsList:XMLList;
		
		internal var __len:int;
		
		public function PanoSaladoComboBox()
		{
			super();
			
			styleName = 'PanoSaladoComboBox';
			
			addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true);
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
			
			initComboBox();
			
		}
		
		protected function initComboBox():void
		{
			var foreignXML:XML = moduleLoader.xmlByName["PanoSalado"] as XML;
			
			spacesList = foreignXML.spaces.space.( @id.search(/\.preview$/) == -1 );
			
			this.dataProvider = spacesList;
			
			this.labelField = "@label";
			
			previewsList = foreignXML.spaces.space.( @id.search(/\.preview$/) > -1 );
			
			__len = spacesList.length();
			
			if (__len > 1)
				this.addEventListener(ListEvent.CHANGE, psChangeHandler, false, 0, true);
			else
				this.enabled = false;
				
			
			moduleLoader.addEventListener(BroadcastEvent.SPACE_LOADED, updateSelectedItem, false, 0, true);
			
			this.selectedIndex = getIndexByName(this.dataProvider, panoSalado.currentSpace );
		}
		
		protected function psChangeHandler(e:ListEvent):void
		{
			var spaceToLoad:String = this.selectedItem.@id.toString();
			
			panoSaladoExecute('loadSpace:'+spaceToLoad);
		}
		
		protected function panoSaladoExecute(str:String):void
		{
			panoSalado.execute( str );
		}
		
		protected function updateSelectedItem(e:BroadcastEvent):void
		{
			var spaceLoaded:String = String(e.info.spaceLoaded);
			
			if (spaceLoaded.search(/\.preview$/) > -1)
				spaceLoaded = spaceLoaded.substring( 0 , spaceLoaded.search(/\.preview$/) );
			
			this.selectedIndex = getIndexByName(this.dataProvider, spaceLoaded );
		}
		
		private function getIndexByName(dataProvider:Object, value:*):int
		{
			var returnValue:int = -1;
			
			for (var i:int=0; i < dataProvider.length; i++)
			{ trace(String(dataProvider[i].@id), String(value));
				if (String(dataProvider[i].@id) == String(value) )
				{
					returnValue = i;
					break;
				}
			}
			
			return returnValue;
		}
	}
}