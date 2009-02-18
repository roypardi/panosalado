package
{
	import flash.display.*;
	import flash.net.*;
	import flash.events.*;
	import flash.utils.Dictionary;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import zephyr.BroadcastEvent;
	import flash.utils.ByteArray;

	import br.com.stimuli.loading.BulkLoader;
	import br.com.stimuli.loading.BulkProgressEvent;
	import br.com.stimuli.loading.BulkErrorEvent;
	
	public class ModuleLoader extends Sprite
	{
	    // Use the singleton pattern for module loader
	    private static var _instance:ModuleLoader = null;
	    
		private var settings:XML;
//		private var itemsToLoad:int = 0;
//		private var itemsLoaded:int = 0;
		private var layerByDepth:Array = new Array();
		
		public var allLayersLoaded:Boolean = false;
		
		public var layerByName:Dictionary = new Dictionary(true);
		
		public var xmlByName:Dictionary = new Dictionary(true);
		
		public var bulkLoader:BulkLoader = new BulkLoader("moduleLoaderBulkLoader");
		
		public function ModuleLoader()
		{
		    if (_instance != null) {
                throw new Error("ModuleLoader can only be accessed through ModuleLoader.moduleLoader");
            } else {
    			var xmlLoader:URLLoader = new URLLoader();
    			xmlLoader.dataFormat = URLLoaderDataFormat.BINARY;
    			xmlLoader.load( new URLRequest( loaderInfo.parameters.xml?loaderInfo.parameters.xml:"PanoSalado.xml" ) );
    			xmlLoader.addEventListener(Event.COMPLETE, onXMLLoaded);
    			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
    			_instance = this;
			}
		}

        public static function get moduleLoader():ModuleLoader
        {
            return _instance;
        }
		
		private function onIOError(e:IOErrorEvent):void
		{
			trace("ModuleLoader: XML file " + loaderInfo.parameters.xml + " not found");
		}
		
		private function onXMLLoaded(e:Event):void
		{
			settings = getXMLFromLoadedByteArray( e.target.data );
			
			var loadingMeterFirst:Boolean = false;
			
			for each (var layer:XML in settings.layer )
			{
				if (layer.@id == "Meter")
				{ 
					loadingMeterFirst = true;
					
					bulkLoader.add
					( 
						layer.@url.toString(), 
						{
							id : layer.@id.toString(), 
							context : new LoaderContext( false, ApplicationDomain.currentDomain)
						} 
					);
					
					bulkLoader.get( layer.@url.toString() ).addEventListener(Event.COMPLETE, layerLoaded, false, 100, true);
					
					bulkLoader.get( layer.@url.toString() ).addEventListener(BulkLoader.COMPLETE, onMeterComplete, false, 0, true);
					
					bulkLoader.start()
				}
			}
			
			if ( ! loadingMeterFirst )
			{
				loadRest();
			}
		}
		
		private function getXMLFromLoadedByteArray(input:ByteArray):XML
		{
			var output:XML;
			
			try 
			{
				input.uncompress()
			}
			catch(e:Error){}
			
			output = XML(input);
			
			return output;
		}
		
		private function layerLoaded(e:Event):void
		{ 
			var name:String = e.target.id.toString();
			var layer:DisplayObject = e.target.content;
			
			layerByDepth[settings.*.(@id == name ).@depth || 0] = layer;
			
			layerByName[ name.toString() ] = layer;
			
			
			for (var i:int=0; i < layerByDepth.length; i++)
			{
				var displayObject:DisplayObject = layerByDepth[i];
				if (displayObject)
				{
					addChild( displayObject );
				}
			}
			
		}
		
		

		
		private function onMeterComplete(e:Event):void
		{
			loadRest();
		}
		
		
		private function loadRest():void
		{
			
			bulkLoader.addEventListener(BulkProgressEvent.PROGRESS, onProgress, false, 0, true);
			
			bulkLoader.addEventListener(BulkLoader.COMPLETE, onComplete, false, 0, true);
			
			for each (var layer:XML in settings.layer )
			{
				xmlByName[layer.@id.toString()] = layer;
				
				bulkLoader.add
				( layer.@url.toString(), 
					{
						id : layer.@id.toString(), 
						context : new LoaderContext( false, ApplicationDomain.currentDomain),
						weight: (layer.@weight || 10)
					} 
				);
				
				bulkLoader.get( layer.@url.toString() ).addEventListener(Event.COMPLETE, layerLoaded, false, 100, true);
				
			}
			
			bulkLoader.start();
		}
		
		
		private function onProgress(e:BulkProgressEvent):void
		{
			dispatchEvent( new BroadcastEvent(BroadcastEvent.LOAD_PROGRESS, { id : bulkLoader.name, percentLoaded : e.weightPercent }) );
		}
		
		
		private function onComplete(e:BulkProgressEvent):void
		{
			dispatchEvent( new BroadcastEvent(BroadcastEvent.LOAD_PROGRESS, { id : bulkLoader.name, percentLoaded : e.weightPercent }) );
		
		
			for (var i:int=0; i < layerByDepth.length; i++)
			{
				var displayObject:DisplayObject = layerByDepth[i];
				if (displayObject)
				{
					addChild( displayObject );
				}
			}
			
			allLayersLoaded = true;
			dispatchEvent( new BroadcastEvent(BroadcastEvent.ALL_LAYERS_LOADED) );
		}
		
		

	}
}