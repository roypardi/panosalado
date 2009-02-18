package commercial.flexinterfaces.elements
{

	import flash.net.*;
	import flash.events.*;
	
	import zephyr.utils.StringTo;
	
	public class PanoSaladoNavigateToURLToggleButton extends PanoSaladoEnhancedButton
	{

		public var unselectedURL:String = "";
		public var selectedURL:String = "";
		
		private var _isSelected:Boolean = false;
		
		public function PanoSaladoNavigateToURLToggleButton()
		{
			super();
			
			styleName="PanoSaladoNavigateToURLToggleButton";
			toggle=true;
			
			addEventListener(MouseEvent.CLICK, interactionHandler, false, 0, true)
			
		}
		
		override protected function stageReady(e:Event):void
		{
			super.stageReady(e);
						
			unselectedURL = settings.panoSaladoNavigateToURLToggleButton.@unselectedURL || unselectedURL;
			
			selectedURL = settings.panoSaladoNavigateToURLToggleButton.@selectedURL || selectedURL;
			
			_isSelected = StringTo.bool(settings.panoSaladoNavigateToURLToggleButton.@selected) || false;
			
			selected = _isSelected;
			
			if (_isSelected)
			{
				panoSaladoToolTip = "Go to "+settings.panoSaladoNavigateToURLToggleButton.@selectedToolTip || "Go to site";
			}
			else
			{
				panoSaladoToolTip = "Go to "+settings.panoSaladoNavigateToURLToggleButton.@unselectedToolTip || "Go to site";
			}
			
		}
		
		
		private function interactionHandler(e:MouseEvent):void
		{
			e.stopImmediatePropagation();
			
			if (_isSelected)
			{trace( "unselected", unselectedURL);
				navigateToURL( new URLRequest(unselectedURL), "_blank" );
				_isSelected = true;
				toolTip = settings.panoSaladoNavigateToURLToggleButton.@selectedToolTip || "Navigate To...";
			}
				
			else
			{ trace( "selected", selectedURL);
				navigateToURL(new URLRequest(selectedURL), "_blank");
				_isSelected = false;
				toolTip = settings.panoSaladoNavigateToURLToggleButton.@unselectedToolTip || "Navigate To...";
			}
		}
	}
}
