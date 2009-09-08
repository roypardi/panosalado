package com.panosalado.view
{
	import com.eyesee360.geometry.Unwarp;
	import com.panosalado.model.PanoramaNode;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;

	public class UnwarpPanoView extends Sprite
	{
		private var _panoramaNode:PanoramaNode;
		private var _unwarpedImageSource:Unwarp;
		private var _viewport:Sprite;
		
		public function UnwarpPanoView(panoramaNode:PanoramaNode)
		{
			super();
			_panoramaNode = panoramaNode;
			_unwarpedImageSource = new Unwarp(_panoramaNode.imageSource);
			_unwarpedImageSource.projection = _panoramaNode.viewProjection;
			_unwarpedImageSource.dimensions = Point(this.width, this.height);

			_viewport = new Sprite();
			this.addChild(_viewport);
		}
		
		public function set width(w:Number):void
		{
			super.width = w;
			_unwarpedImageSource.dimensions = Point(this.width, this.height);
		}
		
				
		public function set height(h:Number):void
		{
			super.height = h;
			_unwarpedImageSource.dimensions = Point(this.width, this.height);
		}

		public function draw()
		{
			if (_unwarpedImageSource.needsUpdate()) {
				_unwarpedImageSource.update();
			}
			var displayBitmap:BitmapData = _unwarpedImageSource.bitmapData;

		    _viewport.graphics.clear();
		    _viewport.graphics.beginBitmapFill(displayBitmapData); 
            _viewport.graphics.drawRect(0, 0, this.width, this.height);
		}
		
	}
}