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

import mx.containers.BoxDirection;
import mx.controls.scrollClasses.ScrollBar;
import mx.core.Container;
import mx.core.EdgeMetrics;
import mx.core.IUIComponent;
import mx.core.ScrollPolicy;
import mx.containers.utilityClasses.Layout;
import mx.containers.utilityClasses.Flex;
import mx.styles.StyleManager;
import mx.core.UIComponent;

import flash.display.DisplayObject;

//[ExcludeClass]

/**
 *  @private
 *  The BoxLayout class is for internal use only.
 */
public class CSSWeightBoxLayout extends Layout
{

	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

	/**
	 *  Constructor.
	 */
	public function CSSWeightBoxLayout()
	{
		super();
	}

	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  direction
	//----------------------------------

	/**
	 *  @private
	 */
	public var direction:String = BoxDirection.VERTICAL;

	//--------------------------------------------------------------------------
	//
	//  Overridden methods
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 *  Measure container as per Box layout rules.
	 */
	override public function measure():void
	{
		var target:Container = super.target;

		var isVertical:Boolean = isVertical();

		var minWidth:Number = 0;
		var minHeight:Number = 0;

		var preferredWidth:Number = 0;
		var preferredHeight:Number = 0;

		var n:int = target.numChildren;
		var numChildrenWithOwnSpace:int = n;
		for (var i:int = 0; i < n; i++)
		{
			var child:IUIComponent = IUIComponent(target.getChildAt(i));

			if (!child.includeInLayout)
			{
				numChildrenWithOwnSpace--;
				continue;
			}

			var wPref:Number = child.getExplicitOrMeasuredWidth();
			var hPref:Number = child.getExplicitOrMeasuredHeight();

			if (isVertical)
			{
				minWidth = Math.max(!isNaN(child.percentWidth) ?
					child.minWidth : wPref, minWidth);

				preferredWidth = Math.max(wPref, preferredWidth);

				minHeight += !isNaN(child.percentHeight) ?
					child.minHeight : hPref;

				preferredHeight += hPref;

			}
			else
			{
				minWidth += !isNaN(child.percentWidth) ?
					child.minWidth : wPref;

				preferredWidth += wPref;

				minHeight = Math.max(!isNaN(child.percentHeight) ?
					child.minHeight : hPref, minHeight);

				preferredHeight = Math.max(hPref, preferredHeight);

			}
		}

		var wPadding:Number = widthPadding(numChildrenWithOwnSpace);
		var hPadding:Number = heightPadding(numChildrenWithOwnSpace);

		target.measuredMinWidth = minWidth + wPadding;
		target.measuredMinHeight = minHeight + hPadding;

		target.measuredWidth = preferredWidth + wPadding;
		target.measuredHeight = preferredHeight + hPadding;
	}

	
	/**
	 *  @private
	 *  Lay out children as per Box layout rules.
	 */
	override public function updateDisplayList(unscaledWidth:Number,
											   unscaledHeight:Number):void
	{
		var target:Container = super.target;

		var n:int = target.numChildren;
		if (n == 0)
			return;

		var vm:EdgeMetrics = target.viewMetricsAndPadding;

		var paddingLeft:Number = target.getStyle("paddingLeft");
		var paddingTop:Number = target.getStyle("paddingTop");

		var horizontalAlign:Number = getHorizontalAlignValue();
		var verticalAlign:Number = getVerticalAlignValue();

		var mw:Number = target.scaleX > 0 && target.scaleX != 1 ?
						target.minWidth / Math.abs(target.scaleX) :
						target.minWidth;
		var mh:Number = target.scaleY > 0 && target.scaleY != 1 ?
						target.minHeight / Math.abs(target.scaleY) :
						target.minHeight;

		var w:Number = Math.max(unscaledWidth, mw) - vm.right - vm.left;
		var h:Number = Math.max(unscaledHeight, mh) - vm.bottom - vm.top;

		var theHorizontalScrollBar:ScrollBar = target.horizontalScrollBar;
		var theVerticalScrollBar:ScrollBar = target.verticalScrollBar;

		var gap:Number;
		var numChildrenWithOwnSpace:int;
		var excessSpace:Number;
		var top:Number;
		var left:Number;
		var i:int;
		var obj:IUIComponent;

		if (n == 1)
		{
			// This is an optimized code path for the case where there's one
			// child. This case is especially common when the Box is really
			// a GridItem. This code path works for both horizontal and
			// vertical layout.

			var child:IUIComponent = IUIComponent(target.getChildAt(0));

			var percentWidth:Number = child.percentWidth;
			var percentHeight:Number = child.percentHeight;

			var width:Number;
			if (percentWidth)
			{
				width = Math.max(child.minWidth,
					Math.min(child.maxWidth,
					((percentWidth >= 100) ? w : (w * percentWidth / 100))));
			}
			else
			{
				width = child.getExplicitOrMeasuredWidth();
			}

			var height:Number
			if (percentHeight)
			{
				height = Math.max(child.minHeight,
					Math.min(child.maxHeight,
					((percentHeight >= 100) ? h : (h * percentHeight / 100))));
			}
			else
			{
				height = child.getExplicitOrMeasuredHeight();
			}

			// if scaled and zoom is playing, best to let the sizes be non-integer
			if (child.scaleX == 1 && child.scaleY == 1)
				child.setActualSize(Math.floor(width), Math.floor(height));
			else
				child.setActualSize(width, height);

			// Ignore scrollbar sizes for child alignment purpose.
			if (theVerticalScrollBar != null &&
				target.verticalScrollPolicy == ScrollPolicy.AUTO)
			{
				w += theVerticalScrollBar.minWidth;
			}
			if (theHorizontalScrollBar != null &&
				target.horizontalScrollPolicy == ScrollPolicy.AUTO)
			{
				h += theHorizontalScrollBar.minHeight;
			}

			// Use the child's width and height because a Resize effect might
			// have changed the child's dimensions. Bug 146158.
			left = (w - child.width) * horizontalAlign + paddingLeft;
			top = (h - child.height) * verticalAlign + paddingTop;

			child.move(Math.floor(left), Math.floor(top));
		}

		else if (isVertical()) // VBOX
		{
			indexedWeights = populatedIndexedWeight();
			
			gap = target.getStyle("verticalGap");

			numChildrenWithOwnSpace = n;
			for (i = 0; i < n; i++)
			{
				if (!IUIComponent(target.getChildAt(i)).includeInLayout)
					numChildrenWithOwnSpace--;
			}

			// Stretch everything as needed, including widths.
			excessSpace = Flex.flexChildHeightsProportionally(
				target, h - (numChildrenWithOwnSpace - 1) * gap, w);

			// Ignore scrollbar sizes for child alignment purpose.
			if (theHorizontalScrollBar != null &&
				target.horizontalScrollPolicy == ScrollPolicy.AUTO)
			{
				excessSpace += theHorizontalScrollBar.minHeight;
			}
			if (theVerticalScrollBar != null &&
				target.verticalScrollPolicy == ScrollPolicy.AUTO)
			{
				w += theVerticalScrollBar.minWidth;
			}

			top = paddingTop + excessSpace * verticalAlign;

			for (i = 0; i < n; i++)
			{
				obj = IUIComponent(getChildByIndexedWeight(i));
				left = (w - obj.width) * horizontalAlign + paddingLeft;
				obj.move(Math.floor(left), Math.floor(top));
				if (obj.includeInLayout)
					top += obj.height + gap;
			}
			
			indexedWeights = null;
		}

		else  // HBOX
		{
			indexedWeights = populatedIndexedWeight();
			
			gap = target.getStyle("horizontalGap");

			numChildrenWithOwnSpace = n;
			for (i = 0; i < n; i++)
			{
				if (!IUIComponent(target.getChildAt(i)).includeInLayout)
					numChildrenWithOwnSpace--;
			}

			// stretch everything as needed including heights
			excessSpace = Flex.flexChildWidthsProportionally(
				target, w - (numChildrenWithOwnSpace - 1) * gap, h);

			// Ignore scrollbar sizes for child alignment purpose.
			if (theHorizontalScrollBar != null &&
				target.horizontalScrollPolicy == ScrollPolicy.AUTO)
			{
				h += theHorizontalScrollBar.minHeight;
			}
			if (theVerticalScrollBar != null &&
				target.verticalScrollPolicy == ScrollPolicy.AUTO)
			{
				excessSpace += theVerticalScrollBar.minWidth;
			}

			left = paddingLeft + excessSpace * horizontalAlign;

			for (i = 0; i < n; i++)
			{
				obj = IUIComponent(getChildByIndexedWeight(i));
				top = (h - obj.height) * verticalAlign + paddingTop;
				obj.move(Math.floor(left), Math.floor(top));
				if (obj.includeInLayout)
					left += obj.width + gap;
			}
			
			indexedWeights = null;
		}
	}

	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
	
	protected var indexedWeights:Array;
	
	protected function populatedIndexedWeight():Array
	{
		indexedWeights = new Array();
		
		var weight:Number = 0;
		var classNameWeight:Number;
		var styleNameWeight:Number;
		
		var positiveWeights:Array = new Array();
		var negativeWeights:Array = new Array();
		
		var internalArray:Array;
		
		var n:int = target.numChildren;
		for (var i:int = 0; i < n; i++)
		{
			var child:UIComponent = UIComponent(target.getChildAt(i));
			
			if ( !(child.includeInLayout) )
				continue;
			
			var classSelector:Object = StyleManager.getStyleDeclaration(child.className);
				
			if(classSelector != null)
			{
				classNameWeight = classSelector.getStyle("weight") as Number;
				if ( !isNaN(classNameWeight) )
				{
					weight = classNameWeight;
				}
			}
			
			if (child.styleName)
			{
				var dotSelector:Object = StyleManager.getStyleDeclaration("." + child.styleName);
				if(dotSelector != null)
				{
					styleNameWeight = dotSelector.getStyle("weight") as Number;
					if ( !isNaN(weight) )
					{
						weight = styleNameWeight;
					}
				}
			}
			
			internalArray = new Array();
			if (weight >= 0)
			{
				if (positiveWeights[weight] == null)
					positiveWeights[weight] = new Array();
				internalArray = positiveWeights[weight] as Array;
				internalArray.push( child );
			}
			else 
			{
				weight = -weight;
				if (negativeWeights[weight] == null)
					negativeWeights[weight] = new Array();
				internalArray = negativeWeights[weight] as Array;
				internalArray.push( child );
			}
		}
		
		var output:Array = new Array()
		var a:Object;
		var o:Object;
		
		var i2:int;
		var i3:int;
		var len2:int;
		var len3:int;
		
		len2 = negativeWeights.length - 1;
		for (i2 = len2; i2 >= 0; i2--)
		{ 
			a = negativeWeights[i2] as Array;
			if (a != null)
			{
				internalArray = (a as Array);
				
				len3 = internalArray.length;
				for (i3 = 0; i3 < len3; i3++)
				{ 
					o = internalArray[i3];
					output.push(o);
				}
			}
		}
		
		len2 = positiveWeights.length;
		for (i2 = 0; i2 < len2; i2++)
		{ 
			a = positiveWeights[i2] as Array;
			
			if (a != null)
			{
				internalArray = a as Array;
				
				len3 = internalArray.length;
				for (i3 = 0; i3 < len3; i3++)
				{ 
					o = internalArray[i3];
					output.push(o);
				}
			}
		}
		
		return output;
	}
	
	protected function getChildByIndexedWeight(index:int):DisplayObject
	{
		return indexedWeights[index] as DisplayObject;
	}
	
	/**
	 *  @private
	 */
	private function isVertical():Boolean
	{
		return direction != BoxDirection.HORIZONTAL;
	}

	/**
	 *  @private
	 */
	protected function widthPadding(numChildren:Number):Number
	{
		var vm:EdgeMetrics = target.viewMetricsAndPadding;
		var padding:Number = vm.left + vm.right;

		if (numChildren > 1 && isVertical() == false)
		{
			padding += target.getStyle("horizontalGap") *
					   (numChildren - 1);
		}

		return padding;
	}

	/**
	 *  @private
	 */
	protected function heightPadding(numChildren:Number):Number
	{
		var vm:EdgeMetrics = target.viewMetricsAndPadding;
		var padding:Number = vm.top + vm.bottom;

		if (numChildren > 1 && isVertical())
		{
			padding += target.getStyle("verticalGap") *
					   (numChildren - 1);
		}

		return padding;
	}

	/**
	 *  @private
	 *  Returns a numeric value for the align setting.
	 *  0 = left/top, 0.5 = center, 1 = right/bottom
	 */
	protected function getHorizontalAlignValue():Number
	{
		var horizontalAlign:String = target.getStyle("horizontalAlign");

		if (horizontalAlign == "center")
			return 0.5;

		else if (horizontalAlign == "right")
			return 1;

		// default = left
		return 0;
	}

	/**
	 *  @private
	 *  Returns a numeric value for the align setting.
	 *  0 = left/top, 0.5 = center, 1 = right/bottom
	 */
	protected function getVerticalAlignValue():Number
	{
		var verticalAlign:String = target.getStyle("verticalAlign");

		if (verticalAlign == "middle")
			return 0.5;

		else if (verticalAlign == "bottom")
			return 1;

		// default = top
		return 0;
	}
}

}
