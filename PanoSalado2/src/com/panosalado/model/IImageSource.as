package com.panosalado.model
{
	import com.eyesee360.geometry.IProjection;
	
	import flash.display.Bitmap;
	
	public interface IImageSource
	{
		public function get bitmapData():BitmapData;
		public function get projection():IProjection;
		public function get loadProgress():Number;
	}
}
