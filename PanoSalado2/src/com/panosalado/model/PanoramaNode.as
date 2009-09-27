package com.panosalado.model
{
	import com.eyesee360.geometry.RectilinearProjection;
	import com.panosalado.event.ImageSourceEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	public class PanoramaNode extends EventDispatcher implements INode
	{
		private var _imageSource:IImageSource;
		private var _viewProjection:RectilinearProjection;
		
		public function PanoramaNode(source:IImageSource = null, viewProj:RectilinearProjection = null)
		{
			this.imageSource = source;
			
			if (viewProj) {
				this.viewProjection = viewProj;
			} else {
				this.viewProjection = new RectilinearProjection();
			}
		}
		
		public function get imageSource():IImageSource
		{
			return _imageSource;
		}
		
		public function set imageSource(source:IImageSource):void
		{
			_imageSource = source;
			_imageSource.addEventListener(com.panosalado.event.ImageSourceEvent.IMAGE_UPDATE, eventRelay);
			_imageSource.addEventListener(com.panosalado.event.ImageSourceEvent.PROJECTION_UPDATE, sourceProjectionUpdate);
		}
		
		// We could let the view property be an IProjection, but that may
		// require move view classes to handle other cases.
		public function get viewProjection():RectilinearProjection
		{
			return _viewProjection;
		}
		
		public function set viewProjection(viewProjection:RectilinearProjection):void
		{
			_viewProjection = viewProjection;
			if (_imageSource.projection) {
				_viewProjection.setConstraintsFromProjection(_imageSource.projection);
			}
		}
		
		private function sourceProjectionUpdate(e:Event):Boolean
		{
			if (_imageSource.projection) {
				_viewProjection.setConstraintsFromProjection(_imageSource.projection);
			}
			return eventRelay(e);
		}

		private function eventRelay(e:Event):Boolean
		{
			this.dispatchEvent(e);
			return true;
		}
	}
}