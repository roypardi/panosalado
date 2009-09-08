package com.panosalado.model
{
	import com.eyesee360.geometry.RectilinearProjection;
	
	public class PanoramaNode implements INode
	{
		private var _imageSource:IImageSource;
		private var _viewProjection:RectilinearProjection;
		
		public function PanoramaNode(source:IImageSource = null, viewProj:RectilinearProjection = null)
		{
			_imageSource = source;
			if (viewProj) {
				_viewProjection = viewProj;
			} else {
				_viewProj = new RectilinearProjection();
			}
		}
		
		public function get imageSource():IImageSource
		{
			return _imageSource;
		}
		
		public function set imageSource(source:IImageSource):void
		{
			_imageSource = source;
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
		}

	}
}