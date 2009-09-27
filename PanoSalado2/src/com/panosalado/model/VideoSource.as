package com.panosalado.model
{
	import com.eyesee360.geometry.Projection;
	import com.panosalado.event.ImageSourceEvent;
	
	import fl.video.FLVPlayback;
	import fl.video.MetadataEvent;
	import fl.video.VideoEvent;
	import fl.video.VideoPlayer;
	
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.net.NetStream;

	/**
	* This event is dispatched each time the unwarped image updates. This
	* may happen automatically as a result of the fromImageSource or projection
	* firing a change event.
	*
	* @eventType flash.events.Event
	**/
	[Event(name="imageUpdate", type="com.panosalado.event.ImageSourceEvent")]

	/**
	* This event is dispatched each time the unwarped image prijection updates.
	*
	* @eventType flash.events.Event
	**/
	[Event(name="projectionUpdate", type="com.panosalado.event.ImageSourceEvent")]

	public class VideoSource extends ProjectionSource
	{
		private var _netStream:NetStream;
		private var _video:FLVPlayback;
		private var _videoURL:String;
		private var _bitmapData:BitmapData;
		
		public function VideoSource(videoURL:String)
		{
			_videoURL = videoURL;
			
			_video = new FLVPlayback();
			_video.addEventListener(VideoEvent.READY, videoReady);
			_video.addEventListener(Event.ENTER_FRAME, enterFrame);
			_video.addEventListener(MetadataEvent.METADATA_RECEIVED, metadataReceived);
			_video.play(_videoURL);
		}
		
		private function videoReady(e:VideoEvent):Boolean
		{
			if (!_bitmapData) {
				var videoPlayer:VideoPlayer = _video.getVideoPlayer(e.vp);
				_video.setSize(videoPlayer.videoWidth, videoPlayer.videoHeight);
				var bitmapData:BitmapData = new BitmapData(videoPlayer.videoWidth, videoPlayer.videoHeight, false);
				this.bitmapData = bitmapData;
			}
			return true;
		}
		
		private function enterFrame(e:Event):Boolean
		{
			if (_bitmapData) {
				_bitmapData.draw(_video);
				var e:Event = new com.panosalado.event.ImageSourceEvent(ImageSourceEvent.IMAGE_UPDATE);
				this.dispatchEvent(e);
			}
			return true;
		}
		
		private function metadataReceived(e:MetadataEvent):Boolean
		{
			// Get the geometry from the video somehow
			return true;
		}
		
		public function set bitmapData(bitmap:BitmapData):void
		{
			_bitmapData = bitmap;
			if (!this.projection) {
				this.projection = Projection.guessProjectionFromBitmapData(_bitmapData);
			}
			var e:Event = new com.panosalado.event.ImageSourceEvent(ImageSourceEvent.IMAGE_UPDATE);
			this.dispatchEvent(e);
		}
		
		override public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}
		
		override public function get loadProgress():Number
		{
			return _video.bytesLoaded / _video.bytesTotal;
		}
		
		override public function get suggestedRefreshInterval():Number
		{
			if (_video && _video.metadata && _video.metadata.hasOwnProperty("videoframerate")) {
				var frameRate:Number = _video.metadata.videoframerate;
				return 1000 / frameRate;
			}
			return super.suggestedRefreshInterval;
		}
	}
}