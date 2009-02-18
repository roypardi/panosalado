////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2005-2006 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package commercial.flexinterfaces.elements
{

import flash.display.Graphics;
import flash.filters.DropShadowFilter;
import mx.core.EdgeMetrics;
import mx.graphics.RectangularDropShadow;
import mx.skins.RectangularBorder;

/**
 *  The skin for a ToolTip.
 */
public class TailToolTipBorder extends RectangularBorder
{

	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

	/**
	 *  Constructor.
	 */
	public function TailToolTipBorder() 
	{
		super(); 
	}

	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 */
	private var dropShadow:RectangularDropShadow;
	
	//--------------------------------------------------------------------------
	//
	//  Overridden properties
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  borderMetrics
	//----------------------------------

	/**
	 *  @private
	 *  Storage for the borderMetrics property.
	 */
	private var _borderMetrics:EdgeMetrics;

	/**
	 *  @private
	 */
	override public function get borderMetrics():EdgeMetrics
	{		
		if (_borderMetrics)
			return _borderMetrics;
			
		var borderStyle:String = getStyle("borderStyle");
		switch (borderStyle)
		{
			case "tailTipRight":
			{
 				_borderMetrics = new EdgeMetrics(15, 1, 3, 3);
				break;
			}
			
			case "tailTipAbove":
			{
 				_borderMetrics = new EdgeMetrics(3, 1, 3, 15);
 				break;
			}
		
			case "tailTipBelow":
			{
 				_borderMetrics = new EdgeMetrics(3, 13, 3, 3);
 				break;
			}
			
 			default: // "toolTip"
			{
				_borderMetrics = new EdgeMetrics(3, 1, 3, 3);
 				break;
			}
 		}
		
		return _borderMetrics;
	}

	//--------------------------------------------------------------------------
	//
	//  Overridden methods
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 *  If borderStyle may have changed, clear the cached border metrics.
	 */
	override public function styleChanged(styleProp:String):void
	{
		if (styleProp == "borderStyle" ||
			styleProp == "styleName" ||
			styleProp == null)
		{
			_borderMetrics = null;
		}
		
		invalidateDisplayList();
	}

	/**
	 *  @private
	 *  Draw the background and border.
	 */
	override protected function updateDisplayList(w:Number, h:Number):void
	{	
		super.updateDisplayList(w, h);

		var borderStyle:String = getStyle("borderStyle");
		var backgroundColor:uint = getStyle("backgroundColor");
		var backgroundAlpha:Number= getStyle("backgroundAlpha");
		var tailColor:uint = getStyle("tailColor");
		var cornerRadius:Number = getStyle("cornerRadius");
		var shadowColor:uint = getStyle("shadowColor");
		var shadowAlpha:Number = 0.1;

		var g:Graphics = graphics;
		g.clear();
		
		filters = [];
		
		switch (borderStyle)
		{ 
			case "taillessTip":
			{ 
				// face
				drawRoundRect(
					3, 1, w - 6, h - 4, cornerRadius,
					backgroundColor, backgroundAlpha) 
				
				if (!dropShadow)
					dropShadow = new RectangularDropShadow();

				dropShadow.distance = 3;
				dropShadow.angle = 90;
				dropShadow.color = 0;
				dropShadow.alpha = 0.4;

				dropShadow.tlRadius = cornerRadius + 2;
				dropShadow.trRadius = cornerRadius + 2;
				dropShadow.blRadius = cornerRadius + 2;
				dropShadow.brRadius = cornerRadius + 2;

				dropShadow.drawShadow(graphics, 3, 0, w - 6, h - 4);

				break;
			}

			case "tailTipAbove":
			{ 
				// border 
				drawRoundRect(
					0, 0, w, h - 13, 3,
					backgroundColor, backgroundAlpha); 

				// bottom pointer 
				g.beginFill(tailColor, backgroundAlpha);
				g.moveTo(9, h - 13);
				g.lineTo(15, h - 2);
				g.lineTo(21, h - 13);
				g.moveTo(9, h - 13);
				g.endFill();

				filters = [ new DropShadowFilter(2, 90, 0, 0.4) ];
				break;
			}

			case "tailTipBelow":
			{ 
				// border 
				drawRoundRect(
					0, 11, w, h - 13, 3,
					backgroundColor, backgroundAlpha); 

				// top pointer 
				g.beginFill(tailColor, backgroundAlpha);
				g.moveTo(9, 11);
				g.lineTo(15, 0);
				g.lineTo(21, 11);
				g.moveTo(10, 11);
				g.endFill();
				
				filters = [ new DropShadowFilter(2, 90, 0, 0.4) ];
				break;
			}
			
			case "tailTipAboveLeft":
			{ 
				// border 
				drawRoundRect(
					0, 0, w, h, 3,
					backgroundColor, backgroundAlpha);

				// left pointer 
				g.beginFill(tailColor, backgroundAlpha);
				g.moveTo(w - 3, h);
				g.lineTo(w + 1, h + 11);
				g.lineTo(w - 15, h);
				g.moveTo(w - 3, h);
				g.endFill();
				
				filters = [ new DropShadowFilter(2, 90, 0, 0.4) ];
				break;
			}
			case "tailTipBelowLeft":
			{ 
				// border 
				drawRoundRect(
					0, 0, w, h, 3,
					backgroundColor, backgroundAlpha); 

				// top pointer 
				g.beginFill(tailColor, backgroundAlpha);
				g.moveTo(w - 3, 0);
				g.lineTo(w + 1, -11);
				g.lineTo(w -15, 0);
				g.moveTo(w - 3, 0);
				g.endFill();
				
				filters = [ new DropShadowFilter(2, 90, 0, 0.4) ];
				break;
			}
		}
	}
}

}
