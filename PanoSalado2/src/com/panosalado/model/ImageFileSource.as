package com.panosalado.model
{
	import com.eyesee360.geometry.IProjection;
	import com.panosalado.utils.XMPFileJPEG;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.xml.XMLDocument;

	public class ImageFileSource extends EventDispatcher implements IImageSource
	{
		protected const _bytesForMetadata:uint = 65535; 
		protected var _urlStream:URLStream;
		protected var _data:ByteArray;
		protected var _xmp:XMLDocument;
		protected var _bitmapData:BitmapData;
		protected var _projection:IProjection;
		protected var _bytesTotal:uint;
		
		public function ImageFileSource(fileURL:String)
		{
			var req:URLRequest = new URLRequest(fileURL);
			_data = new ByteArray();
		
			_urlStream = new URLStream();			
			_urlStream.addEventListener(ProgressEvent.PROGRESS, loadProgressHandler);
			_urlStream.addEventListener(Event.COMPLETE, loadCompleteHandler);
			_urlStream.load(req);
		}

		protected function loadProgressHandler(e:ProgressEvent):void
		{
			if (e.bytesTotal > 0) {
				_bytesTotal = e.bytesTotal;
			}
			
			// Load metadata now if we have enough bytes available.
			if (!_xmp && _urlStream.bytesAvailable >= _bytesForMetadata) {
				var length:uint = Math.min(_bytesForMetadata, _urlStream.bytesAvailable);
				_urlStream.readBytes(_data, 0, length);
				loadMetadata(_data);
			}
			
			// Relay
			this.dispatchEvent(e);
		}
		
		protected function loadCompleteHandler(e:Event):void
		{
			// Read in the remaining unread bytes.
			if (_data.length != _urlStream.bytesAvailable) {
				_urlStream.readBytes(_data, _data.length, 0);				
			}
			
			// Load metadata if we haven't yet.
			if (!_xmp) {
				loadMetadata(_data);
			}
			
			// Now load the image data.
			// We don't need a LoaderContext here since we're loading bytes.
			var loader:Loader = new Loader();
			// Need to get the bitmap from the added event.
			loader.addEventListener(Event.ADDED, function (addedEvent:Event) {
				// Expecting a Bitmap target.
				if (addedEvent.target is Bitmap) {
					var bitmap:Bitmap = addedEvent.target as Bitmap;
					this.bitmapData = bitmap.bitmapData;
				}
			});
			loader.loadBytes(_data);
			
			// Relay
			this.dispatchEvent(e);
		}
		
		protected function loadMetadata(var data:ByteArray):void
		{
			var xmpFile:XMPFileJPEG = new XMPFileJPEG(data);
			if (xmpFile.hasXmp) {
				_xmp = xmpFile.xmp;
				
				// With the metadata we can determine the projection,
				// or possibly load a thumbnail image before the 
				// rest of the image has downloaded.
			}
		}
		
		protected function set bitmapData(bitmap:BitmapData):void
		{
			_bitmapData = bitmap;
			if (!_projection) {
				_projeciton = geometry.guessProjectionFromBitmapData(_bitmapData);
			}
			this.dispatchEvent(Event.CHANGE);
		}
		
		protected function set projection(proj:IProjection):void
		{
			_projection = proj;
			this.dispatchEvent(Event.CHANGE);
		}
		
		protected function eventRelay(e:Event):void
		{
			this.dispatchEvent(e);
		}
		
		public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}
		
		public function get projection():IProjection
		{
			return _projection;
		}
		
		public function get loadProgress():Number
		{
			if (_bitmapData) {
				// Assumes _bitmapData only set after completion.
				return 1.0;
			} else if (_bytesTotal > 0) {
				return _urlStream.bytesAvailable / _bytesTotal;
			}
			return 0.0;
		}
	}
}