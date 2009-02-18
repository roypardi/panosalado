package org.papervision3d.materials {
	import org.papervision3d.Papervision3D;	import org.papervision3d.core.geom.renderables.Triangle3D;	import org.papervision3d.core.geom.renderables.Vertex3DInstance;	import org.papervision3d.core.log.PaperLogger;	import org.papervision3d.core.material.TriangleMaterial;	import org.papervision3d.core.proto.MaterialObject3D;	import org.papervision3d.core.render.command.RenderTriangle;	import org.papervision3d.core.render.data.RenderSessionData;	import org.papervision3d.core.render.draw.ITriangleDrawer;	import org.papervision3d.materials.utils.PrecisionMode;	import org.papervision3d.materials.utils.RenderRecStorage;		import flash.display.BitmapData;	import flash.display.Graphics;	import flash.geom.Matrix;	import flash.geom.Point;	import flash.geom.Rectangle;	import flash.utils.Dictionary;	
	/**
	* The BitmapMaterial class creates a texture from a BitmapData object.
	*
	* Materials collect data about how objects appear when rendered.
	*
	*/
	public class BitmapMaterial extends TriangleMaterial implements ITriangleDrawer
	{
		
		protected static const DEFAULT_FOCUS:Number = 200;
		protected static var hitRect:Rectangle = new Rectangle();
		
		
		protected var renderRecStorage:Array;
		protected var focus:Number = 200;
		protected var _precise:Boolean;
		protected var _precision:int = 8;
		protected var _perPixelPrecision:int = 8;
		public var minimumRenderSize:Number = 4;
		
		protected var _texture :Object;
		
		/**
		 * Indicates if mip mapping is forced.
		 */
		public static var AUTO_MIP_MAPPING :Boolean = false;

		/**
		 * Levels of mip mapping to force.
		 */
		public static var MIP_MAP_DEPTH :Number = 8;
		/**		 * Precision mode indicates how triangles are created for precise texture render.		 */		public var precisionMode:int = PrecisionMode.ORIGINAL;		
		public var uvMatrices:Dictionary = new Dictionary();
		
		/**
		* @private
		*/
		protected static var _triMatrix:Matrix = new Matrix();
		protected static var _triMap:Matrix;
		
		/**
		* @private
		*/
		protected static var _localMatrix:Matrix = new Matrix();
		
		/**
		* The BitmapMaterial class creates a texture from a BitmapData object.
		*
		* @param	asset				A BitmapData object.
		*/
		public function BitmapMaterial( asset:BitmapData=null, precise:Boolean = false)
		{
			// texture calls createBitmap. That's where all the init happens. This allows to reinit when changing texture. -C4RL05
			// if we have an asset passed in, this means we're the subclass, not the super.  Set the texture, let the fun begin.
			if( asset ) texture = asset;
			this.precise = precise;
			createRenderRecStorage();
		}
		
		protected function createRenderRecStorage():void
		{
			this.renderRecStorage = new Array();
			for(var a:int = 0; a<=100; a++){
				this.renderRecStorage[a] = new RenderRecStorage();
			}	
		}
		
		/**
		* Resets the mapping coordinates. Use when the texture has been resized.
		*/
		public function resetMapping():void
		{
			uvMatrices = new Dictionary();
		}
		
			
		//Local storage. Avoid var's in high usage functions.
		private var x0:Number;
		private var y0:Number;
		private var x1:Number;
		private var y1:Number;
		private var x2:Number;
		private var y2:Number;
		/**
		 *  drawTriangle
		 */
		override public function drawTriangle(tri:RenderTriangle, graphics:Graphics, renderSessionData:RenderSessionData, altBitmap:BitmapData = null, altUV:Matrix = null):void
		{
		//	trace("at drawing triangle???");
			_triMap = altUV ? altUV : (uvMatrices[tri] || transformUVRT(tri));
			if(!_precise || !_triMap){
				if( lineAlpha )
					graphics.lineStyle( lineThickness, lineColor, lineAlpha );
				if( bitmap )
				{
					
					x0 = tri.v0.x;
					y0 = tri.v0.y;
					x1 = tri.v1.x;
					y1 = tri.v1.y;
					x2 = tri.v2.x;
					y2 = tri.v2.y;
	
					_triMatrix.a = x1 - x0;
					_triMatrix.b = y1 - y0;
					_triMatrix.c = x2 - x0;
					_triMatrix.d = y2 - y0;
					_triMatrix.tx = x0;
					_triMatrix.ty = y0;
						
					_localMatrix.a = _triMap.a;
					_localMatrix.b = _triMap.b;
					_localMatrix.c = _triMap.c;
					_localMatrix.d = _triMap.d;
					_localMatrix.tx = _triMap.tx;
					_localMatrix.ty = _triMap.ty;
					_localMatrix.concat(_triMatrix);
					
					graphics.beginBitmapFill( altBitmap ? altBitmap : bitmap, _localMatrix, tiled, smooth);
				}
				graphics.moveTo( x0, y0 );
				graphics.lineTo( x1, y1 );
				graphics.lineTo( x2, y2 );
				graphics.lineTo( x0, y0 );
				if( bitmap )
					graphics.endFill();
				if( lineAlpha )
					graphics.lineStyle();
				renderSessionData.renderStatistics.triangles++;
			}else{
				if(bitmap){
					focus = renderSessionData.camera.focus;
					tempPreBmp = altBitmap ? altBitmap : bitmap;
					tempPreRSD = renderSessionData;
					tempPreGrp = graphics;
					cullRect = renderSessionData.viewPort.cullingRectangle;
					renderRec(_triMap, tri.v0, tri.v1, tri.v2, 0);	 
				}
			}
		}
		
		/**
		* Applies the updated UV texture mapping values to the triangle. This is required to speed up rendering.
		*
		*/
		public function transformUV(face3D:Triangle3D):Matrix
		{			
			if( ! face3D.uv )
			{
				PaperLogger.error( "MaterialObject3D: transformUV() uv not found!" );
			}
			else if( bitmap )
			{
				var uv :Array  = face3D.uv;
				
				var w  :Number = bitmap.width * maxU;
				var h  :Number = bitmap.height * maxV;
				var u0 :Number = w * face3D.uv0.u;
				var v0 :Number = h * ( 1 - face3D.uv0.v );
				var u1 :Number = w * face3D.uv1.u;
				var v1 :Number = h * ( 1 - face3D.uv1.v);
				var u2 :Number = w * face3D.uv2.u;
				var v2 :Number = h * ( 1 - face3D.uv2.v );
				
				// Fix perpendicular projections
				if( (u0 == u1 && v0 == v1) || (u0 == u2 && v0 == v2) )
				{
					u0 -= (u0 > 0.05)? 0.05 : -0.05;
					v0 -= (v0 > 0.07)? 0.07 : -0.07;
				}
				
				if( u2 == u1 && v2 == v1 )
				{
					u2 -= (u2 > 0.05)? 0.04 : -0.04;
					v2 -= (v2 > 0.06)? 0.06 : -0.06;
				}
				
				// Precalculate matrix & correct for mip mapping
				var at :Number = ( u1 - u0 );
				var bt :Number = ( v1 - v0 );
				var ct :Number = ( u2 - u0 );
				var dt :Number = ( v2 - v0 );
				
				var m :Matrix = new Matrix( at, bt, ct, dt, u0, v0 );
				// Need to mirror over X-axis when righthanded
				if(Papervision3D.useRIGHTHANDED)
				{
					m.scale(-1, 1);
					m.translate(w, 0);
				}
				m.invert();
				
				var mapping:Matrix = uvMatrices[face3D] = m.clone();
				mapping.a  = m.a;
				mapping.b  = m.b;
				mapping.c  = m.c;
				mapping.d  = m.d;
				mapping.tx = m.tx;
				mapping.ty = m.ty;
			}
			else PaperLogger.error( "MaterialObject3D: transformUV() material.bitmap not found!" );

			return mapping;
		}
		
		/**
		* Applies the updated UV texture mapping values to the triangle. This is required to speed up rendering.
		*
		*/
		public function transformUVRT(tri:RenderTriangle):Matrix
		{			
			if( bitmap )
			{
				//var uv :Array  = face3D.uv;
				
				var w  :Number = bitmap.width * maxU;
				var h  :Number = bitmap.height * maxV;
				var u0 :Number = w * tri.uv0.u;
				var v0 :Number = h * ( 1 - tri.uv0.v );
				var u1 :Number = w * tri.uv1.u;
				var v1 :Number = h * ( 1 - tri.uv1.v);
				var u2 :Number = w * tri.uv2.u;
				var v2 :Number = h * ( 1 - tri.uv2.v );
				
				// Fix perpendicular projections
				if( (u0 == u1 && v0 == v1) || (u0 == u2 && v0 == v2) )
				{
					u0 -= (u0 > 0.05)? 0.05 : -0.05;
					v0 -= (v0 > 0.07)? 0.07 : -0.07;
				}
				
				if( u2 == u1 && v2 == v1 )
				{
					u2 -= (u2 > 0.05)? 0.04 : -0.04;
					v2 -= (v2 > 0.06)? 0.06 : -0.06;
				}
				
				// Precalculate matrix & correct for mip mapping
				var at :Number = ( u1 - u0 );
				var bt :Number = ( v1 - v0 );
				var ct :Number = ( u2 - u0 );
				var dt :Number = ( v2 - v0 );
				
				var m :Matrix = new Matrix( at, bt, ct, dt, u0, v0 );
				// Need to mirror over X-axis when righthanded
				if(Papervision3D.useRIGHTHANDED)
				{
					m.scale(-1, 1);
					m.translate(w, 0);
				}
				m.invert();
				
				var mapping:Matrix = uvMatrices[tri] = m.clone();
				mapping.a  = m.a;
				mapping.b  = m.b;
				mapping.c  = m.c;
				mapping.d  = m.d;
				mapping.tx = m.tx;
				mapping.ty = m.ty;
			}
			else PaperLogger.error( "MaterialObject3D: transformUV() material.bitmap not found!" );

			return mapping;
		}
		
		
		protected var ax:Number;
		protected var ay:Number;
		protected var az:Number;
		protected var bx:Number;
		protected var by:Number;
		protected var bz:Number;
		protected var cx:Number;
		protected var cy:Number;
		protected var cz:Number;
		protected var faz:Number;
        protected var fbz:Number;
        protected var fcz:Number;
       	protected var mabz:Number;
        protected var mbcz:Number;
        protected var mcaz:Number;
        protected var mabx:Number;
        protected var maby:Number;
        protected var mbcx:Number;
        protected var mbcy:Number;
        protected var mcax:Number;
        protected var mcay:Number;
        protected var dabx:Number;
        protected var daby:Number;
        protected var dbcx:Number;
        protected var dbcy:Number;
        protected var dcax:Number;
        protected var dcay:Number;
        protected var dsab:Number;
        protected var dsbc:Number;
        protected var dsca:Number;
        protected var dmax:Number;
        protected var cullRect:Rectangle;
        
        protected var tempPreGrp:Graphics;
        protected var tempPreBmp:BitmapData;
        protected var tempPreRSD:RenderSessionData;		protected var tempTriangleMatrix:Matrix = new Matrix();
		private var a2:Number;
		private var b2:Number;
		private var c2:Number;
		private var d2:Number;

		private var dx:Number, dy:Number, d2ab:Number, d2bc:Number, d2ca:Number;private var emMapi:Matrix, v0i:Vertex3DInstance, v1i:Vertex3DInstance, v2i:Vertex3DInstance, indexi:Number;
        
        protected function renderRec(emMap:Matrix, v0:Vertex3DInstance, v1:Vertex3DInstance, v2:Vertex3DInstance, index:Number):void
        {
        	az = v0.z;
        	bz = v1.z;
        	cz = v2.z;
        	
        	//Cull if a vertex behind near.
            if((az <= 0) && (bz <= 0) && (cz <= 0))
                return;
        	
        	cx = v2.x;
        	cy = v2.y;
        	bx = v1.x;
        	by = v1.y;
        	ax = v0.x;
        	ay = v0.y;
        	
        	//Cull if outside of viewport.
        	if(cullRect){
	    		hitRect.x = (bx < ax ? (bx < cx ? bx : cx) : (ax < cx ? ax : cx ));
				hitRect.width = (bx > ax ? (bx > cx ? bx : cx) : (ax > cx ? ax : cx )) + (hitRect.x < 0 ? -hitRect.x : hitRect.x);
				hitRect.y = (by < ay ? (by < cy ? by : cy) : (ay < cy ? ay : cy ));
				hitRect.height = (by > ay ? (by > cy ? by : cy) : (ay > cy ? ay : cy )) + (hitRect.y < 0 ? -hitRect.y : hitRect.y);
				if(!((hitRect.right<cullRect.left)||(hitRect.left>cullRect.right))){
					if(!((hitRect.bottom<cullRect.top)||(hitRect.top>cullRect.bottom))){
					
					}else{
						return;
					}
				}else{
					return;
				}
        	}
			
			//cull if max iterations is reached, focus is invalid or if tesselation is to small.
            if (index >= 100 || (hitRect.width < minimumRenderSize) || (hitRect.height < minimumRenderSize) || (focus == Infinity))
            {
            	
            	//Draw this triangle.
            	a2 = v1.x - v0.x;
            	b2 = v1.y - v0.y;
            	c2 = v2.x - v0.x;
            	d2 = v2.y - v0.y;
                      	
            	tempTriangleMatrix.a = emMap.a*a2 + emMap.b*c2;
            	tempTriangleMatrix.b = emMap.a*b2 + emMap.b*d2;
            	tempTriangleMatrix.c = emMap.c*a2 + emMap.d*c2;
            	tempTriangleMatrix.d = emMap.c*b2 + emMap.d*d2;
            	tempTriangleMatrix.tx = emMap.tx*a2 + emMap.ty*c2 + v0.x;   
            	tempTriangleMatrix.ty = emMap.tx*b2 + emMap.ty*d2 + v0.y;       
           		
           		if(lineAlpha){
           			tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );
           		}
				tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);
            	tempPreGrp.moveTo(v0.x, v0.y);
            	tempPreGrp.lineTo(v1.x, v1.y);
            	tempPreGrp.lineTo(v2.x, v2.y);
            	tempPreGrp.endFill();
            	if(lineAlpha){
           			tempPreGrp.lineStyle();
           		}
                
                tempPreRSD.renderStatistics.triangles++;
                return;
            }
			
            faz = focus + az;
            fbz = focus + bz;
            fcz = focus + cz;
			mabz = 2 / (faz + fbz);
            mbcz = 2 / (fbz + fcz);
            mcaz = 2 / (fcz + faz);
            mabx = (ax*faz + bx*fbz)*mabz;
            maby = (ay*faz + by*fbz)*mabz;
            mbcx = (bx*fbz + cx*fcz)*mbcz;
            mbcy = (by*fbz + cy*fcz)*mbcz;
            mcax = (cx*fcz + ax*faz)*mcaz;
            mcay = (cy*fcz + ay*faz)*mcaz;
            dabx = ax + bx - mabx;
            daby = ay + by - maby;
            dbcx = bx + cx - mbcx;
            dbcy = by + cy - mbcy;
            dcax = cx + ax - mcax;
            dcay = cy + ay - mcay;
            dsab = (dabx*dabx + daby*daby);
            dsbc = (dbcx*dbcx + dbcy*dbcy);
            dsca = (dcax*dcax + dcay*dcay);
			
			var nIndex:int = index+1;
			var nRss:RenderRecStorage = RenderRecStorage(renderRecStorage[int(index)]);
			var renderRecMap:Matrix = nRss.mat;
			
            if ((dsab <= _precision) && (dsca <= _precision) && (dsbc <= _precision)){
               //Draw this triangle.
               a2 = v1.x - v0.x;
               b2 = v1.y - v0.y;
               c2 = v2.x - v0.x;
               d2 = v2.y - v0.y;
                      	
            	tempTriangleMatrix.a = emMap.a*a2 + emMap.b*c2;
            	tempTriangleMatrix.b = emMap.a*b2 + emMap.b*d2;
            	tempTriangleMatrix.c = emMap.c*a2 + emMap.d*c2;
            	tempTriangleMatrix.d = emMap.c*b2 + emMap.d*d2;
            	tempTriangleMatrix.tx = emMap.tx*a2 + emMap.ty*c2 + v0.x;   
            	tempTriangleMatrix.ty = emMap.tx*b2 + emMap.ty*d2 + v0.y;       
           		
           		if(lineAlpha){
           			tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );
           		}
				tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);
            	tempPreGrp.moveTo(v0.x, v0.y);
            	tempPreGrp.lineTo(v1.x, v1.y);
            	tempPreGrp.lineTo(v2.x, v2.y);
            	tempPreGrp.endFill();
               	if(lineAlpha){
               		tempPreGrp.lineStyle();
               	}
               
               
               tempPreRSD.renderStatistics.triangles++;
               return;
            }
            
            if ((dsab > _precision) && (dsca > _precision) && (dsbc > _precision)){
            	renderRecMap.a = emMap.a*2;
            	renderRecMap.b = emMap.b*2;
            	renderRecMap.c = emMap.c*2;
            	renderRecMap.d = emMap.d*2;
            	renderRecMap.tx = emMap.tx*2;
            	renderRecMap.ty = emMap.ty*2;
            	    	
          		nRss.v0.x = mabx * 0.5;
          		nRss.v0.y = maby * 0.5;
          		nRss.v0.z = (az+bz) * 0.5;
          		
          		nRss.v1.x = mbcx * 0.5;
            	nRss.v1.y = mbcy * 0.5;
            	nRss.v1.z = (bz+cz) * 0.5;
          		
          		nRss.v2.x = mcax * 0.5;
          		nRss.v2.y = mcay * 0.5;
          		nRss.v2.z = (cz+az) * 0.5;
                //renderRec(renderRecMap, v0, nRss.v0, nRss.v2, nIndex);				//renderRec(emMap:Matrix, v0:Vertex3DInstance, v1:Vertex3DInstance, v2:Vertex3DInstance, index:Number)				emMapi = renderRecMap;				v0i =  v0;				v1i = nRss.v0;				v2i = nRss.v2;				indexi = nIndex;								/// INTERNAL RECURSION							az = v0i.z;							bz = v1i.z;							cz = v2i.z;														//Cull if a vertex behind near.							if((az <= 0) && (bz <= 0) && (cz <= 0))								return;														cx = v2i.x;							cy = v2i.y;							bx = v1i.x;							by = v1i.y;							ax = v0i.x;							ay = v0i.y;														//Cull if outside of viewport.							if(cullRect){								hitRect.x = (bx < ax ? (bx < cx ? bx : cx) : (ax < cx ? ax : cx ));								hitRect.width = (bx > ax ? (bx > cx ? bx : cx) : (ax > cx ? ax : cx )) + (hitRect.x < 0 ? -hitRect.x : hitRect.x);								hitRect.y = (by < ay ? (by < cy ? by : cy) : (ay < cy ? ay : cy ));								hitRect.height = (by > ay ? (by > cy ? by : cy) : (ay > cy ? ay : cy )) + (hitRect.y < 0 ? -hitRect.y : hitRect.y);								if(!((hitRect.right<cullRect.left)||(hitRect.left>cullRect.right))){									if(!((hitRect.bottom<cullRect.top)||(hitRect.top>cullRect.bottom))){																		}else{										return;									}								}else{									return;								}							}														//cull if max iterations is reached, focus is invalid or if tesselation is to small.							if (indexi >= 100 || (hitRect.width < minimumRenderSize) || (hitRect.height < minimumRenderSize) || (focus == Infinity))							{																//Draw this triangle.								a2 = v1i.x - v0i.x;								b2 = v1i.y - v0i.y;								c2 = v2i.x - v0i.x;								d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}																tempPreRSD.renderStatistics.triangles++;								return;							}														faz = focus + az;							fbz = focus + bz;							fcz = focus + cz;							mabz = 2 / (faz + fbz);							mbcz = 2 / (fbz + fcz);							mcaz = 2 / (fcz + faz);							mabx = (ax*faz + bx*fbz)*mabz;							maby = (ay*faz + by*fbz)*mabz;							mbcx = (bx*fbz + cx*fcz)*mbcz;							mbcy = (by*fbz + cy*fcz)*mbcz;							mcax = (cx*fcz + ax*faz)*mcaz;							mcay = (cy*fcz + ay*faz)*mcaz;							dabx = ax + bx - mabx;							daby = ay + by - maby;							dbcx = bx + cx - mbcx;							dbcy = by + cy - mbcy;							dcax = cx + ax - mcax;							dcay = cy + ay - mcay;							dsab = (dabx*dabx + daby*daby);							dsbc = (dbcx*dbcx + dbcy*dbcy);							dsca = (dcax*dcax + dcay*dcay);														var nIndexi0:int = indexi+1;							var nRssi0:RenderRecStorage = RenderRecStorage(renderRecStorage[int(indexi)]);							var renderRecMapi0:Matrix = nRssi0.mat;														if ((dsab <= _precision) && (dsca <= _precision) && (dsbc <= _precision)){							   //Draw this triangle.							   a2 = v1i.x - v0i.x;							   b2 = v1i.y - v0i.y;							   c2 = v2i.x - v0i.x;							   d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}							   							   							   tempPreRSD.renderStatistics.triangles++;							   return;							}														if ((dsab > _precision) && (dsca > _precision) && (dsbc > _precision)){								renderRecMapi0.a = emMapi.a*2;								renderRecMapi0.b = emMapi.b*2;								renderRecMapi0.c = emMapi.c*2;								renderRecMapi0.d = emMapi.d*2;								renderRecMapi0.tx = emMapi.tx*2;								renderRecMapi0.ty = emMapi.ty*2;																		nRssi0.v0.x = mabx * 0.5;								nRssi0.v0.y = maby * 0.5;								nRssi0.v0.z = (az+bz) * 0.5;																nRssi0.v1.x = mbcx * 0.5;								nRssi0.v1.y = mbcy * 0.5;								nRssi0.v1.z = (bz+cz) * 0.5;																nRssi0.v2.x = mcax * 0.5;								nRssi0.v2.y = mcay * 0.5;								nRssi0.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi0, v0i, nRssi0.v0, nRssi0.v2, nIndexi0);																renderRecMapi0.tx -=1;								renderRec(renderRecMapi0, nRssi0.v0, v1i, nRssi0.v1, nIndexi0);																renderRecMapi0.ty -=1;								renderRecMapi0.tx = emMapi.tx*2;								renderRec(renderRecMapi0, nRssi0.v2, nRssi0.v1, v2i, nIndexi0);																renderRecMapi0.a = -emMapi.a*2;								renderRecMapi0.b = -emMapi.b*2;								renderRecMapi0.c = -emMapi.c*2;								renderRecMapi0.d = -emMapi.d*2;								renderRecMapi0.tx = -emMapi.tx*2+1;								renderRecMapi0.ty = -emMapi.ty*2+1;								renderRec(renderRecMapi0, nRssi0.v1, nRssi0.v2, nRssi0.v0, nIndexi0);												return;							}											if( precisionMode == PrecisionMode.ORIGINAL )							{								d2ab = dsab;								d2bc = dsbc;								d2ca = dsca;								dmax = (dsca > dsbc ? (dsca > dsab ? dsca : dsab) : (dsbc > dsab ? dsbc : dsab ));							}							else							{								// Calculate best tessellation edge								dx = v0i.x - v1i.x;								dy = v0i.y - v1i.y;								d2ab = dx * dx + dy * dy;																dx = v1i.x - v2i.x;								dy = v1i.y - v2i.y;								d2bc = dx * dx + dy * dy;																dx = v2i.x - v0i.x;								dy = v2i.y - v0i.y;								d2ca = dx * dx + dy * dy;															dmax = (d2ca > d2bc ? (d2ca > d2ab ? d2ca : d2ab) : (d2bc > d2ab ? d2bc : d2ab ));		// dmax = Math.max( d2ab, d2bc, d2ac );							}											// Break triangle along edge							if (d2ab == dmax)							{								renderRecMapi0.a = emMapi.a*2;								renderRecMapi0.b = emMapi.b;								renderRecMapi0.c = emMapi.c*2;								renderRecMapi0.d = emMapi.d;								renderRecMapi0.tx = emMapi.tx*2;								renderRecMapi0.ty = emMapi.ty;								nRssi0.v0.x = mabx * 0.5;								nRssi0.v0.y = maby * 0.5;								nRssi0.v0.z = (az+bz) * 0.5;								renderRec(renderRecMapi0, v0i, nRssi0.v0, v2i, nIndexi0);																renderRecMapi0.a = emMapi.a*2+emMapi.b;								renderRecMapi0.c = 2*emMapi.c+emMapi.d;								renderRecMapi0.tx = emMapi.tx*2+emMapi.ty-1;								renderRec(renderRecMapi0, nRssi0.v0, v1i, v2i, nIndexi0);															return;							}											if (d2ca == dmax){																renderRecMapi0.a = emMapi.a;								renderRecMapi0.b = emMapi.b*2;								renderRecMapi0.c = emMapi.c;								renderRecMapi0.d = emMapi.d*2;								renderRecMapi0.tx = emMapi.tx;								renderRecMapi0.ty = emMapi.ty*2;								nRssi0.v2.x = mcax * 0.5;								nRssi0.v2.y = mcay * 0.5;								nRssi0.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi0, v0i, v1i, nRssi0.v2, nIndexi0);																renderRecMapi0.b += emMapi.a;								renderRecMapi0.d += emMapi.c;								renderRecMapi0.ty += emMapi.tx-1;								renderRec(renderRecMapi0, nRssi0.v2, v1i, v2i, nIndexi0);																return;							}							renderRecMapi0.a = emMapi.a-emMapi.b;							renderRecMapi0.b = emMapi.b*2;							renderRecMapi0.c = emMapi.c-emMapi.d;							renderRecMapi0.d = emMapi.d*2;							renderRecMapi0.tx = emMapi.tx-emMapi.ty;							renderRecMapi0.ty = emMapi.ty*2;														nRssi0.v1.x = mbcx * 0.5;							nRssi0.v1.y = mbcy * 0.5;							nRssi0.v1.z = (bz+cz)*0.5;							renderRec(renderRecMapi0, v0i, v1i, nRssi0.v1, nIndexi0);														renderRecMapi0.a = emMapi.a*2;							renderRecMapi0.b = emMapi.b-emMapi.a;							renderRecMapi0.c = emMapi.c*2;							renderRecMapi0.d = emMapi.d-emMapi.c;							renderRecMapi0.tx = emMapi.tx*2;							renderRecMapi0.ty = emMapi.ty-emMapi.tx;							renderRec(renderRecMapi0, v0i, nRssi0.v1, v2i, nIndexi0);/// END INTERNAL RECURSION				
				
				renderRecMap.tx -=1;
                //renderRec(renderRecMap, nRss.v0, v1, nRss.v1, nIndex);				//renderRec(emMap:Matrix, v0:Vertex3DInstance, v1:Vertex3DInstance, v2:Vertex3DInstance, index:Number)				emMapi = renderRecMap;				v0i =  nRss.v0;				v1i =  v1;				v2i =  nRss.v1;				indexi = nIndex;								/// INTERNAL RECURSION							az = v0i.z;							bz = v1i.z;							cz = v2i.z;														//Cull if a vertex behind near.							if((az <= 0) && (bz <= 0) && (cz <= 0))								return;														cx = v2i.x;							cy = v2i.y;							bx = v1i.x;							by = v1i.y;							ax = v0i.x;							ay = v0i.y;														//Cull if outside of viewport.							if(cullRect){								hitRect.x = (bx < ax ? (bx < cx ? bx : cx) : (ax < cx ? ax : cx ));								hitRect.width = (bx > ax ? (bx > cx ? bx : cx) : (ax > cx ? ax : cx )) + (hitRect.x < 0 ? -hitRect.x : hitRect.x);								hitRect.y = (by < ay ? (by < cy ? by : cy) : (ay < cy ? ay : cy ));								hitRect.height = (by > ay ? (by > cy ? by : cy) : (ay > cy ? ay : cy )) + (hitRect.y < 0 ? -hitRect.y : hitRect.y);								if(!((hitRect.right<cullRect.left)||(hitRect.left>cullRect.right))){									if(!((hitRect.bottom<cullRect.top)||(hitRect.top>cullRect.bottom))){																		}else{										return;									}								}else{									return;								}							}														//cull if max iterations is reached, focus is invalid or if tesselation is to small.							if (indexi >= 100 || (hitRect.width < minimumRenderSize) || (hitRect.height < minimumRenderSize) || (focus == Infinity))							{																//Draw this triangle.								a2 = v1i.x - v0i.x;								b2 = v1i.y - v0i.y;								c2 = v2i.x - v0i.x;								d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}																tempPreRSD.renderStatistics.triangles++;								return;							}														faz = focus + az;							fbz = focus + bz;							fcz = focus + cz;							mabz = 2 / (faz + fbz);							mbcz = 2 / (fbz + fcz);							mcaz = 2 / (fcz + faz);							mabx = (ax*faz + bx*fbz)*mabz;							maby = (ay*faz + by*fbz)*mabz;							mbcx = (bx*fbz + cx*fcz)*mbcz;							mbcy = (by*fbz + cy*fcz)*mbcz;							mcax = (cx*fcz + ax*faz)*mcaz;							mcay = (cy*fcz + ay*faz)*mcaz;							dabx = ax + bx - mabx;							daby = ay + by - maby;							dbcx = bx + cx - mbcx;							dbcy = by + cy - mbcy;							dcax = cx + ax - mcax;							dcay = cy + ay - mcay;							dsab = (dabx*dabx + daby*daby);							dsbc = (dbcx*dbcx + dbcy*dbcy);							dsca = (dcax*dcax + dcay*dcay);														var nIndexi1:int = indexi+1;							var nRssi1:RenderRecStorage = RenderRecStorage(renderRecStorage[int(indexi)]);							var renderRecMapi1:Matrix = nRssi1.mat;														if ((dsab <= _precision) && (dsca <= _precision) && (dsbc <= _precision)){							   //Draw this triangle.							   a2 = v1i.x - v0i.x;							   b2 = v1i.y - v0i.y;							   c2 = v2i.x - v0i.x;							   d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}							   							   							   tempPreRSD.renderStatistics.triangles++;							   return;							}														if ((dsab > _precision) && (dsca > _precision) && (dsbc > _precision)){								renderRecMapi1.a = emMapi.a*2;								renderRecMapi1.b = emMapi.b*2;								renderRecMapi1.c = emMapi.c*2;								renderRecMapi1.d = emMapi.d*2;								renderRecMapi1.tx = emMapi.tx*2;								renderRecMapi1.ty = emMapi.ty*2;																		nRssi1.v0.x = mabx * 0.5;								nRssi1.v0.y = maby * 0.5;								nRssi1.v0.z = (az+bz) * 0.5;																nRssi1.v1.x = mbcx * 0.5;								nRssi1.v1.y = mbcy * 0.5;								nRssi1.v1.z = (bz+cz) * 0.5;																nRssi1.v2.x = mcax * 0.5;								nRssi1.v2.y = mcay * 0.5;								nRssi1.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi1, v0i, nRssi1.v0, nRssi1.v2, nIndexi1);																renderRecMapi1.tx -=1;								renderRec(renderRecMapi1, nRssi1.v0, v1i, nRssi1.v1, nIndexi1);																renderRecMapi1.ty -=1;								renderRecMapi1.tx = emMapi.tx*2;								renderRec(renderRecMapi1, nRssi1.v2, nRssi1.v1, v2i, nIndexi1);																renderRecMapi1.a = -emMapi.a*2;								renderRecMapi1.b = -emMapi.b*2;								renderRecMapi1.c = -emMapi.c*2;								renderRecMapi1.d = -emMapi.d*2;								renderRecMapi1.tx = -emMapi.tx*2+1;								renderRecMapi1.ty = -emMapi.ty*2+1;								renderRec(renderRecMapi1, nRssi1.v1, nRssi1.v2, nRssi1.v0, nIndexi1);												return;							}											if( precisionMode == PrecisionMode.ORIGINAL )							{								d2ab = dsab;								d2bc = dsbc;								d2ca = dsca;								dmax = (dsca > dsbc ? (dsca > dsab ? dsca : dsab) : (dsbc > dsab ? dsbc : dsab ));							}							else							{								// Calculate best tessellation edge								dx = v0i.x - v1i.x;								dy = v0i.y - v1i.y;								d2ab = dx * dx + dy * dy;																dx = v1i.x - v2i.x;								dy = v1i.y - v2i.y;								d2bc = dx * dx + dy * dy;																dx = v2i.x - v0i.x;								dy = v2i.y - v0i.y;								d2ca = dx * dx + dy * dy;															dmax = (d2ca > d2bc ? (d2ca > d2ab ? d2ca : d2ab) : (d2bc > d2ab ? d2bc : d2ab ));		// dmax = Math.max( d2ab, d2bc, d2ac );							}											// Break triangle along edge							if (d2ab == dmax)							{								renderRecMapi1.a = emMapi.a*2;								renderRecMapi1.b = emMapi.b;								renderRecMapi1.c = emMapi.c*2;								renderRecMapi1.d = emMapi.d;								renderRecMapi1.tx = emMapi.tx*2;								renderRecMapi1.ty = emMapi.ty;								nRssi1.v0.x = mabx * 0.5;								nRssi1.v0.y = maby * 0.5;								nRssi1.v0.z = (az+bz) * 0.5;								renderRec(renderRecMapi1, v0i, nRssi1.v0, v2i, nIndexi1);																renderRecMapi1.a = emMapi.a*2+emMapi.b;								renderRecMapi1.c = 2*emMapi.c+emMapi.d;								renderRecMapi1.tx = emMapi.tx*2+emMapi.ty-1;								renderRec(renderRecMapi1, nRssi1.v0, v1i, v2i, nIndexi1);															return;							}											if (d2ca == dmax){																renderRecMapi1.a = emMapi.a;								renderRecMapi1.b = emMapi.b*2;								renderRecMapi1.c = emMapi.c;								renderRecMapi1.d = emMapi.d*2;								renderRecMapi1.tx = emMapi.tx;								renderRecMapi1.ty = emMapi.ty*2;								nRssi1.v2.x = mcax * 0.5;								nRssi1.v2.y = mcay * 0.5;								nRssi1.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi1, v0i, v1i, nRssi1.v2, nIndexi1);																renderRecMapi1.b += emMapi.a;								renderRecMapi1.d += emMapi.c;								renderRecMapi1.ty += emMapi.tx-1;								renderRec(renderRecMapi1, nRssi1.v2, v1i, v2i, nIndexi1);																return;							}							renderRecMapi1.a = emMapi.a-emMapi.b;							renderRecMapi1.b = emMapi.b*2;							renderRecMapi1.c = emMapi.c-emMapi.d;							renderRecMapi1.d = emMapi.d*2;							renderRecMapi1.tx = emMapi.tx-emMapi.ty;							renderRecMapi1.ty = emMapi.ty*2;														nRssi1.v1.x = mbcx * 0.5;							nRssi1.v1.y = mbcy * 0.5;							nRssi1.v1.z = (bz+cz)*0.5;							renderRec(renderRecMapi1, v0i, v1i, nRssi1.v1, nIndexi1);														renderRecMapi1.a = emMapi.a*2;							renderRecMapi1.b = emMapi.b-emMapi.a;							renderRecMapi1.c = emMapi.c*2;							renderRecMapi1.d = emMapi.d-emMapi.c;							renderRecMapi1.tx = emMapi.tx*2;							renderRecMapi1.ty = emMapi.ty-emMapi.tx;							renderRec(renderRecMapi1, v0i, nRssi1.v1, v2i, nIndexi1);/// END INTERNAL RECURSION				
				
				renderRecMap.ty -=1;
				renderRecMap.tx = emMap.tx*2;
                //renderRec(renderRecMap, nRss.v2, nRss.v1, v2, nIndex);				//renderRec(emMap:Matrix, v0:Vertex3DInstance, v1:Vertex3DInstance, v2:Vertex3DInstance, index:Number)				emMapi = renderRecMap;				v0i =  nRss.v2;				v1i =  nRss.v1;				v2i =  v2;				indexi = nIndex;								/// INTERNAL RECURSION							az = v0i.z;							bz = v1i.z;							cz = v2i.z;														//Cull if a vertex behind near.							if((az <= 0) && (bz <= 0) && (cz <= 0))								return;														cx = v2i.x;							cy = v2i.y;							bx = v1i.x;							by = v1i.y;							ax = v0i.x;							ay = v0i.y;														//Cull if outside of viewport.							if(cullRect){								hitRect.x = (bx < ax ? (bx < cx ? bx : cx) : (ax < cx ? ax : cx ));								hitRect.width = (bx > ax ? (bx > cx ? bx : cx) : (ax > cx ? ax : cx )) + (hitRect.x < 0 ? -hitRect.x : hitRect.x);								hitRect.y = (by < ay ? (by < cy ? by : cy) : (ay < cy ? ay : cy ));								hitRect.height = (by > ay ? (by > cy ? by : cy) : (ay > cy ? ay : cy )) + (hitRect.y < 0 ? -hitRect.y : hitRect.y);								if(!((hitRect.right<cullRect.left)||(hitRect.left>cullRect.right))){									if(!((hitRect.bottom<cullRect.top)||(hitRect.top>cullRect.bottom))){																		}else{										return;									}								}else{									return;								}							}														//cull if max iterations is reached, focus is invalid or if tesselation is to small.							if (indexi >= 100 || (hitRect.width < minimumRenderSize) || (hitRect.height < minimumRenderSize) || (focus == Infinity))							{																//Draw this triangle.								a2 = v1i.x - v0i.x;								b2 = v1i.y - v0i.y;								c2 = v2i.x - v0i.x;								d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}																tempPreRSD.renderStatistics.triangles++;								return;							}														faz = focus + az;							fbz = focus + bz;							fcz = focus + cz;							mabz = 2 / (faz + fbz);							mbcz = 2 / (fbz + fcz);							mcaz = 2 / (fcz + faz);							mabx = (ax*faz + bx*fbz)*mabz;							maby = (ay*faz + by*fbz)*mabz;							mbcx = (bx*fbz + cx*fcz)*mbcz;							mbcy = (by*fbz + cy*fcz)*mbcz;							mcax = (cx*fcz + ax*faz)*mcaz;							mcay = (cy*fcz + ay*faz)*mcaz;							dabx = ax + bx - mabx;							daby = ay + by - maby;							dbcx = bx + cx - mbcx;							dbcy = by + cy - mbcy;							dcax = cx + ax - mcax;							dcay = cy + ay - mcay;							dsab = (dabx*dabx + daby*daby);							dsbc = (dbcx*dbcx + dbcy*dbcy);							dsca = (dcax*dcax + dcay*dcay);														var nIndexi2:int = indexi+1;							var nRssi2:RenderRecStorage = RenderRecStorage(renderRecStorage[int(indexi)]);							var renderRecMapi2:Matrix = nRssi2.mat;														if ((dsab <= _precision) && (dsca <= _precision) && (dsbc <= _precision)){							   //Draw this triangle.							   a2 = v1i.x - v0i.x;							   b2 = v1i.y - v0i.y;							   c2 = v2i.x - v0i.x;							   d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}							   							   							   tempPreRSD.renderStatistics.triangles++;							   return;							}														if ((dsab > _precision) && (dsca > _precision) && (dsbc > _precision)){								renderRecMapi2.a = emMapi.a*2;								renderRecMapi2.b = emMapi.b*2;								renderRecMapi2.c = emMapi.c*2;								renderRecMapi2.d = emMapi.d*2;								renderRecMapi2.tx = emMapi.tx*2;								renderRecMapi2.ty = emMapi.ty*2;																		nRssi2.v0.x = mabx * 0.5;								nRssi2.v0.y = maby * 0.5;								nRssi2.v0.z = (az+bz) * 0.5;																nRssi2.v1.x = mbcx * 0.5;								nRssi2.v1.y = mbcy * 0.5;								nRssi2.v1.z = (bz+cz) * 0.5;																nRssi2.v2.x = mcax * 0.5;								nRssi2.v2.y = mcay * 0.5;								nRssi2.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi2, v0i, nRssi2.v0, nRssi2.v2, nIndexi2);																renderRecMapi2.tx -=1;								renderRec(renderRecMapi2, nRssi2.v0, v1i, nRssi2.v1, nIndexi2);																renderRecMapi2.ty -=1;								renderRecMapi2.tx = emMapi.tx*2;								renderRec(renderRecMapi2, nRssi2.v2, nRssi2.v1, v2i, nIndexi2);																renderRecMapi2.a = -emMapi.a*2;								renderRecMapi2.b = -emMapi.b*2;								renderRecMapi2.c = -emMapi.c*2;								renderRecMapi2.d = -emMapi.d*2;								renderRecMapi2.tx = -emMapi.tx*2+1;								renderRecMapi2.ty = -emMapi.ty*2+1;								renderRec(renderRecMapi2, nRssi2.v1, nRssi2.v2, nRssi2.v0, nIndexi2);												return;							}											if( precisionMode == PrecisionMode.ORIGINAL )							{								d2ab = dsab;								d2bc = dsbc;								d2ca = dsca;								dmax = (dsca > dsbc ? (dsca > dsab ? dsca : dsab) : (dsbc > dsab ? dsbc : dsab ));							}							else							{								// Calculate best tessellation edge								dx = v0i.x - v1i.x;								dy = v0i.y - v1i.y;								d2ab = dx * dx + dy * dy;																dx = v1i.x - v2i.x;								dy = v1i.y - v2i.y;								d2bc = dx * dx + dy * dy;																dx = v2i.x - v0i.x;								dy = v2i.y - v0i.y;								d2ca = dx * dx + dy * dy;															dmax = (d2ca > d2bc ? (d2ca > d2ab ? d2ca : d2ab) : (d2bc > d2ab ? d2bc : d2ab ));		// dmax = Math.max( d2ab, d2bc, d2ac );							}											// Break triangle along edge							if (d2ab == dmax)							{								renderRecMapi2.a = emMapi.a*2;								renderRecMapi2.b = emMapi.b;								renderRecMapi2.c = emMapi.c*2;								renderRecMapi2.d = emMapi.d;								renderRecMapi2.tx = emMapi.tx*2;								renderRecMapi2.ty = emMapi.ty;								nRssi2.v0.x = mabx * 0.5;								nRssi2.v0.y = maby * 0.5;								nRssi2.v0.z = (az+bz) * 0.5;								renderRec(renderRecMapi2, v0i, nRssi2.v0, v2i, nIndexi2);																renderRecMapi2.a = emMapi.a*2+emMapi.b;								renderRecMapi2.c = 2*emMapi.c+emMapi.d;								renderRecMapi2.tx = emMapi.tx*2+emMapi.ty-1;								renderRec(renderRecMapi2, nRssi2.v0, v1i, v2i, nIndexi2);															return;							}											if (d2ca == dmax){																renderRecMapi2.a = emMapi.a;								renderRecMapi2.b = emMapi.b*2;								renderRecMapi2.c = emMapi.c;								renderRecMapi2.d = emMapi.d*2;								renderRecMapi2.tx = emMapi.tx;								renderRecMapi2.ty = emMapi.ty*2;								nRssi2.v2.x = mcax * 0.5;								nRssi2.v2.y = mcay * 0.5;								nRssi2.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi2, v0i, v1i, nRssi2.v2, nIndexi2);																renderRecMapi2.b += emMapi.a;								renderRecMapi2.d += emMapi.c;								renderRecMapi2.ty += emMapi.tx-1;								renderRec(renderRecMapi2, nRssi2.v2, v1i, v2i, nIndexi2);																return;							}							renderRecMapi2.a = emMapi.a-emMapi.b;							renderRecMapi2.b = emMapi.b*2;							renderRecMapi2.c = emMapi.c-emMapi.d;							renderRecMapi2.d = emMapi.d*2;							renderRecMapi2.tx = emMapi.tx-emMapi.ty;							renderRecMapi2.ty = emMapi.ty*2;														nRssi2.v1.x = mbcx * 0.5;							nRssi2.v1.y = mbcy * 0.5;							nRssi2.v1.z = (bz+cz)*0.5;							renderRec(renderRecMapi2, v0i, v1i, nRssi2.v1, nIndexi2);														renderRecMapi2.a = emMapi.a*2;							renderRecMapi2.b = emMapi.b-emMapi.a;							renderRecMapi2.c = emMapi.c*2;							renderRecMapi2.d = emMapi.d-emMapi.c;							renderRecMapi2.tx = emMapi.tx*2;							renderRecMapi2.ty = emMapi.ty-emMapi.tx;							renderRec(renderRecMapi2, v0i, nRssi2.v1, v2i, nIndexi2);/// END INTERNAL RECURSION				
				
				renderRecMap.a = -emMap.a*2;
				renderRecMap.b = -emMap.b*2;
				renderRecMap.c = -emMap.c*2;
				renderRecMap.d = -emMap.d*2;
				renderRecMap.tx = -emMap.tx*2+1;
				renderRecMap.ty = -emMap.ty*2+1;
                //renderRec(renderRecMap, nRss.v1, nRss.v2, nRss.v0, nIndex);				//renderRec(emMap:Matrix, v0:Vertex3DInstance, v1:Vertex3DInstance, v2:Vertex3DInstance, index:Number)				emMapi = renderRecMap;				v0i =  nRss.v1;				v1i =  nRss.v2;				v2i =  nRss.v0;				indexi = nIndex;								/// INTERNAL RECURSION							az = v0i.z;							bz = v1i.z;							cz = v2i.z;														//Cull if a vertex behind near.							if((az <= 0) && (bz <= 0) && (cz <= 0))								return;														cx = v2i.x;							cy = v2i.y;							bx = v1i.x;							by = v1i.y;							ax = v0i.x;							ay = v0i.y;														//Cull if outside of viewport.							if(cullRect){								hitRect.x = (bx < ax ? (bx < cx ? bx : cx) : (ax < cx ? ax : cx ));								hitRect.width = (bx > ax ? (bx > cx ? bx : cx) : (ax > cx ? ax : cx )) + (hitRect.x < 0 ? -hitRect.x : hitRect.x);								hitRect.y = (by < ay ? (by < cy ? by : cy) : (ay < cy ? ay : cy ));								hitRect.height = (by > ay ? (by > cy ? by : cy) : (ay > cy ? ay : cy )) + (hitRect.y < 0 ? -hitRect.y : hitRect.y);								if(!((hitRect.right<cullRect.left)||(hitRect.left>cullRect.right))){									if(!((hitRect.bottom<cullRect.top)||(hitRect.top>cullRect.bottom))){																		}else{										return;									}								}else{									return;								}							}														//cull if max iterations is reached, focus is invalid or if tesselation is to small.							if (indexi >= 100 || (hitRect.width < minimumRenderSize) || (hitRect.height < minimumRenderSize) || (focus == Infinity))							{																//Draw this triangle.								a2 = v1i.x - v0i.x;								b2 = v1i.y - v0i.y;								c2 = v2i.x - v0i.x;								d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}																tempPreRSD.renderStatistics.triangles++;								return;							}														faz = focus + az;							fbz = focus + bz;							fcz = focus + cz;							mabz = 2 / (faz + fbz);							mbcz = 2 / (fbz + fcz);							mcaz = 2 / (fcz + faz);							mabx = (ax*faz + bx*fbz)*mabz;							maby = (ay*faz + by*fbz)*mabz;							mbcx = (bx*fbz + cx*fcz)*mbcz;							mbcy = (by*fbz + cy*fcz)*mbcz;							mcax = (cx*fcz + ax*faz)*mcaz;							mcay = (cy*fcz + ay*faz)*mcaz;							dabx = ax + bx - mabx;							daby = ay + by - maby;							dbcx = bx + cx - mbcx;							dbcy = by + cy - mbcy;							dcax = cx + ax - mcax;							dcay = cy + ay - mcay;							dsab = (dabx*dabx + daby*daby);							dsbc = (dbcx*dbcx + dbcy*dbcy);							dsca = (dcax*dcax + dcay*dcay);														var nIndexi3:int = indexi+1;							var nRssi3:RenderRecStorage = RenderRecStorage(renderRecStorage[int(indexi)]);							var renderRecMapi3:Matrix = nRssi3.mat;														if ((dsab <= _precision) && (dsca <= _precision) && (dsbc <= _precision)){							   //Draw this triangle.							   a2 = v1i.x - v0i.x;							   b2 = v1i.y - v0i.y;							   c2 = v2i.x - v0i.x;							   d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}							   							   							   tempPreRSD.renderStatistics.triangles++;							   return;							}														if ((dsab > _precision) && (dsca > _precision) && (dsbc > _precision)){								renderRecMapi3.a = emMapi.a*2;								renderRecMapi3.b = emMapi.b*2;								renderRecMapi3.c = emMapi.c*2;								renderRecMapi3.d = emMapi.d*2;								renderRecMapi3.tx = emMapi.tx*2;								renderRecMapi3.ty = emMapi.ty*2;																		nRssi3.v0.x = mabx * 0.5;								nRssi3.v0.y = maby * 0.5;								nRssi3.v0.z = (az+bz) * 0.5;																nRssi3.v1.x = mbcx * 0.5;								nRssi3.v1.y = mbcy * 0.5;								nRssi3.v1.z = (bz+cz) * 0.5;																nRssi3.v2.x = mcax * 0.5;								nRssi3.v2.y = mcay * 0.5;								nRssi3.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi3, v0i, nRssi3.v0, nRssi3.v2, nIndexi3);																renderRecMapi3.tx -=1;								renderRec(renderRecMapi3, nRssi3.v0, v1i, nRssi3.v1, nIndexi3);																renderRecMapi3.ty -=1;								renderRecMapi3.tx = emMapi.tx*2;								renderRec(renderRecMapi3, nRssi3.v2, nRssi3.v1, v2i, nIndexi3);																renderRecMapi3.a = -emMapi.a*2;								renderRecMapi3.b = -emMapi.b*2;								renderRecMapi3.c = -emMapi.c*2;								renderRecMapi3.d = -emMapi.d*2;								renderRecMapi3.tx = -emMapi.tx*2+1;								renderRecMapi3.ty = -emMapi.ty*2+1;								renderRec(renderRecMapi3, nRssi3.v1, nRssi3.v2, nRssi3.v0, nIndexi3);												return;							}											if( precisionMode == PrecisionMode.ORIGINAL )							{								d2ab = dsab;								d2bc = dsbc;								d2ca = dsca;								dmax = (dsca > dsbc ? (dsca > dsab ? dsca : dsab) : (dsbc > dsab ? dsbc : dsab ));							}							else							{								// Calculate best tessellation edge								dx = v0i.x - v1i.x;								dy = v0i.y - v1i.y;								d2ab = dx * dx + dy * dy;																dx = v1i.x - v2i.x;								dy = v1i.y - v2i.y;								d2bc = dx * dx + dy * dy;																dx = v2i.x - v0i.x;								dy = v2i.y - v0i.y;								d2ca = dx * dx + dy * dy;															dmax = (d2ca > d2bc ? (d2ca > d2ab ? d2ca : d2ab) : (d2bc > d2ab ? d2bc : d2ab ));		// dmax = Math.max( d2ab, d2bc, d2ac );							}											// Break triangle along edge							if (d2ab == dmax)							{								renderRecMapi3.a = emMapi.a*2;								renderRecMapi3.b = emMapi.b;								renderRecMapi3.c = emMapi.c*2;								renderRecMapi3.d = emMapi.d;								renderRecMapi3.tx = emMapi.tx*2;								renderRecMapi3.ty = emMapi.ty;								nRssi3.v0.x = mabx * 0.5;								nRssi3.v0.y = maby * 0.5;								nRssi3.v0.z = (az+bz) * 0.5;								renderRec(renderRecMapi3, v0i, nRssi3.v0, v2i, nIndexi3);																renderRecMapi3.a = emMapi.a*2+emMapi.b;								renderRecMapi3.c = 2*emMapi.c+emMapi.d;								renderRecMapi3.tx = emMapi.tx*2+emMapi.ty-1;								renderRec(renderRecMapi3, nRssi3.v0, v1i, v2i, nIndexi3);															return;							}											if (d2ca == dmax){																renderRecMapi3.a = emMapi.a;								renderRecMapi3.b = emMapi.b*2;								renderRecMapi3.c = emMapi.c;								renderRecMapi3.d = emMapi.d*2;								renderRecMapi3.tx = emMapi.tx;								renderRecMapi3.ty = emMapi.ty*2;								nRssi3.v2.x = mcax * 0.5;								nRssi3.v2.y = mcay * 0.5;								nRssi3.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi3, v0i, v1i, nRssi3.v2, nIndexi3);																renderRecMapi3.b += emMapi.a;								renderRecMapi3.d += emMapi.c;								renderRecMapi3.ty += emMapi.tx-1;								renderRec(renderRecMapi3, nRssi3.v2, v1i, v2i, nIndexi3);																return;							}							renderRecMapi3.a = emMapi.a-emMapi.b;							renderRecMapi3.b = emMapi.b*2;							renderRecMapi3.c = emMapi.c-emMapi.d;							renderRecMapi3.d = emMapi.d*2;							renderRecMapi3.tx = emMapi.tx-emMapi.ty;							renderRecMapi3.ty = emMapi.ty*2;														nRssi3.v1.x = mbcx * 0.5;							nRssi3.v1.y = mbcy * 0.5;							nRssi3.v1.z = (bz+cz)*0.5;							renderRec(renderRecMapi3, v0i, v1i, nRssi3.v1, nIndexi3);														renderRecMapi3.a = emMapi.a*2;							renderRecMapi3.b = emMapi.b-emMapi.a;							renderRecMapi3.c = emMapi.c*2;							renderRecMapi3.d = emMapi.d-emMapi.c;							renderRecMapi3.tx = emMapi.tx*2;							renderRecMapi3.ty = emMapi.ty-emMapi.tx;							renderRec(renderRecMapi3, v0i, nRssi3.v1, v2i, nIndexi3);/// END INTERNAL RECURSION				

                return;
            }

			if( precisionMode == PrecisionMode.ORIGINAL )
			{
				d2ab = dsab;
				d2bc = dsbc;
				d2ca = dsca;
				dmax = (dsca > dsbc ? (dsca > dsab ? dsca : dsab) : (dsbc > dsab ? dsbc : dsab ));
			}
			else
			{
				// Calculate best tessellation edge
				dx = v0.x - v1.x;
				dy = v0.y - v1.y;
				d2ab = dx * dx + dy * dy;
				
				dx = v1.x - v2.x;
				dy = v1.y - v2.y;
				d2bc = dx * dx + dy * dy;
				
				dx = v2.x - v0.x;
				dy = v2.y - v0.y;
				d2ca = dx * dx + dy * dy;
			
				dmax = (d2ca > d2bc ? (d2ca > d2ab ? d2ca : d2ab) : (d2bc > d2ab ? d2bc : d2ab ));		// dmax = Math.max( d2ab, d2bc, d2ac );
			}

			// Break triangle along edge
            if (d2ab == dmax)
            {
            	renderRecMap.a = emMap.a*2;
				renderRecMap.b = emMap.b;
				renderRecMap.c = emMap.c*2;
				renderRecMap.d = emMap.d;
				renderRecMap.tx = emMap.tx*2;
				renderRecMap.ty = emMap.ty;
				nRss.v0.x = mabx * 0.5;
				nRss.v0.y = maby * 0.5;
				nRss.v0.z = (az+bz) * 0.5;
                //renderRec(renderRecMap, v0, nRss.v0, v2, nIndex);				//renderRec(emMap:Matrix, v0:Vertex3DInstance, v1:Vertex3DInstance, v2:Vertex3DInstance, index:Number)				emMapi = renderRecMap;				v0i =  v0;				v1i =  nRss.v0;				v2i =  v2;				indexi = nIndex;								/// INTERNAL RECURSION							az = v0i.z;							bz = v1i.z;							cz = v2i.z;														//Cull if a vertex behind near.							if((az <= 0) && (bz <= 0) && (cz <= 0))								return;														cx = v2i.x;							cy = v2i.y;							bx = v1i.x;							by = v1i.y;							ax = v0i.x;							ay = v0i.y;														//Cull if outside of viewport.							if(cullRect){								hitRect.x = (bx < ax ? (bx < cx ? bx : cx) : (ax < cx ? ax : cx ));								hitRect.width = (bx > ax ? (bx > cx ? bx : cx) : (ax > cx ? ax : cx )) + (hitRect.x < 0 ? -hitRect.x : hitRect.x);								hitRect.y = (by < ay ? (by < cy ? by : cy) : (ay < cy ? ay : cy ));								hitRect.height = (by > ay ? (by > cy ? by : cy) : (ay > cy ? ay : cy )) + (hitRect.y < 0 ? -hitRect.y : hitRect.y);								if(!((hitRect.right<cullRect.left)||(hitRect.left>cullRect.right))){									if(!((hitRect.bottom<cullRect.top)||(hitRect.top>cullRect.bottom))){																		}else{										return;									}								}else{									return;								}							}														//cull if max iterations is reached, focus is invalid or if tesselation is to small.							if (indexi >= 100 || (hitRect.width < minimumRenderSize) || (hitRect.height < minimumRenderSize) || (focus == Infinity))							{																//Draw this triangle.								a2 = v1i.x - v0i.x;								b2 = v1i.y - v0i.y;								c2 = v2i.x - v0i.x;								d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}																tempPreRSD.renderStatistics.triangles++;								return;							}														faz = focus + az;							fbz = focus + bz;							fcz = focus + cz;							mabz = 2 / (faz + fbz);							mbcz = 2 / (fbz + fcz);							mcaz = 2 / (fcz + faz);							mabx = (ax*faz + bx*fbz)*mabz;							maby = (ay*faz + by*fbz)*mabz;							mbcx = (bx*fbz + cx*fcz)*mbcz;							mbcy = (by*fbz + cy*fcz)*mbcz;							mcax = (cx*fcz + ax*faz)*mcaz;							mcay = (cy*fcz + ay*faz)*mcaz;							dabx = ax + bx - mabx;							daby = ay + by - maby;							dbcx = bx + cx - mbcx;							dbcy = by + cy - mbcy;							dcax = cx + ax - mcax;							dcay = cy + ay - mcay;							dsab = (dabx*dabx + daby*daby);							dsbc = (dbcx*dbcx + dbcy*dbcy);							dsca = (dcax*dcax + dcay*dcay);														var nIndexi4:int = indexi+1;							var nRssi4:RenderRecStorage = RenderRecStorage(renderRecStorage[int(indexi)]);							var renderRecMapi:Matrix = nRssi4.mat;														if ((dsab <= _precision) && (dsca <= _precision) && (dsbc <= _precision)){							   //Draw this triangle.							   a2 = v1i.x - v0i.x;							   b2 = v1i.y - v0i.y;							   c2 = v2i.x - v0i.x;							   d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}							   							   							   tempPreRSD.renderStatistics.triangles++;							   return;							}														if ((dsab > _precision) && (dsca > _precision) && (dsbc > _precision)){								renderRecMapi.a = emMapi.a*2;								renderRecMapi.b = emMapi.b*2;								renderRecMapi.c = emMapi.c*2;								renderRecMapi.d = emMapi.d*2;								renderRecMapi.tx = emMapi.tx*2;								renderRecMapi.ty = emMapi.ty*2;																		nRssi4.v0.x = mabx * 0.5;								nRssi4.v0.y = maby * 0.5;								nRssi4.v0.z = (az+bz) * 0.5;																nRssi4.v1.x = mbcx * 0.5;								nRssi4.v1.y = mbcy * 0.5;								nRssi4.v1.z = (bz+cz) * 0.5;																nRssi4.v2.x = mcax * 0.5;								nRssi4.v2.y = mcay * 0.5;								nRssi4.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi, v0i, nRssi4.v0, nRssi4.v2, nIndexi4);																renderRecMapi.tx -=1;								renderRec(renderRecMapi, nRssi4.v0, v1i, nRssi4.v1, nIndexi4);																renderRecMapi.ty -=1;								renderRecMapi.tx = emMapi.tx*2;								renderRec(renderRecMapi, nRssi4.v2, nRssi4.v1, v2i, nIndexi4);																renderRecMapi.a = -emMapi.a*2;								renderRecMapi.b = -emMapi.b*2;								renderRecMapi.c = -emMapi.c*2;								renderRecMapi.d = -emMapi.d*2;								renderRecMapi.tx = -emMapi.tx*2+1;								renderRecMapi.ty = -emMapi.ty*2+1;								renderRec(renderRecMapi, nRssi4.v1, nRssi4.v2, nRssi4.v0, nIndexi4);												return;							}											if( precisionMode == PrecisionMode.ORIGINAL )							{								d2ab = dsab;								d2bc = dsbc;								d2ca = dsca;								dmax = (dsca > dsbc ? (dsca > dsab ? dsca : dsab) : (dsbc > dsab ? dsbc : dsab ));							}							else							{								// Calculate best tessellation edge								dx = v0i.x - v1i.x;								dy = v0i.y - v1i.y;								d2ab = dx * dx + dy * dy;																dx = v1i.x - v2i.x;								dy = v1i.y - v2i.y;								d2bc = dx * dx + dy * dy;																dx = v2i.x - v0i.x;								dy = v2i.y - v0i.y;								d2ca = dx * dx + dy * dy;															dmax = (d2ca > d2bc ? (d2ca > d2ab ? d2ca : d2ab) : (d2bc > d2ab ? d2bc : d2ab ));		// dmax = Math.max( d2ab, d2bc, d2ac );							}											// Break triangle along edge							if (d2ab == dmax)							{								renderRecMapi.a = emMapi.a*2;								renderRecMapi.b = emMapi.b;								renderRecMapi.c = emMapi.c*2;								renderRecMapi.d = emMapi.d;								renderRecMapi.tx = emMapi.tx*2;								renderRecMapi.ty = emMapi.ty;								nRssi4.v0.x = mabx * 0.5;								nRssi4.v0.y = maby * 0.5;								nRssi4.v0.z = (az+bz) * 0.5;								renderRec(renderRecMapi, v0i, nRssi4.v0, v2i, nIndexi4);																renderRecMapi.a = emMapi.a*2+emMapi.b;								renderRecMapi.c = 2*emMapi.c+emMapi.d;								renderRecMapi.tx = emMapi.tx*2+emMapi.ty-1;								renderRec(renderRecMapi, nRssi4.v0, v1i, v2i, nIndexi4);															return;							}											if (d2ca == dmax){																renderRecMapi.a = emMapi.a;								renderRecMapi.b = emMapi.b*2;								renderRecMapi.c = emMapi.c;								renderRecMapi.d = emMapi.d*2;								renderRecMapi.tx = emMapi.tx;								renderRecMapi.ty = emMapi.ty*2;								nRssi4.v2.x = mcax * 0.5;								nRssi4.v2.y = mcay * 0.5;								nRssi4.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi, v0i, v1i, nRssi4.v2, nIndexi4);																renderRecMapi.b += emMapi.a;								renderRecMapi.d += emMapi.c;								renderRecMapi.ty += emMapi.tx-1;								renderRec(renderRecMapi, nRssi4.v2, v1i, v2i, nIndexi4);																return;							}							renderRecMapi.a = emMapi.a-emMapi.b;							renderRecMapi.b = emMapi.b*2;							renderRecMapi.c = emMapi.c-emMapi.d;							renderRecMapi.d = emMapi.d*2;							renderRecMapi.tx = emMapi.tx-emMapi.ty;							renderRecMapi.ty = emMapi.ty*2;														nRssi4.v1.x = mbcx * 0.5;							nRssi4.v1.y = mbcy * 0.5;							nRssi4.v1.z = (bz+cz)*0.5;							renderRec(renderRecMapi, v0i, v1i, nRssi4.v1, nIndexi4);														renderRecMapi.a = emMapi.a*2;							renderRecMapi.b = emMapi.b-emMapi.a;							renderRecMapi.c = emMapi.c*2;							renderRecMapi.d = emMapi.d-emMapi.c;							renderRecMapi.tx = emMapi.tx*2;							renderRecMapi.ty = emMapi.ty-emMapi.tx;							renderRec(renderRecMapi, v0i, nRssi4.v1, v2i, nIndexi4);/// END INTERNAL RECURSION				
				
				renderRecMap.a = emMap.a*2+emMap.b;
				renderRecMap.c = 2*emMap.c+emMap.d;
				renderRecMap.tx = emMap.tx*2+emMap.ty-1;
                //renderRec(renderRecMap, nRss.v0, v1, v2, nIndex);				//renderRec(emMap:Matrix, v0:Vertex3DInstance, v1:Vertex3DInstance, v2:Vertex3DInstance, index:Number)				emMapi = renderRecMap;				v0i =  nRss.v0;				v1i =  v1;				v2i =  v2;				indexi = nIndex;								/// INTERNAL RECURSION							az = v0i.z;							bz = v1i.z;							cz = v2i.z;														//Cull if a vertex behind near.							if((az <= 0) && (bz <= 0) && (cz <= 0))								return;														cx = v2i.x;							cy = v2i.y;							bx = v1i.x;							by = v1i.y;							ax = v0i.x;							ay = v0i.y;														//Cull if outside of viewport.							if(cullRect){								hitRect.x = (bx < ax ? (bx < cx ? bx : cx) : (ax < cx ? ax : cx ));								hitRect.width = (bx > ax ? (bx > cx ? bx : cx) : (ax > cx ? ax : cx )) + (hitRect.x < 0 ? -hitRect.x : hitRect.x);								hitRect.y = (by < ay ? (by < cy ? by : cy) : (ay < cy ? ay : cy ));								hitRect.height = (by > ay ? (by > cy ? by : cy) : (ay > cy ? ay : cy )) + (hitRect.y < 0 ? -hitRect.y : hitRect.y);								if(!((hitRect.right<cullRect.left)||(hitRect.left>cullRect.right))){									if(!((hitRect.bottom<cullRect.top)||(hitRect.top>cullRect.bottom))){																		}else{										return;									}								}else{									return;								}							}														//cull if max iterations is reached, focus is invalid or if tesselation is to small.							if (indexi >= 100 || (hitRect.width < minimumRenderSize) || (hitRect.height < minimumRenderSize) || (focus == Infinity))							{																//Draw this triangle.								a2 = v1i.x - v0i.x;								b2 = v1i.y - v0i.y;								c2 = v2i.x - v0i.x;								d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}																tempPreRSD.renderStatistics.triangles++;								return;							}														faz = focus + az;							fbz = focus + bz;							fcz = focus + cz;							mabz = 2 / (faz + fbz);							mbcz = 2 / (fbz + fcz);							mcaz = 2 / (fcz + faz);							mabx = (ax*faz + bx*fbz)*mabz;							maby = (ay*faz + by*fbz)*mabz;							mbcx = (bx*fbz + cx*fcz)*mbcz;							mbcy = (by*fbz + cy*fcz)*mbcz;							mcax = (cx*fcz + ax*faz)*mcaz;							mcay = (cy*fcz + ay*faz)*mcaz;							dabx = ax + bx - mabx;							daby = ay + by - maby;							dbcx = bx + cx - mbcx;							dbcy = by + cy - mbcy;							dcax = cx + ax - mcax;							dcay = cy + ay - mcay;							dsab = (dabx*dabx + daby*daby);							dsbc = (dbcx*dbcx + dbcy*dbcy);							dsca = (dcax*dcax + dcay*dcay);														var nIndexi5:int = indexi+1;							var nRssi5:RenderRecStorage = RenderRecStorage(renderRecStorage[int(indexi)]);							var renderRecMapi5:Matrix = nRssi5.mat;														if ((dsab <= _precision) && (dsca <= _precision) && (dsbc <= _precision)){							   //Draw this triangle.							   a2 = v1i.x - v0i.x;							   b2 = v1i.y - v0i.y;							   c2 = v2i.x - v0i.x;							   d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}							   							   							   tempPreRSD.renderStatistics.triangles++;							   return;							}														if ((dsab > _precision) && (dsca > _precision) && (dsbc > _precision)){								renderRecMapi5.a = emMapi.a*2;								renderRecMapi5.b = emMapi.b*2;								renderRecMapi5.c = emMapi.c*2;								renderRecMapi5.d = emMapi.d*2;								renderRecMapi5.tx = emMapi.tx*2;								renderRecMapi5.ty = emMapi.ty*2;																		nRssi5.v0.x = mabx * 0.5;								nRssi5.v0.y = maby * 0.5;								nRssi5.v0.z = (az+bz) * 0.5;																nRssi5.v1.x = mbcx * 0.5;								nRssi5.v1.y = mbcy * 0.5;								nRssi5.v1.z = (bz+cz) * 0.5;																nRssi5.v2.x = mcax * 0.5;								nRssi5.v2.y = mcay * 0.5;								nRssi5.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi5, v0i, nRssi5.v0, nRssi5.v2, nIndexi5);																renderRecMapi5.tx -=1;								renderRec(renderRecMapi5, nRssi5.v0, v1i, nRssi5.v1, nIndexi5);																renderRecMapi5.ty -=1;								renderRecMapi5.tx = emMapi.tx*2;								renderRec(renderRecMapi5, nRssi5.v2, nRssi5.v1, v2i, nIndexi5);																renderRecMapi5.a = -emMapi.a*2;								renderRecMapi5.b = -emMapi.b*2;								renderRecMapi5.c = -emMapi.c*2;								renderRecMapi5.d = -emMapi.d*2;								renderRecMapi5.tx = -emMapi.tx*2+1;								renderRecMapi5.ty = -emMapi.ty*2+1;								renderRec(renderRecMapi5, nRssi5.v1, nRssi5.v2, nRssi5.v0, nIndexi5);												return;							}											if( precisionMode == PrecisionMode.ORIGINAL )							{								d2ab = dsab;								d2bc = dsbc;								d2ca = dsca;								dmax = (dsca > dsbc ? (dsca > dsab ? dsca : dsab) : (dsbc > dsab ? dsbc : dsab ));							}							else							{								// Calculate best tessellation edge								dx = v0i.x - v1i.x;								dy = v0i.y - v1i.y;								d2ab = dx * dx + dy * dy;																dx = v1i.x - v2i.x;								dy = v1i.y - v2i.y;								d2bc = dx * dx + dy * dy;																dx = v2i.x - v0i.x;								dy = v2i.y - v0i.y;								d2ca = dx * dx + dy * dy;															dmax = (d2ca > d2bc ? (d2ca > d2ab ? d2ca : d2ab) : (d2bc > d2ab ? d2bc : d2ab ));		// dmax = Math.max( d2ab, d2bc, d2ac );							}											// Break triangle along edge							if (d2ab == dmax)							{								renderRecMapi5.a = emMapi.a*2;								renderRecMapi5.b = emMapi.b;								renderRecMapi5.c = emMapi.c*2;								renderRecMapi5.d = emMapi.d;								renderRecMapi5.tx = emMapi.tx*2;								renderRecMapi5.ty = emMapi.ty;								nRssi5.v0.x = mabx * 0.5;								nRssi5.v0.y = maby * 0.5;								nRssi5.v0.z = (az+bz) * 0.5;								renderRec(renderRecMapi5, v0i, nRssi5.v0, v2i, nIndexi5);																renderRecMapi5.a = emMapi.a*2+emMapi.b;								renderRecMapi5.c = 2*emMapi.c+emMapi.d;								renderRecMapi5.tx = emMapi.tx*2+emMapi.ty-1;								renderRec(renderRecMapi5, nRssi5.v0, v1i, v2i, nIndexi5);															return;							}											if (d2ca == dmax){																renderRecMapi5.a = emMapi.a;								renderRecMapi5.b = emMapi.b*2;								renderRecMapi5.c = emMapi.c;								renderRecMapi5.d = emMapi.d*2;								renderRecMapi5.tx = emMapi.tx;								renderRecMapi5.ty = emMapi.ty*2;								nRssi5.v2.x = mcax * 0.5;								nRssi5.v2.y = mcay * 0.5;								nRssi5.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi5, v0i, v1i, nRssi5.v2, nIndexi5);																renderRecMapi5.b += emMapi.a;								renderRecMapi5.d += emMapi.c;								renderRecMapi5.ty += emMapi.tx-1;								renderRec(renderRecMapi5, nRssi5.v2, v1i, v2i, nIndexi5);																return;							}							renderRecMapi5.a = emMapi.a-emMapi.b;							renderRecMapi5.b = emMapi.b*2;							renderRecMapi5.c = emMapi.c-emMapi.d;							renderRecMapi5.d = emMapi.d*2;							renderRecMapi5.tx = emMapi.tx-emMapi.ty;							renderRecMapi5.ty = emMapi.ty*2;														nRssi5.v1.x = mbcx * 0.5;							nRssi5.v1.y = mbcy * 0.5;							nRssi5.v1.z = (bz+cz)*0.5;							renderRec(renderRecMapi5, v0i, v1i, nRssi5.v1, nIndexi5);														renderRecMapi5.a = emMapi.a*2;							renderRecMapi5.b = emMapi.b-emMapi.a;							renderRecMapi5.c = emMapi.c*2;							renderRecMapi5.d = emMapi.d-emMapi.c;							renderRecMapi5.tx = emMapi.tx*2;							renderRecMapi5.ty = emMapi.ty-emMapi.tx;							renderRec(renderRecMapi5, v0i, nRssi5.v1, v2i, nIndexi5);/// END INTERNAL RECURSION
            
                return;
            }

            if (d2ca == dmax){
            	
            	renderRecMap.a = emMap.a;
				renderRecMap.b = emMap.b*2;
				renderRecMap.c = emMap.c;
				renderRecMap.d = emMap.d*2;
				renderRecMap.tx = emMap.tx;
				renderRecMap.ty = emMap.ty*2;
				nRss.v2.x = mcax * 0.5;
				nRss.v2.y = mcay * 0.5;
				nRss.v2.z = (cz+az) * 0.5;
                //renderRec(renderRecMap, v0, v1, nRss.v2, nIndex);				//renderRec(emMap:Matrix, v0:Vertex3DInstance, v1:Vertex3DInstance, v2:Vertex3DInstance, index:Number)				emMapi = renderRecMap;				v0i =  v0;				v1i =  v1;				v2i =  nRss.v2;				indexi = nIndex;								/// INTERNAL RECURSION							az = v0i.z;							bz = v1i.z;							cz = v2i.z;														//Cull if a vertex behind near.							if((az <= 0) && (bz <= 0) && (cz <= 0))								return;														cx = v2i.x;							cy = v2i.y;							bx = v1i.x;							by = v1i.y;							ax = v0i.x;							ay = v0i.y;														//Cull if outside of viewport.							if(cullRect){								hitRect.x = (bx < ax ? (bx < cx ? bx : cx) : (ax < cx ? ax : cx ));								hitRect.width = (bx > ax ? (bx > cx ? bx : cx) : (ax > cx ? ax : cx )) + (hitRect.x < 0 ? -hitRect.x : hitRect.x);								hitRect.y = (by < ay ? (by < cy ? by : cy) : (ay < cy ? ay : cy ));								hitRect.height = (by > ay ? (by > cy ? by : cy) : (ay > cy ? ay : cy )) + (hitRect.y < 0 ? -hitRect.y : hitRect.y);								if(!((hitRect.right<cullRect.left)||(hitRect.left>cullRect.right))){									if(!((hitRect.bottom<cullRect.top)||(hitRect.top>cullRect.bottom))){																		}else{										return;									}								}else{									return;								}							}														//cull if max iterations is reached, focus is invalid or if tesselation is to small.							if (indexi >= 100 || (hitRect.width < minimumRenderSize) || (hitRect.height < minimumRenderSize) || (focus == Infinity))							{																//Draw this triangle.								a2 = v1i.x - v0i.x;								b2 = v1i.y - v0i.y;								c2 = v2i.x - v0i.x;								d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}																tempPreRSD.renderStatistics.triangles++;								return;							}														faz = focus + az;							fbz = focus + bz;							fcz = focus + cz;							mabz = 2 / (faz + fbz);							mbcz = 2 / (fbz + fcz);							mcaz = 2 / (fcz + faz);							mabx = (ax*faz + bx*fbz)*mabz;							maby = (ay*faz + by*fbz)*mabz;							mbcx = (bx*fbz + cx*fcz)*mbcz;							mbcy = (by*fbz + cy*fcz)*mbcz;							mcax = (cx*fcz + ax*faz)*mcaz;							mcay = (cy*fcz + ay*faz)*mcaz;							dabx = ax + bx - mabx;							daby = ay + by - maby;							dbcx = bx + cx - mbcx;							dbcy = by + cy - mbcy;							dcax = cx + ax - mcax;							dcay = cy + ay - mcay;							dsab = (dabx*dabx + daby*daby);							dsbc = (dbcx*dbcx + dbcy*dbcy);							dsca = (dcax*dcax + dcay*dcay);														var nIndexi6:int = indexi+1;							var nRssi6:RenderRecStorage = RenderRecStorage(renderRecStorage[int(indexi)]);							var renderRecMapi6:Matrix = nRssi6.mat;														if ((dsab <= _precision) && (dsca <= _precision) && (dsbc <= _precision)){							   //Draw this triangle.							   a2 = v1i.x - v0i.x;							   b2 = v1i.y - v0i.y;							   c2 = v2i.x - v0i.x;							   d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}							   							   							   tempPreRSD.renderStatistics.triangles++;							   return;							}														if ((dsab > _precision) && (dsca > _precision) && (dsbc > _precision)){								renderRecMapi6.a = emMapi.a*2;								renderRecMapi6.b = emMapi.b*2;								renderRecMapi6.c = emMapi.c*2;								renderRecMapi6.d = emMapi.d*2;								renderRecMapi6.tx = emMapi.tx*2;								renderRecMapi6.ty = emMapi.ty*2;																		nRssi6.v0.x = mabx * 0.5;								nRssi6.v0.y = maby * 0.5;								nRssi6.v0.z = (az+bz) * 0.5;																nRssi6.v1.x = mbcx * 0.5;								nRssi6.v1.y = mbcy * 0.5;								nRssi6.v1.z = (bz+cz) * 0.5;																nRssi6.v2.x = mcax * 0.5;								nRssi6.v2.y = mcay * 0.5;								nRssi6.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi6, v0i, nRssi6.v0, nRssi6.v2, nIndexi6);																renderRecMapi6.tx -=1;								renderRec(renderRecMapi6, nRssi6.v0, v1i, nRssi6.v1, nIndexi6);																renderRecMapi6.ty -=1;								renderRecMapi6.tx = emMapi.tx*2;								renderRec(renderRecMapi6, nRssi6.v2, nRssi6.v1, v2i, nIndexi6);																renderRecMapi6.a = -emMapi.a*2;								renderRecMapi6.b = -emMapi.b*2;								renderRecMapi6.c = -emMapi.c*2;								renderRecMapi6.d = -emMapi.d*2;								renderRecMapi6.tx = -emMapi.tx*2+1;								renderRecMapi6.ty = -emMapi.ty*2+1;								renderRec(renderRecMapi6, nRssi6.v1, nRssi6.v2, nRssi6.v0, nIndexi6);												return;							}											if( precisionMode == PrecisionMode.ORIGINAL )							{								d2ab = dsab;								d2bc = dsbc;								d2ca = dsca;								dmax = (dsca > dsbc ? (dsca > dsab ? dsca : dsab) : (dsbc > dsab ? dsbc : dsab ));							}							else							{								// Calculate best tessellation edge								dx = v0i.x - v1i.x;								dy = v0i.y - v1i.y;								d2ab = dx * dx + dy * dy;																dx = v1i.x - v2i.x;								dy = v1i.y - v2i.y;								d2bc = dx * dx + dy * dy;																dx = v2i.x - v0i.x;								dy = v2i.y - v0i.y;								d2ca = dx * dx + dy * dy;															dmax = (d2ca > d2bc ? (d2ca > d2ab ? d2ca : d2ab) : (d2bc > d2ab ? d2bc : d2ab ));		// dmax = Math.max( d2ab, d2bc, d2ac );							}											// Break triangle along edge							if (d2ab == dmax)							{								renderRecMapi6.a = emMapi.a*2;								renderRecMapi6.b = emMapi.b;								renderRecMapi6.c = emMapi.c*2;								renderRecMapi6.d = emMapi.d;								renderRecMapi6.tx = emMapi.tx*2;								renderRecMapi6.ty = emMapi.ty;								nRssi6.v0.x = mabx * 0.5;								nRssi6.v0.y = maby * 0.5;								nRssi6.v0.z = (az+bz) * 0.5;								renderRec(renderRecMapi6, v0i, nRssi6.v0, v2i, nIndexi6);																renderRecMapi6.a = emMapi.a*2+emMapi.b;								renderRecMapi6.c = 2*emMapi.c+emMapi.d;								renderRecMapi6.tx = emMapi.tx*2+emMapi.ty-1;								renderRec(renderRecMapi6, nRssi6.v0, v1i, v2i, nIndexi6);															return;							}											if (d2ca == dmax){																renderRecMapi6.a = emMapi.a;								renderRecMapi6.b = emMapi.b*2;								renderRecMapi6.c = emMapi.c;								renderRecMapi6.d = emMapi.d*2;								renderRecMapi6.tx = emMapi.tx;								renderRecMapi6.ty = emMapi.ty*2;								nRssi6.v2.x = mcax * 0.5;								nRssi6.v2.y = mcay * 0.5;								nRssi6.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi6, v0i, v1i, nRssi6.v2, nIndexi6);																renderRecMapi6.b += emMapi.a;								renderRecMapi6.d += emMapi.c;								renderRecMapi6.ty += emMapi.tx-1;								renderRec(renderRecMapi6, nRssi6.v2, v1i, v2i, nIndexi6);																return;							}							renderRecMapi6.a = emMapi.a-emMapi.b;							renderRecMapi6.b = emMapi.b*2;							renderRecMapi6.c = emMapi.c-emMapi.d;							renderRecMapi6.d = emMapi.d*2;							renderRecMapi6.tx = emMapi.tx-emMapi.ty;							renderRecMapi6.ty = emMapi.ty*2;														nRssi6.v1.x = mbcx * 0.5;							nRssi6.v1.y = mbcy * 0.5;							nRssi6.v1.z = (bz+cz)*0.5;							renderRec(renderRecMapi6, v0i, v1i, nRssi6.v1, nIndexi6);														renderRecMapi6.a = emMapi.a*2;							renderRecMapi6.b = emMapi.b-emMapi.a;							renderRecMapi6.c = emMapi.c*2;							renderRecMapi6.d = emMapi.d-emMapi.c;							renderRecMapi6.tx = emMapi.tx*2;							renderRecMapi6.ty = emMapi.ty-emMapi.tx;							renderRec(renderRecMapi6, v0i, nRssi6.v1, v2i, nIndexi6);/// END INTERNAL RECURSION				
				
				renderRecMap.b += emMap.a;
				renderRecMap.d += emMap.c;
				renderRecMap.ty += emMap.tx-1;
                //renderRec(renderRecMap, nRss.v2, v1, v2, nIndex);				//renderRec(emMap:Matrix, v0:Vertex3DInstance, v1:Vertex3DInstance, v2:Vertex3DInstance, index:Number)				emMapi = renderRecMap;				v0i =  nRss.v2;				v1i =  v1;				v2i =  v2;				indexi = nIndex;								/// INTERNAL RECURSION							az = v0i.z;							bz = v1i.z;							cz = v2i.z;														//Cull if a vertex behind near.							if((az <= 0) && (bz <= 0) && (cz <= 0))								return;														cx = v2i.x;							cy = v2i.y;							bx = v1i.x;							by = v1i.y;							ax = v0i.x;							ay = v0i.y;														//Cull if outside of viewport.							if(cullRect){								hitRect.x = (bx < ax ? (bx < cx ? bx : cx) : (ax < cx ? ax : cx ));								hitRect.width = (bx > ax ? (bx > cx ? bx : cx) : (ax > cx ? ax : cx )) + (hitRect.x < 0 ? -hitRect.x : hitRect.x);								hitRect.y = (by < ay ? (by < cy ? by : cy) : (ay < cy ? ay : cy ));								hitRect.height = (by > ay ? (by > cy ? by : cy) : (ay > cy ? ay : cy )) + (hitRect.y < 0 ? -hitRect.y : hitRect.y);								if(!((hitRect.right<cullRect.left)||(hitRect.left>cullRect.right))){									if(!((hitRect.bottom<cullRect.top)||(hitRect.top>cullRect.bottom))){																		}else{										return;									}								}else{									return;								}							}														//cull if max iterations is reached, focus is invalid or if tesselation is to small.							if (indexi >= 100 || (hitRect.width < minimumRenderSize) || (hitRect.height < minimumRenderSize) || (focus == Infinity))							{																//Draw this triangle.								a2 = v1i.x - v0i.x;								b2 = v1i.y - v0i.y;								c2 = v2i.x - v0i.x;								d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}																tempPreRSD.renderStatistics.triangles++;								return;							}														faz = focus + az;							fbz = focus + bz;							fcz = focus + cz;							mabz = 2 / (faz + fbz);							mbcz = 2 / (fbz + fcz);							mcaz = 2 / (fcz + faz);							mabx = (ax*faz + bx*fbz)*mabz;							maby = (ay*faz + by*fbz)*mabz;							mbcx = (bx*fbz + cx*fcz)*mbcz;							mbcy = (by*fbz + cy*fcz)*mbcz;							mcax = (cx*fcz + ax*faz)*mcaz;							mcay = (cy*fcz + ay*faz)*mcaz;							dabx = ax + bx - mabx;							daby = ay + by - maby;							dbcx = bx + cx - mbcx;							dbcy = by + cy - mbcy;							dcax = cx + ax - mcax;							dcay = cy + ay - mcay;							dsab = (dabx*dabx + daby*daby);							dsbc = (dbcx*dbcx + dbcy*dbcy);							dsca = (dcax*dcax + dcay*dcay);														var nIndexi7:int = indexi+1;							var nRssi7:RenderRecStorage = RenderRecStorage(renderRecStorage[int(indexi)]);							var renderRecMapi7:Matrix = nRssi7.mat;														if ((dsab <= _precision) && (dsca <= _precision) && (dsbc <= _precision)){							   //Draw this triangle.							   a2 = v1i.x - v0i.x;							   b2 = v1i.y - v0i.y;							   c2 = v2i.x - v0i.x;							   d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}							   							   							   tempPreRSD.renderStatistics.triangles++;							   return;							}														if ((dsab > _precision) && (dsca > _precision) && (dsbc > _precision)){								renderRecMapi7.a = emMapi.a*2;								renderRecMapi7.b = emMapi.b*2;								renderRecMapi7.c = emMapi.c*2;								renderRecMapi7.d = emMapi.d*2;								renderRecMapi7.tx = emMapi.tx*2;								renderRecMapi7.ty = emMapi.ty*2;																		nRssi7.v0.x = mabx * 0.5;								nRssi7.v0.y = maby * 0.5;								nRssi7.v0.z = (az+bz) * 0.5;																nRssi7.v1.x = mbcx * 0.5;								nRssi7.v1.y = mbcy * 0.5;								nRssi7.v1.z = (bz+cz) * 0.5;																nRssi7.v2.x = mcax * 0.5;								nRssi7.v2.y = mcay * 0.5;								nRssi7.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi7, v0i, nRssi7.v0, nRssi7.v2, nIndexi7);																renderRecMapi7.tx -=1;								renderRec(renderRecMapi7, nRssi7.v0, v1i, nRssi7.v1, nIndexi7);																renderRecMapi7.ty -=1;								renderRecMapi7.tx = emMapi.tx*2;								renderRec(renderRecMapi7, nRssi7.v2, nRssi7.v1, v2i, nIndexi7);																renderRecMapi7.a = -emMapi.a*2;								renderRecMapi7.b = -emMapi.b*2;								renderRecMapi7.c = -emMapi.c*2;								renderRecMapi7.d = -emMapi.d*2;								renderRecMapi7.tx = -emMapi.tx*2+1;								renderRecMapi7.ty = -emMapi.ty*2+1;								renderRec(renderRecMapi7, nRssi7.v1, nRssi7.v2, nRssi7.v0, nIndexi7);												return;							}											if( precisionMode == PrecisionMode.ORIGINAL )							{								d2ab = dsab;								d2bc = dsbc;								d2ca = dsca;								dmax = (dsca > dsbc ? (dsca > dsab ? dsca : dsab) : (dsbc > dsab ? dsbc : dsab ));							}							else							{								// Calculate best tessellation edge								dx = v0i.x - v1i.x;								dy = v0i.y - v1i.y;								d2ab = dx * dx + dy * dy;																dx = v1i.x - v2i.x;								dy = v1i.y - v2i.y;								d2bc = dx * dx + dy * dy;																dx = v2i.x - v0i.x;								dy = v2i.y - v0i.y;								d2ca = dx * dx + dy * dy;															dmax = (d2ca > d2bc ? (d2ca > d2ab ? d2ca : d2ab) : (d2bc > d2ab ? d2bc : d2ab ));		// dmax = Math.max( d2ab, d2bc, d2ac );							}											// Break triangle along edge							if (d2ab == dmax)							{								renderRecMapi7.a = emMapi.a*2;								renderRecMapi7.b = emMapi.b;								renderRecMapi7.c = emMapi.c*2;								renderRecMapi7.d = emMapi.d;								renderRecMapi7.tx = emMapi.tx*2;								renderRecMapi7.ty = emMapi.ty;								nRssi7.v0.x = mabx * 0.5;								nRssi7.v0.y = maby * 0.5;								nRssi7.v0.z = (az+bz) * 0.5;								renderRec(renderRecMapi7, v0i, nRssi7.v0, v2i, nIndexi7);																renderRecMapi7.a = emMapi.a*2+emMapi.b;								renderRecMapi7.c = 2*emMapi.c+emMapi.d;								renderRecMapi7.tx = emMapi.tx*2+emMapi.ty-1;								renderRec(renderRecMapi7, nRssi7.v0, v1i, v2i, nIndexi7);															return;							}											if (d2ca == dmax){																renderRecMapi7.a = emMapi.a;								renderRecMapi7.b = emMapi.b*2;								renderRecMapi7.c = emMapi.c;								renderRecMapi7.d = emMapi.d*2;								renderRecMapi7.tx = emMapi.tx;								renderRecMapi7.ty = emMapi.ty*2;								nRssi7.v2.x = mcax * 0.5;								nRssi7.v2.y = mcay * 0.5;								nRssi7.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi7, v0i, v1i, nRssi7.v2, nIndexi7);																renderRecMapi7.b += emMapi.a;								renderRecMapi7.d += emMapi.c;								renderRecMapi7.ty += emMapi.tx-1;								renderRec(renderRecMapi7, nRssi7.v2, v1i, v2i, nIndexi7);																return;							}							renderRecMapi7.a = emMapi.a-emMapi.b;							renderRecMapi7.b = emMapi.b*2;							renderRecMapi7.c = emMapi.c-emMapi.d;							renderRecMapi7.d = emMapi.d*2;							renderRecMapi7.tx = emMapi.tx-emMapi.ty;							renderRecMapi7.ty = emMapi.ty*2;														nRssi7.v1.x = mbcx * 0.5;							nRssi7.v1.y = mbcy * 0.5;							nRssi7.v1.z = (bz+cz)*0.5;							renderRec(renderRecMapi7, v0i, v1i, nRssi7.v1, nIndexi7);														renderRecMapi7.a = emMapi.a*2;							renderRecMapi7.b = emMapi.b-emMapi.a;							renderRecMapi7.c = emMapi.c*2;							renderRecMapi7.d = emMapi.d-emMapi.c;							renderRecMapi7.tx = emMapi.tx*2;							renderRecMapi7.ty = emMapi.ty-emMapi.tx;							renderRec(renderRecMapi7, v0i, nRssi7.v1, v2i, nIndexi7);/// END INTERNAL RECURSION
            	
                return;
            }
            renderRecMap.a = emMap.a-emMap.b;
			renderRecMap.b = emMap.b*2;
			renderRecMap.c = emMap.c-emMap.d;
			renderRecMap.d = emMap.d*2;
			renderRecMap.tx = emMap.tx-emMap.ty;
			renderRecMap.ty = emMap.ty*2;
			
			nRss.v1.x = mbcx * 0.5;
			nRss.v1.y = mbcy * 0.5;
			nRss.v1.z = (bz+cz)*0.5;
            //renderRec(renderRecMap, v0, v1, nRss.v1, nIndex);			//renderRec(emMap:Matrix, v0:Vertex3DInstance, v1:Vertex3DInstance, v2:Vertex3DInstance, index:Number)			emMapi = renderRecMap;			v0i =  v0;			v1i =  v1;			v2i =  nRss.v1;			indexi = nIndex;						/// INTERNAL RECURSION							az = v0i.z;							bz = v1i.z;							cz = v2i.z;														//Cull if a vertex behind near.							if((az <= 0) && (bz <= 0) && (cz <= 0))								return;														cx = v2i.x;							cy = v2i.y;							bx = v1i.x;							by = v1i.y;							ax = v0i.x;							ay = v0i.y;														//Cull if outside of viewport.							if(cullRect){								hitRect.x = (bx < ax ? (bx < cx ? bx : cx) : (ax < cx ? ax : cx ));								hitRect.width = (bx > ax ? (bx > cx ? bx : cx) : (ax > cx ? ax : cx )) + (hitRect.x < 0 ? -hitRect.x : hitRect.x);								hitRect.y = (by < ay ? (by < cy ? by : cy) : (ay < cy ? ay : cy ));								hitRect.height = (by > ay ? (by > cy ? by : cy) : (ay > cy ? ay : cy )) + (hitRect.y < 0 ? -hitRect.y : hitRect.y);								if(!((hitRect.right<cullRect.left)||(hitRect.left>cullRect.right))){									if(!((hitRect.bottom<cullRect.top)||(hitRect.top>cullRect.bottom))){																		}else{										return;									}								}else{									return;								}							}														//cull if max iterations is reached, focus is invalid or if tesselation is to small.							if (indexi >= 100 || (hitRect.width < minimumRenderSize) || (hitRect.height < minimumRenderSize) || (focus == Infinity))							{																//Draw this triangle.								a2 = v1i.x - v0i.x;								b2 = v1i.y - v0i.y;								c2 = v2i.x - v0i.x;								d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}																tempPreRSD.renderStatistics.triangles++;								return;							}														faz = focus + az;							fbz = focus + bz;							fcz = focus + cz;							mabz = 2 / (faz + fbz);							mbcz = 2 / (fbz + fcz);							mcaz = 2 / (fcz + faz);							mabx = (ax*faz + bx*fbz)*mabz;							maby = (ay*faz + by*fbz)*mabz;							mbcx = (bx*fbz + cx*fcz)*mbcz;							mbcy = (by*fbz + cy*fcz)*mbcz;							mcax = (cx*fcz + ax*faz)*mcaz;							mcay = (cy*fcz + ay*faz)*mcaz;							dabx = ax + bx - mabx;							daby = ay + by - maby;							dbcx = bx + cx - mbcx;							dbcy = by + cy - mbcy;							dcax = cx + ax - mcax;							dcay = cy + ay - mcay;							dsab = (dabx*dabx + daby*daby);							dsbc = (dbcx*dbcx + dbcy*dbcy);							dsca = (dcax*dcax + dcay*dcay);														var nIndexi8:int = indexi+1;							var nRssi8:RenderRecStorage = RenderRecStorage(renderRecStorage[int(indexi)]);							var renderRecMapi8:Matrix = nRssi8.mat;														if ((dsab <= _precision) && (dsca <= _precision) && (dsbc <= _precision)){							   //Draw this triangle.							   a2 = v1i.x - v0i.x;							   b2 = v1i.y - v0i.y;							   c2 = v2i.x - v0i.x;							   d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}							   							   							   tempPreRSD.renderStatistics.triangles++;							   return;							}														if ((dsab > _precision) && (dsca > _precision) && (dsbc > _precision)){								renderRecMapi8.a = emMapi.a*2;								renderRecMapi8.b = emMapi.b*2;								renderRecMapi8.c = emMapi.c*2;								renderRecMapi8.d = emMapi.d*2;								renderRecMapi8.tx = emMapi.tx*2;								renderRecMapi8.ty = emMapi.ty*2;																		nRssi8.v0.x = mabx * 0.5;								nRssi8.v0.y = maby * 0.5;								nRssi8.v0.z = (az+bz) * 0.5;																nRssi8.v1.x = mbcx * 0.5;								nRssi8.v1.y = mbcy * 0.5;								nRssi8.v1.z = (bz+cz) * 0.5;																nRssi8.v2.x = mcax * 0.5;								nRssi8.v2.y = mcay * 0.5;								nRssi8.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi8, v0i, nRssi8.v0, nRssi8.v2, nIndexi8);																renderRecMapi8.tx -=1;								renderRec(renderRecMapi8, nRssi8.v0, v1i, nRssi8.v1, nIndexi8);																renderRecMapi8.ty -=1;								renderRecMapi8.tx = emMapi.tx*2;								renderRec(renderRecMapi8, nRssi8.v2, nRssi8.v1, v2i, nIndexi8);																renderRecMapi8.a = -emMapi.a*2;								renderRecMapi8.b = -emMapi.b*2;								renderRecMapi8.c = -emMapi.c*2;								renderRecMapi8.d = -emMapi.d*2;								renderRecMapi8.tx = -emMapi.tx*2+1;								renderRecMapi8.ty = -emMapi.ty*2+1;								renderRec(renderRecMapi8, nRssi8.v1, nRssi8.v2, nRssi8.v0, nIndexi8);												return;							}											if( precisionMode == PrecisionMode.ORIGINAL )							{								d2ab = dsab;								d2bc = dsbc;								d2ca = dsca;								dmax = (dsca > dsbc ? (dsca > dsab ? dsca : dsab) : (dsbc > dsab ? dsbc : dsab ));							}							else							{								// Calculate best tessellation edge								dx = v0i.x - v1i.x;								dy = v0i.y - v1i.y;								d2ab = dx * dx + dy * dy;																dx = v1i.x - v2i.x;								dy = v1i.y - v2i.y;								d2bc = dx * dx + dy * dy;																dx = v2i.x - v0i.x;								dy = v2i.y - v0i.y;								d2ca = dx * dx + dy * dy;															dmax = (d2ca > d2bc ? (d2ca > d2ab ? d2ca : d2ab) : (d2bc > d2ab ? d2bc : d2ab ));		// dmax = Math.max( d2ab, d2bc, d2ac );							}											// Break triangle along edge							if (d2ab == dmax)							{								renderRecMapi8.a = emMapi.a*2;								renderRecMapi8.b = emMapi.b;								renderRecMapi8.c = emMapi.c*2;								renderRecMapi8.d = emMapi.d;								renderRecMapi8.tx = emMapi.tx*2;								renderRecMapi8.ty = emMapi.ty;								nRssi8.v0.x = mabx * 0.5;								nRssi8.v0.y = maby * 0.5;								nRssi8.v0.z = (az+bz) * 0.5;								renderRec(renderRecMapi8, v0i, nRssi8.v0, v2i, nIndexi8);																renderRecMapi8.a = emMapi.a*2+emMapi.b;								renderRecMapi8.c = 2*emMapi.c+emMapi.d;								renderRecMapi8.tx = emMapi.tx*2+emMapi.ty-1;								renderRec(renderRecMapi8, nRssi8.v0, v1i, v2i, nIndexi8);															return;							}											if (d2ca == dmax){																renderRecMapi8.a = emMapi.a;								renderRecMapi8.b = emMapi.b*2;								renderRecMapi8.c = emMapi.c;								renderRecMapi8.d = emMapi.d*2;								renderRecMapi8.tx = emMapi.tx;								renderRecMapi8.ty = emMapi.ty*2;								nRssi8.v2.x = mcax * 0.5;								nRssi8.v2.y = mcay * 0.5;								nRssi8.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi8, v0i, v1i, nRssi8.v2, nIndexi8);																renderRecMapi8.b += emMapi.a;								renderRecMapi8.d += emMapi.c;								renderRecMapi8.ty += emMapi.tx-1;								renderRec(renderRecMapi8, nRssi8.v2, v1i, v2i, nIndexi8);																return;							}							renderRecMapi8.a = emMapi.a-emMapi.b;							renderRecMapi8.b = emMapi.b*2;							renderRecMapi8.c = emMapi.c-emMapi.d;							renderRecMapi8.d = emMapi.d*2;							renderRecMapi8.tx = emMapi.tx-emMapi.ty;							renderRecMapi8.ty = emMapi.ty*2;														nRssi8.v1.x = mbcx * 0.5;							nRssi8.v1.y = mbcy * 0.5;							nRssi8.v1.z = (bz+cz)*0.5;							renderRec(renderRecMapi8, v0i, v1i, nRssi8.v1, nIndexi8);														renderRecMapi8.a = emMapi.a*2;							renderRecMapi8.b = emMapi.b-emMapi.a;							renderRecMapi8.c = emMapi.c*2;							renderRecMapi8.d = emMapi.d-emMapi.c;							renderRecMapi8.tx = emMapi.tx*2;							renderRecMapi8.ty = emMapi.ty-emMapi.tx;							renderRec(renderRecMapi8, v0i, nRssi8.v1, v2i, nIndexi8);/// END INTERNAL RECURSION
			
			renderRecMap.a = emMap.a*2;
			renderRecMap.b = emMap.b-emMap.a;
			renderRecMap.c = emMap.c*2;
			renderRecMap.d = emMap.d-emMap.c;
			renderRecMap.tx = emMap.tx*2;
			renderRecMap.ty = emMap.ty-emMap.tx;
            //renderRec(renderRecMap, v0, nRss.v1, v2, nIndex);			//renderRec(emMap:Matrix, v0:Vertex3DInstance, v1:Vertex3DInstance, v2:Vertex3DInstance, index:Number)			emMapi = renderRecMap;			v0i =  v0;			v1i =  nRss.v1;			v2i =  v2;			indexi = nIndex;						/// INTERNAL RECURSION							az = v0i.z;							bz = v1i.z;							cz = v2i.z;														//Cull if a vertex behind near.							if((az <= 0) && (bz <= 0) && (cz <= 0))								return;														cx = v2i.x;							cy = v2i.y;							bx = v1i.x;							by = v1i.y;							ax = v0i.x;							ay = v0i.y;														//Cull if outside of viewport.							if(cullRect){								hitRect.x = (bx < ax ? (bx < cx ? bx : cx) : (ax < cx ? ax : cx ));								hitRect.width = (bx > ax ? (bx > cx ? bx : cx) : (ax > cx ? ax : cx )) + (hitRect.x < 0 ? -hitRect.x : hitRect.x);								hitRect.y = (by < ay ? (by < cy ? by : cy) : (ay < cy ? ay : cy ));								hitRect.height = (by > ay ? (by > cy ? by : cy) : (ay > cy ? ay : cy )) + (hitRect.y < 0 ? -hitRect.y : hitRect.y);								if(!((hitRect.right<cullRect.left)||(hitRect.left>cullRect.right))){									if(!((hitRect.bottom<cullRect.top)||(hitRect.top>cullRect.bottom))){																		}else{										return;									}								}else{									return;								}							}														//cull if max iterations is reached, focus is invalid or if tesselation is to small.							if (indexi >= 100 || (hitRect.width < minimumRenderSize) || (hitRect.height < minimumRenderSize) || (focus == Infinity))							{																//Draw this triangle.								a2 = v1i.x - v0i.x;								b2 = v1i.y - v0i.y;								c2 = v2i.x - v0i.x;								d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}																tempPreRSD.renderStatistics.triangles++;								return;							}														faz = focus + az;							fbz = focus + bz;							fcz = focus + cz;							mabz = 2 / (faz + fbz);							mbcz = 2 / (fbz + fcz);							mcaz = 2 / (fcz + faz);							mabx = (ax*faz + bx*fbz)*mabz;							maby = (ay*faz + by*fbz)*mabz;							mbcx = (bx*fbz + cx*fcz)*mbcz;							mbcy = (by*fbz + cy*fcz)*mbcz;							mcax = (cx*fcz + ax*faz)*mcaz;							mcay = (cy*fcz + ay*faz)*mcaz;							dabx = ax + bx - mabx;							daby = ay + by - maby;							dbcx = bx + cx - mbcx;							dbcy = by + cy - mbcy;							dcax = cx + ax - mcax;							dcay = cy + ay - mcay;							dsab = (dabx*dabx + daby*daby);							dsbc = (dbcx*dbcx + dbcy*dbcy);							dsca = (dcax*dcax + dcay*dcay);														var nIndexi9:int = indexi+1;							var nRssi9:RenderRecStorage = RenderRecStorage(renderRecStorage[int(indexi)]);							var renderRecMapi9:Matrix = nRssi9.mat;														if ((dsab <= _precision) && (dsca <= _precision) && (dsbc <= _precision)){							   //Draw this triangle.							   a2 = v1i.x - v0i.x;							   b2 = v1i.y - v0i.y;							   c2 = v2i.x - v0i.x;							   d2 = v2i.y - v0i.y;																		tempTriangleMatrix.a = emMapi.a*a2 + emMapi.b*c2;								tempTriangleMatrix.b = emMapi.a*b2 + emMapi.b*d2;								tempTriangleMatrix.c = emMapi.c*a2 + emMapi.d*c2;								tempTriangleMatrix.d = emMapi.c*b2 + emMapi.d*d2;								tempTriangleMatrix.tx = emMapi.tx*a2 + emMapi.ty*c2 + v0i.x;   								tempTriangleMatrix.ty = emMapi.tx*b2 + emMapi.ty*d2 + v0i.y;       																if(lineAlpha){									tempPreGrp.lineStyle( lineThickness, lineColor, lineAlpha );								}								tempPreGrp.beginBitmapFill(tempPreBmp, tempTriangleMatrix, tiled, smooth);								tempPreGrp.moveTo(v0i.x, v0i.y);								tempPreGrp.lineTo(v1i.x, v1i.y);								tempPreGrp.lineTo(v2i.x, v2i.y);								tempPreGrp.endFill();								if(lineAlpha){									tempPreGrp.lineStyle();								}							   							   							   tempPreRSD.renderStatistics.triangles++;							   return;							}														if ((dsab > _precision) && (dsca > _precision) && (dsbc > _precision)){								renderRecMapi9.a = emMapi.a*2;								renderRecMapi9.b = emMapi.b*2;								renderRecMapi9.c = emMapi.c*2;								renderRecMapi9.d = emMapi.d*2;								renderRecMapi9.tx = emMapi.tx*2;								renderRecMapi9.ty = emMapi.ty*2;																		nRssi9.v0.x = mabx * 0.5;								nRssi9.v0.y = maby * 0.5;								nRssi9.v0.z = (az+bz) * 0.5;																nRssi9.v1.x = mbcx * 0.5;								nRssi9.v1.y = mbcy * 0.5;								nRssi9.v1.z = (bz+cz) * 0.5;																nRssi9.v2.x = mcax * 0.5;								nRssi9.v2.y = mcay * 0.5;								nRssi9.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi9, v0i, nRssi9.v0, nRssi9.v2, nIndexi9);																renderRecMapi9.tx -=1;								renderRec(renderRecMapi9, nRssi9.v0, v1i, nRssi9.v1, nIndexi9);																renderRecMapi9.ty -=1;								renderRecMapi9.tx = emMapi.tx*2;								renderRec(renderRecMapi9, nRssi9.v2, nRssi9.v1, v2i, nIndexi9);																renderRecMapi9.a = -emMapi.a*2;								renderRecMapi9.b = -emMapi.b*2;								renderRecMapi9.c = -emMapi.c*2;								renderRecMapi9.d = -emMapi.d*2;								renderRecMapi9.tx = -emMapi.tx*2+1;								renderRecMapi9.ty = -emMapi.ty*2+1;								renderRec(renderRecMapi9, nRssi9.v1, nRssi9.v2, nRssi9.v0, nIndexi9);												return;							}											if( precisionMode == PrecisionMode.ORIGINAL )							{								d2ab = dsab;								d2bc = dsbc;								d2ca = dsca;								dmax = (dsca > dsbc ? (dsca > dsab ? dsca : dsab) : (dsbc > dsab ? dsbc : dsab ));							}							else							{								// Calculate best tessellation edge								dx = v0i.x - v1i.x;								dy = v0i.y - v1i.y;								d2ab = dx * dx + dy * dy;																dx = v1i.x - v2i.x;								dy = v1i.y - v2i.y;								d2bc = dx * dx + dy * dy;																dx = v2i.x - v0i.x;								dy = v2i.y - v0i.y;								d2ca = dx * dx + dy * dy;															dmax = (d2ca > d2bc ? (d2ca > d2ab ? d2ca : d2ab) : (d2bc > d2ab ? d2bc : d2ab ));		// dmax = Math.max( d2ab, d2bc, d2ac );							}											// Break triangle along edge							if (d2ab == dmax)							{								renderRecMapi9.a = emMapi.a*2;								renderRecMapi9.b = emMapi.b;								renderRecMapi9.c = emMapi.c*2;								renderRecMapi9.d = emMapi.d;								renderRecMapi9.tx = emMapi.tx*2;								renderRecMapi9.ty = emMapi.ty;								nRssi9.v0.x = mabx * 0.5;								nRssi9.v0.y = maby * 0.5;								nRssi9.v0.z = (az+bz) * 0.5;								renderRec(renderRecMapi9, v0i, nRssi9.v0, v2i, nIndexi9);																renderRecMapi9.a = emMapi.a*2+emMapi.b;								renderRecMapi9.c = 2*emMapi.c+emMapi.d;								renderRecMapi9.tx = emMapi.tx*2+emMapi.ty-1;								renderRec(renderRecMapi9, nRssi9.v0, v1i, v2i, nIndexi9);															return;							}											if (d2ca == dmax){																renderRecMapi9.a = emMapi.a;								renderRecMapi9.b = emMapi.b*2;								renderRecMapi9.c = emMapi.c;								renderRecMapi9.d = emMapi.d*2;								renderRecMapi9.tx = emMapi.tx;								renderRecMapi9.ty = emMapi.ty*2;								nRssi9.v2.x = mcax * 0.5;								nRssi9.v2.y = mcay * 0.5;								nRssi9.v2.z = (cz+az) * 0.5;								renderRec(renderRecMapi9, v0i, v1i, nRssi9.v2, nIndexi9);																renderRecMapi9.b += emMapi.a;								renderRecMapi9.d += emMapi.c;								renderRecMapi9.ty += emMapi.tx-1;								renderRec(renderRecMapi9, nRssi9.v2, v1i, v2i, nIndexi9);																return;							}							renderRecMapi9.a = emMapi.a-emMapi.b;							renderRecMapi9.b = emMapi.b*2;							renderRecMapi9.c = emMapi.c-emMapi.d;							renderRecMapi9.d = emMapi.d*2;							renderRecMapi9.tx = emMapi.tx-emMapi.ty;							renderRecMapi9.ty = emMapi.ty*2;														nRssi9.v1.x = mbcx * 0.5;							nRssi9.v1.y = mbcy * 0.5;							nRssi9.v1.z = (bz+cz)*0.5;							renderRec(renderRecMapi9, v0i, v1i, nRssi9.v1, nIndexi9);														renderRecMapi9.a = emMapi.a*2;							renderRecMapi9.b = emMapi.b-emMapi.a;							renderRecMapi9.c = emMapi.c*2;							renderRecMapi9.d = emMapi.d-emMapi.c;							renderRecMapi9.tx = emMapi.tx*2;							renderRecMapi9.ty = emMapi.ty-emMapi.tx;							renderRec(renderRecMapi9, v0i, nRssi9.v1, v2i, nIndexi9);/// END INTERNAL RECURSION			
        }

		/**
		* Returns a string value representing the material properties in the specified BitmapMaterial object.
		*
		* @return	A string.
		*/
		public override function toString(): String
		{
			return 'Texture:' + this.texture + ' lineColor:' + this.lineColor + ' lineAlpha:' + this.lineAlpha;
		}


		// ______________________________________________________________________ CREATE BITMAP

		protected function createBitmap( asset:BitmapData ):BitmapData
		{		
			resetMapping();

			var bm:BitmapData;
			
			if( AUTO_MIP_MAPPING )
			{
				bm = correctBitmap( asset );
			}
			else
			{
				this.maxU = this.maxV = 1;

				bm = asset;
			}
			
			return bm;
		}


		// ______________________________________________________________________ CORRECT BITMAP FOR MIP MAPPING

		protected function correctBitmap( bitmap :BitmapData ):BitmapData
		{
			var okBitmap :BitmapData;

			var levels :Number = 1 << MIP_MAP_DEPTH;
			// this is faster than Math.ceil
			var bWidth :Number = bitmap.width  / levels;
			bWidth = bWidth == uint(bWidth) ? bWidth : uint(bWidth)+1;
			var bHeight :Number = bitmap.height  / levels;
			bHeight = bHeight == uint(bHeight) ? bHeight : uint(bHeight)+1;
			
			var width  :Number = levels * bWidth;
			var height :Number = levels * bHeight;

			// Check for BitmapData maximum size
			var ok:Boolean = true;

			if( width  > 2880 )
			{
				width  = bitmap.width;
				ok = false;
			}

			if( height > 2880 )
			{
				height = bitmap.height;
				ok = false;
			}
			
			if( ! ok ) PaperLogger.warning( "Material " + this.name + ": Texture too big for mip mapping. Resizing recommended for better performance and quality." );

			// Create new bitmap?
			if( bitmap && ( bitmap.width % levels !=0  ||  bitmap.height % levels != 0 ) )
			{
				okBitmap = new BitmapData( width, height, bitmap.transparent, 0x00000000 );

					
				// this is for ISM and offsetting bitmaps that have been resized
				widthOffset = bitmap.width;
				heightOffset = bitmap.height;
				
				this.maxU = bitmap.width / width;
				this.maxV = bitmap.height / height;

				okBitmap.draw( bitmap );

				// PLEASE DO NOT REMOVE
				extendBitmapEdges( okBitmap, bitmap.width, bitmap.height );
			}
			else
			{
				this.maxU = this.maxV = 1;

				okBitmap = bitmap;
			}

			return okBitmap;
		}

		protected function extendBitmapEdges( bmp:BitmapData, originalWidth:Number, originalHeight:Number ):void
		{
			var srcRect  :Rectangle = new Rectangle();
			var dstPoint :Point = new Point();
			
			var i        :int;

			// Check width
			if( bmp.width > originalWidth )
			{
				// Extend width
				srcRect.x      = originalWidth-1;
				srcRect.y      = 0;
				srcRect.width  = 1;
				srcRect.height = originalHeight;
				dstPoint.y     = 0;
				
				for( i = originalWidth; i < bmp.width; i++ )
				{
					dstPoint.x = i;
					bmp.copyPixels( bmp, srcRect, dstPoint );
				}
			}

			// Check height
			if( bmp.height > originalHeight )
			{
				// Extend height
				srcRect.x      = 0;
				srcRect.y      = originalHeight-1;
				srcRect.width  = bmp.width;
				srcRect.height = 1;
				dstPoint.x     = 0;

				for( i = originalHeight; i < bmp.height; i++ )
				{
					dstPoint.y = i;
					bmp.copyPixels( bmp, srcRect, dstPoint );
				}
			}
		}

		// ______________________________________________________________________
		
		
		/**
		 * resetUVMatrices();
		 * 
		 * Resets the precalculated uvmatrices, so they can be recalculated
		 */
		 public function resetUVS():void
		 {
		 	uvMatrices = new Dictionary(false);
		 }
		
		/**
		* Copies the properties of a material.
		*
		* @param	material	Material to copy from.
		*/
		override public function copy( material :MaterialObject3D ):void
		{
			super.copy( material );

			this.maxU = material.maxU;
			this.maxV = material.maxV;
		}

		/**
		* Creates a copy of the material.
		*
		* @return	A newly created material that contains the same properties.
		*/
		override public function clone():MaterialObject3D
		{
			var cloned:MaterialObject3D = super.clone();

			cloned.maxU = this.maxU;
			cloned.maxV = this.maxV;

			return cloned;
		}
		
		/**
		 * Sets the material's precise rendering mode. If set to true, material will adaptively render triangles to conquer texture distortion. 
		 */
		public function set precise(boolean:Boolean):void
		{
			_precise = boolean;
		}
		
		public function get precise():Boolean
		{
			return _precise;
		}
		
		/**
		 * If the material is rendering with @see precise to true, this sets tesselation per pixel ratio.
		 */
		public function set precision(precision:int):void
		{
			_precision = precision;
		}
		
		public function get precision():int
		{
			return _precision;
		}
		
		/**
		 * If the material is rendering with @see precise to true, this sets tesselation per pixel ratio.
		 * 
		 * corrected to set per pixel precision exactly.
		 */
		public function set pixelPrecision(precision:int):void
		{
			_precision = precision*precision*1.4;
			_perPixelPrecision = precision;
		}
		
		public function get pixelPrecision():int
		{
			return _perPixelPrecision;
		}
		
		/**
		* A texture object.
		*/		
		public function get texture():Object
		{
			return this._texture;
		}
		
		/**
		* @private
		*/
		public function set texture( asset:Object ):void
		{
			if( asset is BitmapData == false )
			{
				PaperLogger.error("BitmapMaterial.texture requires a BitmapData object for the texture");
				return;
			}
			
			bitmap   = createBitmap( BitmapData(asset) );
			
			_texture = asset;
		}
		//  modified by zephyr renner: put bitmap.dispose() call in front of super.destroy() call.
		override public function destroy():void
		{
			if(bitmap){
				bitmap.dispose();
			}						super.destroy();
			if(uvMatrices){
				uvMatrices = null;
			}
			
			this.renderRecStorage = null;
		}
			
	}
}