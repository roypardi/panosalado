package zephyr.objects.primitives {
	import org.papervision3d.Papervision3D;
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.Triangle3D;
	import org.papervision3d.core.geom.renderables.Vertex3D;
	import org.papervision3d.core.math.NumberUV;
	import org.papervision3d.core.proto.*;	

	/**
	* The Sphere class lets you create and display spheres.
	* <p/>
	* The sphere is divided in vertical and horizontal segment, the smallest combination is two vertical and three horizontal segments.
	*/
	public class Sphere extends TriangleMesh3D
	{
		/**
		* Number of segments horizontally. Defaults to 8.
		*/
		private var segmentsW :Number;
	
		/**
		* Number of segments vertically. Defaults to 6.
		*/
		private var segmentsH :Number;
		
		/**
		* Minimum pan angle (in degrees) for sphere geometry. Defaults to 0.
		*/
		private var minPan :Number;
		
		/**
		* Range of pan angles (in degrees) for sphere geometry. Defaults to 360.
		*/
		private var panRange :Number;
        
		/**
		* Minimum tilt angle (in degrees) for sphere geometry. Defaults to -90.
		*/
		private var minTilt :Number;
        
		/**
		* Range of tilt angles (in degrees) for sphere geometry. Defaults to 180.
		*/
		private var tiltRange :Number;
        
		/**
		* Reverse
		*/
		private var reverse :Boolean;
	
		/**
		* Default radius of Sphere if not defined.
		*/
		static public var DEFAULT_RADIUS :Number = 100;
	
		/**
		* Default scale of Sphere texture if not defined.
		*/
		static public var DEFAULT_SCALE :Number = 1;
	
		/**
		* Default value of gridX if not defined.
		*/
		static public var DEFAULT_SEGMENTSW :Number = 8;
	
		/**
		* Default value of gridY if not defined.
		*/
		static public var DEFAULT_SEGMENTSH :Number = 6;
	
		/**
		* Minimum value of gridX.
		*/
		static public var MIN_SEGMENTSW :Number = 3;
	
		/**
		* Minimum value of gridY.
		*/
		static public var MIN_SEGMENTSH :Number = 2;
	
	
		// ___________________________________________________________________________________________________
		//                                                                                               N E W
		// NN  NN EEEEEE WW    WW
		// NNN NN EE     WW WW WW
		// NNNNNN EEEE   WWWWWWWW
		// NN NNN EE     WWW  WWW
		// NN  NN EEEEEE WW    WW
	
		/**
		* Create a new Sphere object.
		* <p/>
		* @param	material	A MaterialObject3D object that contains the material properties of the object.
		* <p/>
		* @param	radius		[optional] - Desired radius.
		* <p/>
		* @param	segmentsW	[optional] - Number of segments horizontally. Defaults to 8.
		* <p/>
		* @param	segmentsH	[optional] - Number of segments vertically. Defaults to 6.
		* <p/>
		*/
		public function Sphere( material:MaterialObject3D=null, radius:Number=100, segmentsW:int=8, segmentsH:int=6, reverse:Boolean=true, minPan:Number=0.0, panRange:Number=360.0, minTilt:Number=-90.0, tiltRange:Number=180.0 )
		{
			super( material, new Array(), new Array(), null );
	
			this.segmentsW = Math.max( MIN_SEGMENTSW, segmentsW || DEFAULT_SEGMENTSW); // Defaults to 8
			this.segmentsH = Math.max( MIN_SEGMENTSH, segmentsH || DEFAULT_SEGMENTSH); // Defaults to 6
			if (radius==0) radius = DEFAULT_RADIUS; // Defaults to 100
			
			this.minPan = Math.PI / 180.0 * minPan;
			this.panRange = Math.PI / 180.0 * Math.min(360.0, panRange); // Don't allow range > 360.0
			this.minTilt = Math.PI / 180.0 * minTilt;
			this.tiltRange = Math.PI / 180.0 * Math.min(180.0, Math.max(-180.0, tiltRange)); // -180 <= TiltRange <= 180
			
			this.reverse = reverse;
			
			var scale :Number = DEFAULT_SCALE;
		
			buildSphere( radius );
		}
	
		private function buildSphere( fRadius:Number ):void
		{
			var rev :int = reverse? -1 : 1;
			
			var i:Number, j:Number, k:Number;
			var iHor:Number = Math.max(3,this.segmentsW);
			var iVer:Number = Math.max(2,this.segmentsH);
			var aVertice:Array = this.geometry.vertices;
			var aFace:Array = this.geometry.faces;
			var aVtc:Array = new Array();
			var bZenith:Boolean = (this.minTilt + this.tiltRange >= Math.PI);
			var bNadir:Boolean =  (this.minTilt <= -Math.PI);

			// Sine lookup tables for performance
			var horSinLUT:Array = new Array();
			var horCosLUT:Array = new Array();
			for (i=0;i<iHor;i++) { // horizontal
			    var fRad2:Number = this.minPan + this.panRange*i/iHor;
				horSinLUT.push(Math.sin(fRad2));
				horCosLUT.push(Math.cos(fRad2));
			}
			for (j=0;j<=iVer;j++) { // vertical
				var fRad1:Number = this.minTilt + this.tiltRange*j/iVer;
				var fZ:Number = fRadius*Math.sin(fRad1);
				var fRds:Number = fRadius*Math.cos(fRad1);
				var aRow:Array = new Array();
				var oVtx:Vertex3D;
				for (i=0;i<iHor;i++) { // horizontal
					var fX:Number = fRds*horSinLUT[i];
					var fY:Number = rev*fRds*horCosLUT[i];
					var bMakeVertex:Boolean = true;
					if ((bNadir && j==0) || (bZenith && j==iVer)) {
					    bMakeVertex = (i == 0);
					}
					if (bMakeVertex) {
    					oVtx = new Vertex3D(fY,fZ,fX);
    					aVertice.push(oVtx);
					}
					aRow.push(oVtx);
				}
				aVtc.push(aRow);
			}
			var iVerNum:int = aVtc.length;
			for (j=1;j<iVerNum;j++) {
				var iHorNum:int = aVtc[j].length;
				for (i=0;i<iHorNum;i++) {
					// select vertices
					var aP1:Vertex3D = aVtc[j][i];
					var aP2:Vertex3D = aVtc[j][(i==0?iHorNum:i)-1];
					var aP3:Vertex3D = aVtc[j-1][(i==0?iHorNum:i)-1];
					var aP4:Vertex3D = aVtc[j-1][i];
					// uv
					/*
					 * fix applied as suggested by Philippe to correct the uv mapping on a sphere
					 * */
					var fJ0:Number = j		/ (iVerNum-1);
					var fJ1:Number = (j-1)	/ (iVerNum-1);
					var fI0:Number = (i+1)	/ iHorNum;
					var fI1:Number = i		/ iHorNum;
					var aP4uv:NumberUV = new NumberUV(fI0,fJ1);
					var aP1uv:NumberUV = new NumberUV(fI0,fJ0);
					var aP2uv:NumberUV = new NumberUV(fI1,fJ0);
					var aP3uv:NumberUV = new NumberUV(fI1,fJ1);
					// 2 faces
					if (!bNadir || j<(aVtc.length-1)) aFace.push( new Triangle3D(this, new Array(aP1,aP2,aP3), material, new Array(aP1uv,aP2uv,aP3uv)) );
					if (!bZenith || j>1)			  aFace.push( new Triangle3D(this, new Array(aP1,aP3,aP4), material, new Array(aP1uv,aP3uv,aP4uv)) );
				}
			}
			this.geometry.ready = true;

			if(Papervision3D.useRIGHTHANDED)
				this.geometry.flipFaces();
		}
	}
}