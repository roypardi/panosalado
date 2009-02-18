package commercial.flexinterfaces.elements
{
	import commercial.flexinterfaces.elements.PanoSaladoEnhancedButton;
	import flash.events.*;
	
	public class PanoSaladoPreviousButton extends PanoSaladoEnhancedButton
	{
		protected var spacesList:XMLList;
		
		protected var previewsList:XMLList;
		
		internal var __len:int;
		
		public function PanoSaladoPreviousButton()
		{
			super();
			
			
			
			styleName = 'PanoSaladoPreviousButton';
		}
		
		protected function psClickHandler(e:MouseEvent):void
		{
			// code to go to previous space
			
			var previousSpace:String = getPreviousSpace();
			
			if ( previewsList.(@id == previousSpace+'.preview') != undefined)
				previousSpace = previousSpace+'.preview'
			
			
			panoSaladoExecute('loadSpace:'+previousSpace);
		}
		
		protected function psNextPrevOverHandler(e:MouseEvent):void
		{
			var previousSpaceLabel:String = getPreviousSpaceLabel();
					
			panoSaladoToolTip =  previousSpaceLabel || "Previous";
		}
		
		private function getPreviousSpace():String
		{
			var currentSpace:String = panoSalado.currentSpace;
			
			var idxOfdotPreview:int = currentSpace.search(/\.preview$/);
			if ( idxOfdotPreview > -1)
				currentSpace = currentSpace.substring( 0,idxOfdotPreview );
			
			for (var i:int = 0; i < __len; i++)
			{
				if (currentSpace == spacesList.@id[i])
					break;
			}
			
			var indexOfPrevious:int = i-1; 
			
			if ( indexOfPrevious < 0 )
				indexOfPrevious = __len -1; 
			
			var previousSpace:String = spacesList.@id[indexOfPrevious];
			
			return previousSpace;
		}
		
		override protected function stageReady(e:Event):void
		{
			super.stageReady(e);
			
			var foreignXML:XML = moduleLoader.xmlByName["PanoSalado"] as XML;
			
			spacesList = foreignXML.spaces.space.( @id.search(/\.preview$/) == -1 );
			
			previewsList = foreignXML.spaces.space.( @id.search(/\.preview$/) > -1 );
			
			__len = spacesList.length();
			
			if (__len > 1) {
				addEventListener(MouseEvent.CLICK, psClickHandler, false, 0, true);
				addEventListener(MouseEvent.MOUSE_OVER, psNextPrevOverHandler, false, 0, true);
			} else {
				enabled = false;
			}
			//toolTip =  settings.PanoSaladoPreviousButton.@toolTip || "Previous";
			//label = settings.PanoSaladoPreviousButton.@label || "Previous";
		}
		
		private function getPreviousSpaceLabel():String
		{
			var currentSpace:String = panoSalado.currentSpace;
			
			var idxOfdotPreview:int = currentSpace.search(/\.preview$/);
			if ( idxOfdotPreview > -1)
				currentSpace = currentSpace.substring( 0,idxOfdotPreview );
			
			for (var i:int = 0; i < __len; i++)
			{
				if (currentSpace == spacesList.@id[i])
					break;
			}
			
			var indexOfPrevious:int = i-1; 
			
			if ( indexOfPrevious < 0 )
				indexOfPrevious = __len -1; 
			
			var previousSpaceLabel:String = spacesList.@label[indexOfPrevious];
			
			return previousSpaceLabel;
		}
	}
}