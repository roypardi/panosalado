package commercial.flexinterfaces.elements
{
	import commercial.flexinterfaces.elements.PanoSaladoEnhancedButton;
	import flash.events.*;
	
	public class PanoSaladoZoomOutButton extends PanoSaladoEnhancedButton
	{
		
		public function PanoSaladoZoomOutButton()
		{
			super();
			
			styleName="PanoSaladoZoomOutButton";

			addEventListener(MouseEvent.MOUSE_DOWN, interactionHandler, false, 0, true);
			addEventListener(MouseEvent.MOUSE_UP, interactionHandler, false, 0, true);
		}
		
		override protected function stageReady(e:Event):void
		{
			super.stageReady(e);
			
			panoSaladoToolTip =  settings.PanoSaladoZoomOutButton.@toolTip || "Zoom Out";
			//label = settings.panoSaladoZoomOutButton.@label || "Out";
		}
		
		private function interactionHandler(e:MouseEvent):void
		{
			e.stopImmediatePropagation();
			
			if (e.type == MouseEvent.MOUSE_DOWN)
			{
				panoSaladoExecute( "keyDown:control" );
				addEventListener(MouseEvent.MOUSE_OUT, interactionHandler, false, 0, true);
			}
			else if (e.type == MouseEvent.MOUSE_UP)
			{
				panoSaladoExecute( "keyUp:control" );
				removeEventListener(MouseEvent.MOUSE_OUT, interactionHandler);
			}
			else if (e.type == MouseEvent.MOUSE_OUT)
			{
				panoSaladoExecute( "keyUp:control" );
				removeEventListener(MouseEvent.MOUSE_OUT, interactionHandler);
			}
		}
	}
}