package commercial.flexinterfaces.elements
{
	import mx.core.Application;
	import flash.events.*;
	import flash.system.ApplicationDomain;
	
	import flash.utils.Dictionary;
	import mx.styles.StyleManager;
	import mx.events.StyleEvent;
	import flash.events.IEventDispatcher;
	
	import zephyr.BroadcastEvent;
	import mx.core.IToolTip;
	import mx.core.Singleton;
//	import flash.utils.getDefinitionByName;
	
	import flash.net.*;
	//import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.events.ContextMenuEvent;
    
    import commercial.rubenswieringa.CSSLoader;
		import mx.events.StyleEvent;
		import mx.core.Application;
		import zephyr.PanoSaladoCanvas3D;
		import flash.display.DisplayObject;
		import flash.utils.Dictionary;
	
	
	public class PanoSaladoApplication extends Application
	{
		private var ModuleLoader:Class;
		
		private var PanoSalado:Class;
		
		//private var BroadcastEvent:Class;
		
		public var moduleLoader:Object;
		
		public var panoSalado:Object;
		
		public var settings:XML;
		
		public var layerByName:Dictionary;
		
		private var manualToolTip:IToolTip;
		
		//assure that custom tooltip managers get compiled in.
		internal var panoSaladoToolTipManager : PanoSaladoToolTipManager;
		internal var iPanoSaladoToolTipManager : IPanoSaladoToolTipManager;
		internal var panoSaladoToolTipManagerImpl : PanoSaladoToolTipManagerImpl;
		
		private var contextMenuItems:Dictionary = new Dictionary(true);
		
		protected var cssLoader:CSSLoader;
		protected var initiallyInstantiatedChildren:Dictionary = new Dictionary(true);
		
		public function PanoSaladoApplication()
		{
			super();
			
			horizontalScrollPolicy="off";
			
			verticalScrollPolicy="off";
			
			Singleton.registerClass("commercial.flexinterfaces.elements::IPanoSaladoToolTipManager", 
				PanoSaladoToolTipManagerImpl);
			
			init();
		}
		
		private function init():void
		{
			addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true);
		}
		
		override public function initialize():void
		{
			super.initialize();
			
			//visible = false;
			
		}
		
		private function stageReady(e:Event=null):void
		{ 
			//BroadcastEvent = ApplicationDomain.currentDomain.getDefinition("zephyr.BroadcastEvent") as Class;
			
			ModuleLoader = ApplicationDomain.currentDomain.getDefinition("ModuleLoader") as Class;
			
			moduleLoader = ModuleLoader( parent.parent );
			
			moduleLoader.addEventListener(BroadcastEvent.ALL_LAYERS_LOADED, layersReady, false, 0, true);
			
			moduleLoader.addEventListener(BroadcastEvent.SHOW_TOOLTIP, toolTipHandler, false, 0, true);
			moduleLoader.addEventListener(BroadcastEvent.HIDE_TOOLTIP, toolTipHandler, false, 0, true);
			
			stage.addEventListener(Event.RESIZE, onResize, false, 0, true);
			
			stage.addEventListener(Event.FULLSCREEN, onResize, false, 0, true);
			
			onResize();
			
			layersReady();
			
			initStyleSheets();
			
			initContextMenuItems();
		}
		
		private function onResize(e:Event=null):void
		{
			this.percentWidth=100;
			this.percentHeight=100;
		}
		

		
		protected function layersReady(e:Event=null):void
		{
			
			layerByName = Dictionary( moduleLoader.layerByName );
			
			PanoSalado = ApplicationDomain.currentDomain.getDefinition("PanoSalado") as Class;
			
			panoSalado = PanoSalado( layerByName["PanoSalado"] );
			
			settings = moduleLoader.xmlByName["Interface"] as XML;
		}
		
		override protected function initializationComplete():void
		{
			super.initializationComplete();
			
			for (var o:Object in initiallyInstantiatedChildren)
			{ 
				if ( !(o is PanoSaladoCanvas3D) && !(o is Application) )
					DisplayObject(o).visible = false;
			}
		}
		
		protected function initStyleSheets():void
		{
			 if (settings.style.@url != undefined) 
 			{
 				var dispatcher:IEventDispatcher = 
 					StyleManager.loadStyleDeclarations( settings.style.@url.toString() );
 				
 				dispatcher.addEventListener(StyleEvent.PROGRESS,themeStyleSheetProgress, false, 0, true);
 				dispatcher.addEventListener(StyleEvent.COMPLETE,themeStyleSheetLoaded, false, 0, true);
 			}
 			else
 			{
 				themeStyleSheetLoaded();
 			}
		}
		
		protected function themeStyleSheetLoaded(e:StyleEvent=null):void
		{
			moduleLoader.dispatchEvent( new BroadcastEvent( BroadcastEvent.STYLE_SHEET_LOADED ) );
			
			if (settings.style != undefined)
			{
				 cssLoader = new CSSLoader();
				 
				 cssLoader.loadString(settings.style, "overrideStyleSheet", this);
				 
				 moduleLoader.dispatchEvent( new BroadcastEvent(BroadcastEvent.OVERRIDE_STYLE_SHEET_LOADED) );
			}
			
			moduleLoader.dispatchEvent( new BroadcastEvent(BroadcastEvent.STYLING_COMPLETE) );
			
			for (var o:Object in initiallyInstantiatedChildren)
			{ // set to original visibility value as stored in Dict
				if ( !(o is PanoSaladoCanvas3D) && !(o is Application) )
					DisplayObject(o).visible = initiallyInstantiatedChildren[o];
			}
		}
		
		protected function themeStyleSheetProgress(e:StyleEvent):void
		{
			var percent:Number = e.bytesLoaded/e.bytesTotal;
			
			moduleLoader.dispatchEvent( new BroadcastEvent(BroadcastEvent.LOAD_PROGRESS, { id : "PanoSaladoApplicationStyleLoader", percentLoaded : percent }) );
		}
		
		protected function initContextMenuItems():void
		{
			var psXML:XML = <ContextMenuItem caption="SpinControl:PanoSalado" destination="http://panosalado.com" window="_blank"/>;
			
			var psMenuItem:ContextMenuItem = new ContextMenuItem(psXML.@caption);
			
			contextMenuItems[psMenuItem] = psXML;
			
			psMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, goToURL, false, 0, true);
			
			this.contextMenu.customItems.push(psMenuItem);
			
			
			var menuItems:XMLList = settings.ContextMenuItem;
			
			for each (var itemXML:XML in menuItems)
			{ 
				var menuItem:ContextMenuItem = new ContextMenuItem(itemXML.@caption);
				
				contextMenuItems[menuItem] = itemXML;
				
				if(itemXML.@destination != undefined && itemXML.@destination != "")
				{
					menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, goToURL, false, 0, true);
				}
				this.contextMenu.customItems.push(menuItem);
			}
		}
		
		public function goToURL(e:ContextMenuEvent):void
		{
			//could also pipe this over to PanoSalado class's openURL function....
			
			var itemXML:XML = contextMenuItems[e.target];
			
			var url:String = itemXML.@destination;
			
			var window:String = itemXML.@window || "_blank";
			
			navigateToURL( new URLRequest(url), window);
		}
		
		protected function toolTipHandler(e:BroadcastEvent):void
		{
			var text:String = String( e.info.toolTip );
			var xPos:Number = Number( e.info.x );
			var yPos:Number = Number( e.info.y );
			
			switch (e.type)
			{
				case BroadcastEvent.SHOW_TOOLTIP :
					manualToolTip = PanoSaladoToolTipManager.createToolTip(text, xPos, yPos );
					break;
				
				case  BroadcastEvent.HIDE_TOOLTIP :
					PanoSaladoToolTipManager.destroyToolTip( manualToolTip );
					break;
			}
			
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
		
		
		protected function recursiveGetChildren(displayObj:Object):void
		{
			initiallyInstantiatedChildren[ displayObj ] = displayObj.visible;
			
			if ( displayObj.hasOwnProperty("getChildren") )
			{
				var children:Array = displayObj.getChildren();
				var len:int = children.length;
				for (var i:int=0; i<len; i++)
				{
					recursiveGetChildren( children[i] );
				}
			}
		}
	}
}