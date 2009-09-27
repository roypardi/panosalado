package com.panosalado.controller
{
	import com.eyesee360.geometry.Projection;
	import com.panosalado.event.PresentationEvent;
	import com.panosalado.model.IImageSource;
	import com.panosalado.model.INode;
	import com.panosalado.model.ImageFileSource;
	import com.panosalado.model.PanoramaNode;
	import com.panosalado.model.Presentation;
	import com.panosalado.model.ProjectionSource;
	import com.panosalado.model.VideoSource;
	import com.panosalado.view.UnwarpPanoView;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	public class ViewerController extends Sprite
	{
		private var _presentation:Presentation;
		private var _nodeView:UnwarpPanoView;
		private var _mouseController:Object;
		private var _keyboardController:Object;
		private static const _imageExts:Array = ["jpg","png","tif","tiff"];
		private static const _videoExts:Array = ["flv","m4v","mp4","mov","vwm","vwmovie"];
		private static const _videoProtos:Array = ["rtmp", "rtmps", "rtmpe"];
		
		public static function controllerWithPanoramaURL(url:String, baseURL:String, params:Object = null):ViewerController
		{
			// Initialize based on the kind of file at the URL.
			var extStart:int = url.lastIndexOf(".");
			var protEnd:int = url.indexOf(":");
			var extension:String = url.slice(extStart+1).toLowerCase();
			var protocol:String = url.slice(0,protEnd).toLowerCase();
			var source:IImageSource = null;
			
			if (_imageExts.indexOf(extension) >= 0) {
				// Load an image file
				var imageSrc:ImageFileSource = new ImageFileSource(url);
				source = imageSrc;
			} else if (_videoProtos.indexOf(protocol) >= 0 
					   || _videoExts.indexOf(extension) >= 0) {
				// Load a panoramic video
				var videoSrc:VideoSource = new VideoSource(url);
				source = videoSrc;
			}

			if (source) {
				if (params.hasOwnProperty('projection') && (source is ProjectionSource)) {
					var projSource:ProjectionSource = source as ProjectionSource;
					var proj:Projection = Projection.projectionFromJSON(params.projection);
					if (proj) projSource.projection = proj;
				}
				
				var node:PanoramaNode = new PanoramaNode(source);
				var presentation:Presentation = new Presentation([node]);
				return new ViewerController(presentation);	
			}
			
			return null;
		}
		
		public function ViewerController(presentation:Presentation)
		{
			_presentation = presentation;
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		public function addedToStage(e:Event):void
		{
			this.stage.quality = flash.display.StageQuality.HIGH;
			this.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
			this.stage.align = flash.display.StageAlign.TOP_LEFT;
			
			this.stage.addEventListener(Event.RESIZE, stageResized);
			
			_presentation.addEventListener(PresentationEvent.NODE_ENTER, nodeEntered, false, 0, true);
			_presentation.addEventListener(PresentationEvent.NODE_EXIT, nodeExited, false, 0, true);
			
			if (_presentation.currentNode) {
				this.showNode(_presentation.currentNode);
			}
		}
		
		private function stageResized(e:Event):void
		{
			_nodeView.setSize(stage.stageWidth, stage.stageHeight);
		}

		private function showNode(node:INode):void
		{
			// Find an appropriate view. Easy when there's only one.
			if (node is PanoramaNode) {
				var dims:Point = new Point(this.stage.stageWidth, this.stage.stageHeight)
				var view:UnwarpPanoView = new UnwarpPanoView(node as PanoramaNode);
				_nodeView = view;
				this.addChild(_nodeView);
				
				this.stageResized(null);
				_mouseController = new MouseVelocityController(_nodeView, (node as PanoramaNode));
				_keyboardController = new KeyboardVelocityController(_nodeView, (node as PanoramaNode));
			}
		}
		
		private function nodeEntered(e:PresentationEvent):void
		{
			this.showNode(e.node);
		}
		
		private function nodeExited(e:PresentationEvent):void
		{
			this.removeChild(_nodeView);
			_mouseController = null;
			_keyboardController = null;
			_nodeView = null;
		}
	}
}