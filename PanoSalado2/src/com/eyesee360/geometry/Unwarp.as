package com.eyesee360.geometry
{
	import com.panosalado.event.ImageSourceEvent;
	import com.panosalado.model.IImageSource;
	
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.ShaderEvent;
		
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

	public class Unwarp extends EventDispatcher implements IImageSource
	{
		private var _fromImageSource:IImageSource;
		private var _sourceProjection:IProjection;
		private var _projection:IProjection;
		private var _dimensions:Object;
		private var _unwarpShader:Shader;
		private var _unwarpJob:ShaderJob;
		private var _unwarpedBitmapData:BitmapData;
		private var _async:Boolean;
		
		[Embed(source="../../../../pbj/EquirectangularToRectilinearKernel.pbj", mimeType="application/octet-stream")]
		private var EquirectangularToRectilinearKernel:Class;

		[Embed(source="../../../../pbj/CylindricalToRectilinearKernel.pbj", mimeType="application/octet-stream")]
		private var CylindricalToRectilinearKernel:Class;
		
		public function Unwarp(fromImageSource:IImageSource)
		{
			_fromImageSource = fromImageSource;
			_fromImageSource.addEventListener(ImageSourceEvent.IMAGE_UPDATE, imageSourceUpdated);
			if (_fromImageSource.projection) {
				_sourceProjection = _fromImageSource.projection;
			}
			_fromImageSource.addEventListener(ImageSourceEvent.PROJECTION_UPDATE, sourceProjectionUpdated);
			_async = true;
		}
		
		public function set dimensions(dims:Object):void
		{
			if (dims.width > 0 && dims.height > 0) {
				
				// modulo the dimensions for the shader
				var mw:Number = dims.width % 4;
				var mh:Number = dims.height % 4;
				dims.width += (mw) ? 4 - mw : 0; 
				dims.height += (mh) ? 4 - mh : 0;
				
				_dimensions = dims;
				_unwarpedBitmapData = null;
			
				if (!_unwarpShader) {
					initShader();
				}
				
				update();
			}
		}
		
		public function set projection(toProj:IProjection):void
		{
			_projection = toProj;
			if (_projection is IEventDispatcher) {
				(_projection as IEventDispatcher).addEventListener(Event.CHANGE, projectionUpdated);
			}
			
			if (!_unwarpShader) {
				initShader();
			}
			
			var projectionEvent:ImageSourceEvent = new ImageSourceEvent(ImageSourceEvent.PROJECTION_UPDATE);
			this.dispatchEvent(projectionEvent);
		}
		
		public function get fromImageSource():IImageSource
		{
			return _fromImageSource;
		}
				
		public function get dimensions():Object
		{
			return _dimensions;
		}
		
		public function get projection():IProjection
		{
			return _projection;
		}
		
		public function get loadProgress():Number
		{
			return _fromImageSource.loadProgress;
		}
		
		public function get bitmapData():BitmapData
		{
			return _unwarpedBitmapData;
		}
		
		public function get suggestedRefreshInterval():Number
		{
			return _fromImageSource.suggestedRefreshInterval;
		}
		
		private function imageSourceUpdated(e:Event):void
		{
			this.update();
		}
		
		private function sourceProjectionUpdated(e:Event):void
		{
			_sourceProjection = _fromImageSource.projection;
			initShader();
		}
		
		private function projectionUpdated(e:Event):void
		{
			this.updateToProjection();
			this.update();
		}
		
		public function update():void
		{
			// unwarp
			if (_unwarpShader && _dimensions) {
				
				if (!_unwarpedBitmapData) {
					_unwarpedBitmapData = new BitmapData(_dimensions.width, _dimensions.height, false, 0);
				    _unwarpShader.data.outputDimensions.value = [_dimensions.width, _dimensions.height];
				}
				
				// Update toProjection with every frame. Change updates would be great.
				// updateToProjection();
				
	            _unwarpJob = new ShaderJob(_unwarpShader, _unwarpedBitmapData, _dimensions.width, _dimensions.height);
				_unwarpJob.addEventListener(ShaderEvent.COMPLETE, unwarpJobComplete);
				_unwarpJob.start(!_async);
				
				if (!_async) {
					var imageUpdateEvent:ImageSourceEvent = new ImageSourceEvent(ImageSourceEvent.IMAGE_UPDATE);
					this.dispatchEvent(imageUpdateEvent);
				}
			}
		}
		
		private function unwarpJobComplete(e:ShaderEvent):void
		{
			var imageUpdateEvent:ImageSourceEvent = new ImageSourceEvent(ImageSourceEvent.IMAGE_UPDATE);
			this.dispatchEvent(imageUpdateEvent);
		}
		
		// Must be called when toProjection is set. FromImageSource defines the 
		// "from" projection and must have been set in the constructor.
		private function initShader():void
		{
			if (_unwarpShader) return;	// can't re-init
			if (!_sourceProjection || !_projection || !_dimensions) return;
			if (!_fromImageSource.bitmapData) return;
			
			var fromType:String = _sourceProjection.type;
			var toType:String = _projection.type;
			
			if (toType == Projection.RECTILINEAR) {
				
				if (fromType == Projection.EQUIRECTANGULAR) {
					this.initShaderEquirectangularToRectilinear();
				} else if (fromType == Projection.CYLINDRICAL) {
					//this.initShaderEquirectangularToRectilinear();
					this.initShaderCylindricalToRectilinear();
				} else {
					throw("Cannot unwarp from " + fromType + " to " + toType);
				}
				this.updateToProjection();
				
				_unwarpedBitmapData = new BitmapData(_dimensions.width, _dimensions.height, false, 0);
			    _unwarpShader.data.outputDimensions.value = [_dimensions.width, _dimensions.height];
				
			} else {
				throw("Cannot unwarp to " + toType);
			}
		}
		
		private function initShaderEquirectangularToRectilinear():void
		{
			_unwarpShader = new Shader( new EquirectangularToRectilinearKernel() );
			var input:BitmapData = _fromImageSource.bitmapData;
			var bounds:Array = _sourceProjection.bounds;
			
		    _unwarpShader.data.src.input = input;
			_unwarpShader.data.inputDimensions.value = [input.width,input.height];
			_unwarpShader.data.equirectangularBoundsRad.value = bounds;
		}

		private function initShaderCylindricalToRectilinear():void
		{
			_unwarpShader = new Shader( new CylindricalToRectilinearKernel() );
			var input:BitmapData = _fromImageSource.bitmapData;
			var bounds:Array = _sourceProjection.bounds;
			
			// map angle to Y axis for bounds
			bounds[3] = Math.tan(bounds[1] + bounds[3]) - Math.tan(bounds[1]);
			bounds[1] = Math.tan(bounds[1]);
			
		    _unwarpShader.data.src.input = input;
			_unwarpShader.data.inputDimensions.value = [input.width,input.height];
			_unwarpShader.data.cylindricalBounds.value = bounds;
		}
		
		private function updateToProjection():void
		{
			if (!_unwarpShader) return;
			
			if (_projection is RectilinearProjection) {
				var rectProjection:RectilinearProjection = _projection as RectilinearProjection;
				var viewBounds:Array = rectProjection.bounds;
				var orientation:Vector.<Number> = rectProjection.orientation.rawData;
				var rotationMatrix:Array = [
					orientation[0], orientation[1], orientation[2],
					orientation[4], orientation[5], orientation[6],
					orientation[8], orientation[9], orientation[10]
				];
				
				_unwarpShader.data.viewBounds.value = viewBounds;
				_unwarpShader.data.rotationMatrix.value = rotationMatrix;
			}
		}
	}
}
