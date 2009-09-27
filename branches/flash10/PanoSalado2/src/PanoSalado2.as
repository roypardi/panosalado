package {
	import com.panosalado.controller.ViewerController;
	
	import flash.display.Sprite;
	import flash.system.ApplicationDomain;

	public class PanoSalado2 extends Sprite
	{
		private var _vc:ViewerController;
		
		public function PanoSalado2()
		{
			var baseURL:String = this.loaderInfo.loaderURL;
			baseURL = baseURL.substring(0, baseURL.lastIndexOf("/") + 1);
			
			var params:Object = this.loaderInfo.parameters;
			for (var key:String in params) {
				if (key == "panorama") {
					_vc = ViewerController.controllerWithPanoramaURL(params[key], baseURL, params);
				}
			}
			
			if (_vc) {
				this.addChild(_vc);
			}
		}
	}
}
