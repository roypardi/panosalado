package com.panosalado.model
{
	import com.eyesee360.geometry.IProjection;
	
	import flash.display.BitmapData;
	import flash.events.IEventDispatcher;
	
	public interface IImageSource extends IEventDispatcher
	{
		function get bitmapData():BitmapData;
		function get projection():IProjection;
		function get loadProgress():Number;
		function get suggestedRefreshInterval():Number;
	}
}
