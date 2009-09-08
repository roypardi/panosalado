package com.eyesee360.geometry
{
	import com.panosalado.model.IImageSource;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.geom.Point;
	
	public class Unwarp implements IImageSource
	{
		private var _fromImageSource:IImageSource;
		private var _projection:IProjection;
		private var _dimensions:Point;
		private var _unwarpShader:Shader;
		private var _unwarpedBitmapData:BitmapData;
		
		public function Unwarp(fromImageSource:IImageSource)
		{
			_fromImageSource = fromImageSource;
		}
		
		public function get fromImageSource():IImageSource
		{
			return _fromImageSource;
		}
				
		public function get dimensions():Point
		{
			return _dimensions;
		}
		
		public function set dimensions(dims:Point):void
		{
			_dimensions = dims;
			
			// Update bitmap and shader parameters
			_displayBitmap = new BitmapData(dims.x, dims.y);
		    var displayDims:Array = [dims.x, dims.y];
		    unwarpShader.data.outputDimensions.value = displayDims;
		}
		
		public function get projection():IProjection
		{
			return _projection;
		}
		
		public function set projection(toProj:IProjection):void
		{
			_projection = toProj;
			
			initShader();
		}
		
		public function get needsUpdate():Boolean
		{
			return _fromImageSource.needsUpdate;
		}
		
		public function get loadProgress():Number
		{
			return _fromImageSource.needsUpdate;
		}
		
		public function get bitmapData:():BitmapData
		{
			return _unwarpedBitmapData;
		}
		
		public function update():void
		{
			// Update the image source
			if (_fromImageSource.needsUpdate()) {
				_fromImageSource.update();
			}

			// unwarp
            unwarpJob = new ShaderJob(_unwarpShader, _unwarpedBitmapData, _dimensions.x, _dimensions.y);
			unwarpJob.start(true);
		}
		
		// Must be called when toProjection is set. FromImageSource defines the 
		// "from" projection and must have been set in the constructor.
		private function initShader():void
		{
			var fromType:String = _fromImageSource.projection.type;
			var toType:String = _projection.type;
			
			if (toType == Projection.RECTILINEAR) {
				
				if (fromType == Projection.EQUIRECTANGULAR) {
					this.initShaderEquirectangularToRectilinear();
				} else if (fromType == Projection.CYLINDRICAL) {
					this.initShaderCylindricalToRectilinear();
				} else {
					throw("Cannot unwarp from " + fromType + " to " + toType);
				}
				this.updateToProjection();
				
			} else {
				throw("Cannot unwarp to " + toType);
			}

		}
		
		private function initShaderEquirectangularToRectilinear():void
		{
			unwarpShader = new Shader( new EquirectangularToPerspectiveKernel() );
			var input:BitmapData = _fromImageSource.bitmapData;
			var bounds:Array = _fromImageSource.projection.boundsRad;
			
		    unwarpShader.data.src.input = input;
			unwarpShader.data.inputDimensions.value = [input.width,input.height];
			unwarpShader.data.equirectangularBoundsRad.value = bounds;
		}

		private function initShaderCylindricalToRectilinear():void
		{
			unwarpShader = new Shader( new CylindricalToPerspectiveKernel() );
			var input:BitmapData = _fromImageSource.bitmapData;
			var bounds:Array = _fromImageSource.projection.boundsRad;
			
		    unwarpShader.data.src.input = input;
			unwarpShader.data.inputDimensions.value = [input.width,input.height];
			unwarpShader.data.cylindricalBoundsRad.value = bounds;
		}
		
		private function updateToProjection():void
		{
			var viewBounds:Array = _projection.viewBounds;
			var orientation:Vector = _projection.orientation.rawData();
			var rotationMatrix:Array = [
				orientation[0], orientation[1], orientation[2],
				orientation[4], orientation[5], orientation[6],
				orientation[8], orientation[9], orientation[10]
			];
			
			unwarpShader.data.viewBounds = viewBounds;
			unwarpShader.data.rotationMatrix = rotationMatrix;
		}
	}
}
