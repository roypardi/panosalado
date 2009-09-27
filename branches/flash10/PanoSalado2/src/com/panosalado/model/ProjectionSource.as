package com.panosalado.model
{
	import com.eyesee360.geometry.IProjection;
	import com.panosalado.event.ImageSourceEvent;
	
	import flash.display.BitmapData;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	/**
	* This event is dispatched each time the unwarped image prijection updates.
	*
	* @eventType flash.events.Event
	**/
	[Event(name="projectionUpdate", type="com.panosalado.event.ImageSourceEvent")]

	public class ProjectionSource extends EventDispatcher implements IImageSource
	{
		private var _projection:IProjection;

		public function ProjectionSource(proj:IProjection = null)
		{
			_projection = proj;
		}

		public function set projection(proj:IProjection):void
		{
			_projection = proj;
			var e:Event = new com.panosalado.event.ImageSourceEvent(ImageSourceEvent.PROJECTION_UPDATE);
			this.dispatchEvent(e);
		}
		
		public function get projection():IProjection
		{
			return _projection;
		}
		
		public function get bitmapData():BitmapData
		{
			var error:Error = new flash.errors.IllegalOperationError();
			throw(error);
		}
		
		public function get loadProgress():Number
		{
			var error:Error = new flash.errors.IllegalOperationError();
			throw(error);
		}
		
		public function get suggestedRefreshInterval():Number
		{
			return 1000/30;
		}
	}
}