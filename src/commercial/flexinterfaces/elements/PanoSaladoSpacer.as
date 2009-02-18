package commercial.flexinterfaces.elements
{
	import mx.controls.Spacer;
	import flash.utils.getDefinitionByName;
	//import commercial.flexlib.skins.EnhancedButtonSkin;
	import mx.styles.StyleManager;
	
	public class PanoSaladoSpacer extends Spacer
	{
		//internal var enhancedButtonSkin:EnhancedButtonSkin = new EnhancedButtonSkin();
		
		public function PanoSaladoSpacer()
		{
			super();
			
			styleName="PanoSaladoSpacer";
			//setStyle( "skin", getDefinitionByName("commercial.flexlib.skins.EnhancedButtonSkin") as Class );
		}
		
		//http://www.craftymind.com/2008/03/31/hacking-width-and-height-properties-into-flexs-css-model/
		override public function styleChanged(styleProp:String):void
		{
			super.styleChanged(styleProp);
			
			if(!styleProp || styleProp == "styleName"){ //if runtime css swap or direct change of stylename
				var dotSelector:Object = StyleManager.getStyleDeclaration("." + styleName);
				if(dotSelector != null){
					applyProperties(dotSelector, ["width", "height", "percentWidth", "percentHeight", "x", "y", "visible"]);
				}
				var classSelector:Object = StyleManager.getStyleDeclaration(className);
				if(classSelector != null){
					applyProperties(classSelector, ["width", "height", "percentWidth", "percentHeight", "x", "y", "visible"]);
				}
			}
		}
		private function applyProperties(styleObj:Object, arr:Array):void{
			for each (var item:String in arr){
				var prop:Object = styleObj.getStyle(item);
				if(prop != null) this[item] = prop;
			}
		}
	}
}