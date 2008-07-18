package
{
	import flash.display.*;
	import flash.net.*;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import zephyr.utils.LayerEvent;
	
	public class Main extends Sprite
	{
		private var settings:XML;
		private var itemsToLoad:int = 0;
		private var itemsLoaded:int = 0;
		private var layerByDepth:Array = new Array();
		public var layerByName:Dictionary = new Dictionary(true);
		
		public function Main()
		{
			var xmlLoader:URLLoader = new URLLoader();
			xmlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			xmlLoader.load( new URLRequest( loaderInfo.parameters.xml?loaderInfo.parameters.xml:"Main.xml" ) );
			xmlLoader.addEventListener(Event.COMPLETE, onXMLLoaded);
		}
		
		private function onXMLLoaded(e:Event):void
		{
			settings = XML( e.target.data );
			for each (var layer:XML in settings.* )
			{
				var loader:Loader = new Loader();
				loader.load( new URLRequest( layer.@url.toString() ), new LoaderContext( false, ApplicationDomain.currentDomain) );
				loader.name = layer.@id.toString();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, layerLoaded);
				
				itemsToLoad++
			}
		}
		
		private function layerLoaded(e:Event):void
		{
			itemsLoaded++;
			
			var name:String = e.target.loader.name.toString();
			var layer:DisplayObject = e.target.content;
			//layer.name = name;
			layerByDepth[settings.*.(@id == name ).@depth || 0] = layer;
			
			layerByName[ name.toString() ] = layer;
			
			addChild( layer );
			
			if (itemsLoaded == itemsToLoad)
			{
				for (var i:int=0; i < layerByDepth.length; i++)
				{
					var displayObject:DisplayObject = layerByDepth[i];
					if (displayObject)
					{
						addChild( displayObject );
					}
				}
				
				dispatchEvent( new LayerEvent(LayerEvent.ALL_LAYERS_LOADED) );
			}
		}
	}
}