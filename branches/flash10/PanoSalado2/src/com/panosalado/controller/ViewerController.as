package com.panosalado.controller
{
	import com.panosalado.model.ImageFileSource;
	import com.panosalado.model.PanoramaNode;
	import com.panosalado.model.Presentation;
	
	public class ViewerController
	{
		private var _presentation:Presentation;
		private const _imageExts:Array = ["jpg","png","tif","tiff"];
		private const _videoExts:Array = ["flv","m4v","mpg","mov"];
		
		public static function controllerWithPanoramaURL(url:String):ViewerController
		{
			// Initialize based on the kind of file at the URL.
			var extStart:int = url.lastIndexOf(".");
			var extension:String = url.slice(extStart+1).toLowerCase();
			
			if (extension in _imageExts) {
				// Load an image file
				var imageSrc:ImageFileSource = new ImageFileSource(url);
				var node:PanoramaNode = new PanoramaNode(imageSrc);
				var presentation:Presentation = new Presentation([node]);
			
				return new ViewerController(presentation);	
			
			} else if (extension in _videoExts) {
				// Load a panoramic video
			}
		}
		
		public function ViewerController(presentation:Presentation)
		{
			_presentation = presentation;
		}
		
	}
}