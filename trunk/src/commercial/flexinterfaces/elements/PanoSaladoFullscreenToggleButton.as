package commercial.flexinterfaces.elements
{
	import commercial.flexinterfaces.elements.PanoSaladoEnhancedButton;
	import flash.events.*;
	
	public class PanoSaladoFullscreenToggleButton extends PanoSaladoEnhancedButton
	{
		
		public function PanoSaladoFullscreenToggleButton()
		{
			super();
			
			styleName="PanoSaladoFullscreenToggleButton";
			toggle=true;
			
			addEventListener(MouseEvent.CLICK, interactionHandler, false, 0, true)
		}
		
		override protected function stageReady(e:Event):void
		{
			super.stageReady(e);
			
			panoSaladoToolTip =  settings.PanoSaladoFullscreenToggleButton.@toolTip || "Toggle Full Screen Display";
			//label = settings.panoSaladoFullscreenToggleButton.@label || "Full Screen";
			
			moduleLoader.addEventListener(BroadcastEvent.ENTER_FULLSCREEN, setSelected, false, 0, true);
			
			moduleLoader.addEventListener(BroadcastEvent.EXIT_FULLSCREEN, clearSelected, false, 0, true);
		}
		
		protected function interactionHandler(e:MouseEvent):void
		{
			e.stopImmediatePropagation();
			
			panoSaladoExecute( "toggleFullscreen" );
		}
		
		protected function setSelected(e:Event):void
		{
			selected = true;
		}
		
		protected function clearSelected(e:Event):void
		{
			selected = false;
		}
	}
}
