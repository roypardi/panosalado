package commercial.flexinterfaces.elements
{
	import mx.containers.Box;
	import mx.styles.StyleManager;
	import mx.core.UIComponent;
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;
	
	public class BetterBox extends Box
	{
		private var horizontalScrollBarExists:Boolean = false;
		
		private var verticalScrollBarExists:Boolean = false;
		
		
		public function BetterBox()
		{
			super();
		}
		
		//http://www.craftymind.com/2008/03/31/hacking-width-and-height-properties-into-flexs-css-model/
		override public function styleChanged(styleProp:String):void
		{
			super.styleChanged(styleProp);
			
			if(!styleProp || styleProp == "styleName"){ //if runtime css swap or direct change of stylename
				
				var classSelector:Object = StyleManager.getStyleDeclaration(className);
				if(classSelector != null){
					applyProperties(classSelector, ["width", "height", "percentWidth", "percentHeight", "x", "y", "visible", "direction"]);
				}
				
				var dotSelector:Object = StyleManager.getStyleDeclaration("." + styleName);
				if(dotSelector != null){
					applyProperties(dotSelector, ["width", "height", "percentWidth", "percentHeight", "x", "y", "visible", "direction"]);
				}
			}
		}
		private function applyProperties(styleObj:Object, arr:Array):void
		{
			for each (var item:String in arr){
				var prop:Object = styleObj.getStyle(item);
				if(prop != null) this[item] = prop;
			}
		}
		
		override protected function createChildren():void 
		{
			super.createChildren();
		
			var whiteBox:DisplayObject = rawChildren.getChildByName("whiteBox");
			if(whiteBox)
				rawChildren.removeChild(whiteBox);
				//whiteBox.alpha=0.15;
		}
		override public function validateDisplayList():void 
		{
			super.validateDisplayList();
			
			var whiteBox:DisplayObject = rawChildren.getChildByName("whiteBox");
			if(whiteBox)
				rawChildren.removeChild(whiteBox);
				//whiteBox.alpha=0.15;
		}
	}
}
