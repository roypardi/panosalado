/**
 * @author Michael Rondinelli
 */ 

// __________________________________________________________________________ VIDEO MATERIAL

package com.eyesee360.materials
{
	import mx.controls.videoClasses.VideoPlayer;
    import mx.events.VideoEvent;
	import flash.display.DisplayObject;
	import flash.events.NetStatusEvent;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import flash.media.Video;
	import flash.net.NetStream;
	
	import org.papervision3d.materials.MovieMaterial;
	import org.papervision3d.core.render.draw.ITriangleDrawer;

	/*
	* The VideoMaterial class creates a texture from an existing Video instance and is for use with a Video and NetStream objects with an RTMP stream.
	* <p/>
	* The texture can be animated and/or transparent.
	* <p/>
	* Materials collects data about how objects appear when rendered.
	*/
	public class VideoPlayerMaterial extends MovieMaterial implements ITriangleDrawer
	{		
		// ______________________________________________________________________ PUBLIC
	
		/**
		 * The NetStream and Vdeo that are used as a texture.
		 */		
		public var player:VideoPlayer;
		
		
		// ______________________________________________________________________ NEW
	
		/**
		* The VideoPlayerMaterial class creates a texture from an existing Video instance.
		*
		* @param	player			A VideoPlayer that display the FLV file
		*/
		public function VideoPlayerMaterial ( player:VideoPlayer, precise:Boolean = false )
		{			
			// store the values
			this.player = player;
			animated = true;
			this.precise = precise;
			// init the material with a listener for the NS object 
			initMaterial ( player );
					
			super ( DisplayObject(player) );
		}
	

		// ______________________________________________________________________ INITIALISE
		
		/**
		 * Executes when the VideoMaterial is instantiated
		 */
		private function initMaterial ( player:VideoPlayer ):void
		{
			player.addEventListener ( VideoEvent.STATE_CHANGE, onPlayerStateChange );
		}
		

		// ______________________________________________________________________ UPDATE
	
		/**
		* Updates Video Bitmap
		*
		* Draws the current Video frame onto bitmap.
		*/	
		public override function updateBitmap ():void
		{
			try
			{
				// copies the scale properties of the video
				if (this.player.scaleX != 1 || this.player.scaleY != 1) {
			    }
				
				var myMatrix:Matrix = new Matrix();
				myMatrix.scale( this.player.scaleX, this.player.scaleY );
				
				// Fills the rectangle with a background color
				this.bitmap.fillRect ( this.bitmap.rect, this.fillColor );

				// Due to security reasons the BitmapData cannot access RTMP content like a NetStream using a FMS server.
				// The next three lines are a simple but effective workaround to get pass Flash its security sandbox.
				this.bitmap.draw( this.player, myMatrix, this.player.transform.colorTransform );
			}catch(e:Error)
			{
				//
			}
		}
		
		
		// ______________________________________________________________________ STREAM STATUS
	
		/**
		* Executes when the status of the NetStream object changes
		*
		* @param Event that invoked the handler
		*/			
		private function onPlayerStateChange ( event:VideoEvent ):void
		{
			switch ( event.state )
			{
				case VideoPlayer.PLAYING:
				    animated = true;
				    break;
				default:
					animated = false;
					break;
			}			
		}	
		
		// ______________________________________________________________________ TO STRING
	
		/**
		* Returns a string value representing the material properties in the specified VideoMaterial object.
		*
		* @return	A string.
		*/
		public override function toString():String
		{
			return 'Texture:' + this.texture;
		}
		
		
	}
}