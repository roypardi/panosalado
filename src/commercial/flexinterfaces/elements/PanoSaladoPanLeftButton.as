package commercial.flexinterfaces.elements
{
	import commercial.flexinterfaces.elements.PanoSaladoEnhancedButton;
	import flash.events.*;
	
	public class PanoSaladoPanLeftButton extends PanoSaladoEnhancedButton
	{
		
		public function PanoSaladoPanLeftButton()
		{
			super();
			
			styleName="PanoSaladoPanLeftButton";
			
			addEventListener(MouseEvent.MOUSE_DOWN, interactionHandler, false, 0, true);
			addEventListener(MouseEvent.MOUSE_UP, interactionHandler, false, 0, true);
		}
		
		override protected function stageReady(e:Event):void
		{
			super.stageReady(e);
			
			panoSaladoToolTip =  settings.PanoSaladoPanLeftButton.@toolTip || "Pan Left";

			//label = settings.panoSaladoPanLeftButton.@label || "◄Left";
		}
		
		private function interactionHandler(e:MouseEvent):void
		{
			e.stopImmediatePropagation();
			
			if (e.type == MouseEvent.MOUSE_DOWN)
			{
				panoSaladoExecute( "keyDown:left" );
				addEventListener(MouseEvent.MOUSE_OUT, interactionHandler, false, 0, true);
			}
			else if (e.type == MouseEvent.MOUSE_UP)
			{
				panoSaladoExecute( "keyUp:left" );
				removeEventListener(MouseEvent.MOUSE_OUT, interactionHandler);
			}
			else if (e.type == MouseEvent.MOUSE_OUT)
			{
				panoSaladoExecute( "keyUp:left" );
				removeEventListener(MouseEvent.MOUSE_OUT, interactionHandler);
			}
		}
	}
}