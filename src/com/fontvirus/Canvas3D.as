/*
           00XXXX                        XXXX00        
           00XXxx                        xxXX00        
           ee0000eeeeRR            RReeee0000ee        
                 xxXX00            00XXxx              
                 XXXX00            00XXXX              
           eexxXXXXXXXXXXXXXXXXXXXXXXXXXXXXxxee        
           00XXXXeeee00XXXXXXXXXXXX00eeeeXXXX00        
       xxXXXXXXXX    00XXXXXXXXXXXX00    XXXXXXXXxx    
       XXXXXXXXXX    00XXXXXXXXXXXX00    XXXXXXXXXX    
   eeeeXXXXXXXXXXeeeeRRXXXXXXXXXXXXRReeeeXXXXXXXXXXeeee
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   XXXX""""RRXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXRR""""XXXX
   XXXX    00XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX00    XXXX
   XXXX    00XXXX""""""""""""""""""""""""XXXX00    XXXX
   XXRR    00XXXX                        XXXX00    RRXX
   eeXX    00xxxxRR000000ee    ee000000RRxxxx00    XXee
                 xxXXXXXXxx    xxXXXXXXxx                            
                 XXXXXXXXXX    XXXXXXXXXX                       
    _____             __        .__
  _/ ____\___   _____/  |____  _|__|______  __ __ ______
  \   __/  _ \ /    \   __\  \/ /  \_  __ \|  |  |  ___/
   |  |(  <_> )   |  \  |  \   /|  ||  | \/|  |  |___ \
   |__| \____/|___|  /__|   \_/ |__||__|  /\____/____  >
                   \/                     \/         \/
            .  .  f l e x  .  c a n v a s  .  . 
														*/
package com.fontvirus
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;	

	public class Canvas3D extends UIComponent
	{	
		private var paperSprite:Sprite;
		private var backgroundSprite:Sprite;
		private var clipRect:Rectangle;
		
		private var _backgroundColor:uint = 0x000000;
		private var _backgroundAlpha:Number = 1;
		
		public function Canvas3D()
		{
			super();
			init();
		}
		
		private function init():void
		{
			clipRect = new Rectangle();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			backgroundSprite = new Sprite();
			backgroundSprite.cacheAsBitmap = true;
			
			paperSprite = new Sprite();
			
			addChild(backgroundSprite);
			addChild(paperSprite);		
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);		
			drawBackground();
			
			var hw:Number = unscaledWidth/2;
			var hh:Number = unscaledHeight/2;
			
			paperSprite.x = hw;
			paperSprite.y = hh;
			
			clipRect.x = 0;
			clipRect.y = 0;
			clipRect.width = unscaledWidth;
			clipRect.height = unscaledHeight;
			
			scrollRect = clipRect;
		}
		
		protected function drawBackground():void
		{
			if(backgroundSprite){
				var g:Graphics = backgroundSprite.graphics;
				g.clear();
				g.beginFill(backgroundColor, _backgroundAlpha);
				g.drawRect(0,0,unscaledWidth,unscaledHeight);
				g.endFill();
			}
		}
		
		public function set backgroundColor(bgColor:uint):void
		{
			_backgroundColor = bgColor;	
			drawBackground();
		}
		
		public function get backgroundColor():uint
		{
			return _backgroundColor;	
		}
		
		public function set backgroundAlpha(alpha:Number):void
		{
			_backgroundAlpha = alpha;
		}
		
		public function get backgroundAlpha():Number
		{
			return _backgroundAlpha;	
		}
		
		public function get canvas():Sprite
		{
			return paperSprite;
		}
	
	}
}