package com.panosalado.view
{
	import com.eyesee360.geometry.Unwarp;
	import com.panosalado.event.ImageSourceEvent;
	import com.panosalado.model.PanoramaNode;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class UnwarpPanoView extends Sprite
	{
		private var _panoramaNode:PanoramaNode;
		private var _unwarp:Unwarp;
		private var _drawTimer:Timer;
		private var _needsDisplay:Boolean = true;
		private var _noDrawCounter:uint = 0;
		private var _drawBitmapData:BitmapData = null;
		
		public function UnwarpPanoView(panoramaNode:PanoramaNode)
		{
			super();
			_panoramaNode = panoramaNode;
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStage);
			_unwarp = new Unwarp(_panoramaNode.imageSource);
			_unwarp.projection = _panoramaNode.viewProjection;			
		}
		
		private function addedToStage(e:Event):Boolean
		{
			_unwarp.addEventListener(ImageSourceEvent.IMAGE_UPDATE, imageUpdate);
			
			return true;
		}
		
		private function imageUpdate(e:Event):void
		{
			this.needsDisplay = true;
			_drawBitmapData = _unwarp.bitmapData;
		}
		
		private function onTick(event:TimerEvent):void 
        {
			if (_needsDisplay) {
				this.draw();
				_noDrawCounter = 0;
			} else {
				_noDrawCounter++;
				if (_noDrawCounter > 10) {
					_drawTimer.reset();
					trace("stopped timer");
				}
			}
        }

		public function setSize(w:Number, h:Number):void
		{
			_panoramaNode.viewProjection.aspectRatio = w / h;
			_unwarp.dimensions = {width:w, height:h};
		}
		
		public function draw():void
		{
			if (_drawBitmapData) {
			    //this.graphics.clear();
			    this.graphics.beginBitmapFill(_drawBitmapData); 
        	   	this.graphics.drawRect(0, 0, _drawBitmapData.width, _drawBitmapData.height);
        	   	this.graphics.endFill();
        	   	_needsDisplay = false;
   			} else {
   				// diagnostic
   				this.graphics.beginFill(0xFF0000);
        	   	this.graphics.drawRect(0, 0, _drawBitmapData.width, _drawBitmapData.height);
        	   	this.graphics.endFill();
   			}
		}
		
		public function get needsDisplay():Boolean
		{
			return _needsDisplay;
		}
		
		public function set needsDisplay(display:Boolean):void
		{
			_needsDisplay = display;
			if (display) {
				if (!_drawTimer) {
					var updateInterval:Number = _panoramaNode.imageSource.suggestedRefreshInterval;
					_drawTimer = new Timer(updateInterval);
					_drawTimer.addEventListener(TimerEvent.TIMER, onTick);
				} else if (!_drawTimer.running) {
					_drawTimer.start();
					trace("started timer");
				}
			}
		}
		
	}
}