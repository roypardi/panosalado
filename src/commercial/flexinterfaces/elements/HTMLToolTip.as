package commercial.flexinterfaces.elements
{

import flash.display.DisplayObject;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import mx.core.EdgeMetrics;
import mx.core.IFlexDisplayObject;
import mx.core.IFlexModuleFactory;
import mx.core.IFontContextComponent;
import mx.core.IRectangularBorder;
import mx.core.IToolTip;
import mx.core.IUITextField;
import mx.core.UIComponent;
import mx.core.UITextField;
import mx.styles.ISimpleStyleClient;

//--------------------------------------
//  Styles
//-------------------------------------- 

/*
    Note: ToolTip is affected by the following styles:

    backgroundColor
    borderColor
    borderStyle
    color
    fontFamily
    fontSize
    fontStyle
    fontWidth
    paddingBottom
    paddingLeft
    paddingRight
    paddingTop
    shadowColor (when borderStyle is "toolTip")
    textAlign
    textDecoration
*/

include "metadata/BorderStyles.as"
include "metadata/LeadingStyle.as"
include "metadata/PaddingStyles.as"
include "metadata/TextStyles.as"

/**
 *  The ToolTip control lets you provide helpful information to your users.
 *  When a user moves the mouse pointer over a graphical component, the ToolTip
 *  control pops up and displays text that provides information about the
 *  component.
 *  You can use ToolTips to guide users as they work with your application
 *  or customize the ToolTip controls to provide additional functionality.
 *
 *  @see mx.managers.ToolTipManager
 *  @see mx.styles.CSSStyleDeclaration
 */
public class HTMLToolTip extends UIComponent implements IToolTip, IFontContextComponent
{

    //--------------------------------------------------------------------------
    //
    //  Class properties
    //
    //--------------------------------------------------------------------------

    [Inspectable(category="Other")]
    
    /**
     *  Maximum width in pixels for new ToolTip controls.
     */
    public static var maxWidth:Number = 300;

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor.
     */
    public function HTMLToolTip()
    {
        super();

        // InteractiveObject variables.
        // Make the ToolTip invisible to the mouse so that it doesn't
        // interfere with the ToolTipManager's mouse-tracking.
        mouseEnabled = false;
        
//         HTMLToolTip
// 		{
// 			backgroundColor: #FFFFFF;
// 			backgroundAlpha: 0.95;
// 			tailColor: #919999;
// 			borderSkin: ClassReference("commercial.flexinterfaces.elements.TailToolTipBorder");
// 			borderStyle: "tailTipAbove";
// 			cornerRadius: 2;
// 			fontFamily: Arial Narrow Embedded;
// 			color: #333333;
// 			kerning: true;
// 			letterSpacing: 2;
// 			fontSize: 9;
// 			paddingBottom: 2;
// 			paddingLeft: 4;
// 			paddingRight: 4;
// 			paddingTop: 2;
// 			shadowColor: #000000;
// 		}
        
        
        // This needs to be placed somewhere central so that it will be overridden by run-time CSS.
//      setStyle( "borderSkin", TailToolTipBorder);
//      setStyle( "borderStyle", "tailTipAbove");
// 		setStyle( "backgroundColor", 0xFFFFFF);
// 		setStyle( "backgroundAlpha", 0.95);
// 		setStyle( "tailColor", 0x919999);
// 		setStyle( "cornerRadius", 2);
// 		setStyle( "color", 0x333333);
// 		setStyle( "fontSize", 9);
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
    
    /**
     *  The internal object that draws the border.
     */
    protected var border:IFlexDisplayObject;
    
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  borderMetrics
    //----------------------------------

    /**
     *  @private
     */
    private function get borderMetrics():EdgeMetrics
    {
        if (border is IRectangularBorder)
            return IRectangularBorder(border).borderMetrics;

        return EdgeMetrics.EMPTY;
    }

    //----------------------------------
    //  fontContext
    //----------------------------------
    
    /**
     *  @private 
     */
    public function get fontContext():IFlexModuleFactory
    {
        return moduleFactory;
    }

    /**
     *  @private
     */
    public function set fontContext(moduleFactory:IFlexModuleFactory):void
    {
        this.moduleFactory = moduleFactory;
    }
    
    //----------------------------------
    //  text
    //----------------------------------

    /**
     *  @private
     *  Storage for the text property.
     */
    private var _text:String;

    /**
     *  @private
     */
    private var textChanged:Boolean;

    /**
     *  The text displayed by the ToolTip.
     *
     *  @default null
     */
    public function get text():String
    {
        return _text;
    }

    /**
     *  @private
     */
    public function set text(value:String):void
    {
        _text = value;
        textChanged = true;

        invalidateProperties();
        invalidateSize();
        invalidateDisplayList();
    }

    //----------------------------------
    //  textField
    //----------------------------------

    /**
     *  The internal UITextField that renders the text of this ToolTip.
     */
    protected var textField:IUITextField;

    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    override protected function createChildren():void
    {
        super.createChildren();

        // Create the border/background.
        if (!border)
        {
            var borderClass:Class = getStyle("borderSkin");
            border = new borderClass();
            if (border is ISimpleStyleClient)
                ISimpleStyleClient(border).styleName = this;
            addChild(DisplayObject(border));
        }

        // Create the TextField that displays the tooltip text.
        createTextField(-1);
    }

    /**
     *  @private
     */
    override protected function commitProperties():void
    {
        super.commitProperties();

        // if the font changed and we already created the label, we will need to 
        // destory it so it can be re-created, possibly in a different swf context.
        if (hasFontContextChanged() && textField != null)
        {
            var index:int = getChildIndex(DisplayObject(textField));
            removeTextField();
            createTextField(index);
            invalidateSize();
            textChanged = true;
        }

        if (textChanged)
        {
            // In general, we want the ToolTip style to be applied.
            // However, we don't want leftMargin and rightMargin
            // of the TextField's TextFormat to be set to the
            // paddingLeft and paddingRight of the ToolTip style.
            // We want these styles to affect the space between the
            // TextField and the border, but not the space within
            // the TextField.
//             var textFormat:TextFormat = textField.getTextFormat();
//             textFormat.leftMargin = 0;
//             textFormat.rightMargin = 0;
//             textField.defaultTextFormat = textFormat;

            textField.htmlText = _text;
            textChanged = false;
        }
    }

    /**
     *  @private
     */
    override protected function measure():void
    {
        super.measure();

        var bm:EdgeMetrics = borderMetrics;

        var leftInset:Number = bm.left + getStyle("paddingLeft");
        var topInset:Number = bm.top + getStyle("paddingTop");
        var rightInset:Number = bm.right + getStyle("paddingRight");
        var bottomInset:Number = bm.bottom + getStyle("paddingBottom");

        var widthSlop:Number = leftInset + rightInset;
        var heightSlop:Number = topInset + bottomInset;

        textField.wordWrap = false;

        if (textField.textWidth + widthSlop > HTMLToolTip.maxWidth)
        {
            textField.width = HTMLToolTip.maxWidth - widthSlop;
            textField.wordWrap = true;
        }

        measuredWidth = textField.width + widthSlop;
        measuredHeight = textField.height + heightSlop;
    }

    /**
     *  @private
     */
    override protected function updateDisplayList(unscaledWidth:Number,
                                                  unscaledHeight:Number):void
    {
        super.updateDisplayList(unscaledWidth, unscaledHeight);

        var bm:EdgeMetrics = borderMetrics;

        var leftInset:Number = bm.left + getStyle("paddingLeft");
        var topInset:Number = bm.top + getStyle("paddingTop");
        var rightInset:Number = bm.right + getStyle("paddingRight");
        var bottomInset:Number = bm.bottom + getStyle("paddingBottom");

        var widthSlop:Number = leftInset + rightInset;
        var heightSlop:Number = topInset + bottomInset;

        border.setActualSize(unscaledWidth, unscaledHeight);

        textField.move(leftInset, topInset);
        textField.setActualSize(unscaledWidth - widthSlop, unscaledHeight - heightSlop);
    }

    /**
     *  @private
     */
    override public function styleChanged(styleProp:String):void
    {
        // This will take care of doing invalidateSize() if styleProp
        // is "styleName" or a registered layout style such as "borderStyle".
        super.styleChanged(styleProp);

        // However, if the borderStyle changes from "errorTipAbove" to
        // "errorTipBelow" or vice versa, the measured size won't change.
        // (The pointy part of the skin simply changes from the bottom
        // to the top or vice versa.) This means that the LayoutManager
        // won't call updateDisplayList() because the size hasn't changed.
        // But the TextField has to be repositioned, so we need to
        // invalidate the layout as well as the size.
        if (styleProp == "borderStyle" ||
            styleProp == "styleName" ||
            styleProp == null)
        {
            invalidateDisplayList();
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     *  Creates the text field child and adds it as a child of this component.
     * 
     *  @param childIndex The index of where to add the child.
     *  If -1, the text field is appended to the end of the list.
     */
    protected function createTextField(childIndex:int):void
    {
        if (!textField)
        {
            textField = IUITextField(createInFontContext(UITextField));

            textField.autoSize = TextFieldAutoSize.LEFT;
            textField.mouseEnabled = false;
            textField.multiline = true;
            textField.selectable = false;
            textField.wordWrap = false;
            textField.styleName = this;
            
            if (childIndex == -1)
                addChild(DisplayObject(textField));
            else 
                addChildAt(DisplayObject(textField), childIndex);
        }
    }

    /**
     *  @private
     *  Removes the text field from this component.
     */
    protected function removeTextField():void
    {
        if (textField)
        {
            removeChild(DisplayObject(textField));
            textField = null;
        }
    }
    

    /**
     *  @private
     */
    protected function getTextField():IUITextField
    {
        return textField;
    }
}

}
