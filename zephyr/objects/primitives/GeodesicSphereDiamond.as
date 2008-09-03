/*
 * Copyright 2007 (c) Gabriel Putnam
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

package zephyr.objects.primitives {
	import org.papervision3d.core.*;
	import org.papervision3d.core.proto.*;
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.Triangle3D;
	import org.papervision3d.core.geom.renderables.Vertex3D;
	import org.papervision3d.core.math.NumberUV;
	
	public class GeodesicSphere extends TriangleMesh3D {
		// Define our constants
		static public var RADIUS_DEFAULT:Number = 100;
		static public var FRACTURES_DEFAULT:int = 2;
		static public var SCALE_DEFAULT:Number = 1;
		public var edgeFractures:int;
		
		public function GeodesicSphere( material:MaterialObject3D=null, radius:Number=100, fractures:int=2 ) {
			super( material, new Array(), new Array(), null );
			if( fractures < 0 ) {
				fractures = FRACTURES_DEFAULT;
			}
			if( radius < 0 ){
				radius = RADIUS_DEFAULT;
			}
			var scale :Number = SCALE_DEFAULT;
			
			edgeFractures = fractures;
			
			buildGeodesicSphere( radius, fractures, material:MaterialObject3D );
		}
		public function buildGeodesicSphere( radius_in:Number, fractures_in:int, material ):void
		{
			// Set up variables for keeping track of the vertices, faces, and texture coords.
			var aVertice:Array = this.geometry.vertices;
			var aFace:Array = this.geometry.faces;
			var aUV:Array = new Array();
			// Set up variables for keeping track of the number of iterations and the angles
			var iVerts:uint = fractures_in + 1, jVerts:uint;
			var i:int=0, j:uint, Theta:Number=0, Phi:Number=0, ThetaDel:Number, PhiDel:Number;
			var cosTheta:Number, sinTheta:Number, rcosPhi:Number, rsinPhi:Number;
			// Set up variables for figuring out the texture coordinates using a diamond ~equal area map projection
			// This is done so that there is the minimal amount of distortion of textures around poles.
			// Visually, this map projection looks like this.
			/*	Phi   /\0,0
				|    /  \
				\/  /    \
				   /      \
				  /        \
				 / 1,0      \0,1
				 \ Theta->  /
				  \        /
				   \      /
				    \    /
					 \  /
					  \/1,1
			*/
			var Pd4:Number = Math.PI / 4, cosPd4:Number = Math.cos(Pd4), sinPd4:Number = Math.sin(Pd4), PIInv:Number = 1/Math.PI;
			var R_00:Number = cosPd4, R_01:Number = -sinPd4, R_10:Number = sinPd4, R_11:Number = cosPd4;
			var Scale:Number = Math.SQRT2, uOff:Number = 0.5, vOff:Number = 0.5;
			var oVtx:Vertex3D, oUV:NumberUV, UU:Number, VV:Number, u:Number, v:Number;
			PhiDel = Math.PI / ( 2 * iVerts);
			// Build the top vertex
			oVtx = new Vertex3D( 0, 0, radius_in );
			aVertice.push( oVtx );
			i++;
			Phi += PhiDel;
			// Build the tops worth of vertices for the sphere progressing in rings around the sphere
			for( i; i <= iVerts; i++ ){
				j = 0;
				jVerts = i*4;
				Theta = 0;
				ThetaDel = 2* Math.PI / jVerts;
				rcosPhi = Math.cos( Phi ) * radius_in;
				rsinPhi = Math.sin( Phi ) * radius_in;
				for( j; j < jVerts; j++ ){
					UU = Theta * PIInv - 0.5;
					VV = ( Phi * PIInv - 1 ) * ( 0.5 - Math.abs( UU ) );
					u = ( UU * R_00 + VV * R_01 ) * Scale + uOff;
					v = ( UU * R_10 + VV * R_11 ) * Scale + vOff;
					cosTheta = Math.cos( Theta );
					sinTheta = Math.sin( Theta );
					oVtx = new Vertex3D( cosTheta * rsinPhi, sinTheta * rsinPhi, rcosPhi );
					oUV = new NumberUV( u, v );
					aVertice.push( oVtx );
					aUV.push( oUV );
					Theta += ThetaDel;
				}
				Phi += PhiDel;
			}
			// Build the bottom worth of vertices for the sphere.
			i = iVerts-1;
			for( i; i >0; i-- ){
				j = 0;
				jVerts = i*4;
				Theta = 0;
				ThetaDel = 2* Math.PI / jVerts;
				rcosPhi = Math.cos( Phi ) * radius_in;
				rsinPhi = Math.sin( Phi ) * radius_in;
				for( j; j < jVerts; j++ ){
					cosTheta = Math.cos( Theta );
					sinTheta = Math.sin( Theta );
					oVtx = new Vertex3D( cosTheta * rsinPhi, sinTheta * rsinPhi, rcosPhi );
					aVertice.push( oVtx );
					Theta += ThetaDel;
				}
				Phi += PhiDel;
			}
			// Build the last vertice
			oVtx = new Vertex3D( 0, 0, -radius_in );
			aVertice.push( oVtx );
			// Build the faces for the sphere
			// Build the upper four sections
			var k:uint, L_Ind_s:uint, U_Ind_s:uint, U_Ind_e:uint, L_Ind_e:uint, L_Ind:uint, U_Ind:uint;
			var isUpTri:Boolean, Pt0:uint, Pt1:uint, Pt2:uint, tPt:uint, triInd:uint, tris:uint;
			tris = 1;
			L_Ind_s = 0; L_Ind_e = 0;
			for( i = 0; i < iVerts; i++ ){
				U_Ind_s = L_Ind_s;
				U_Ind_e = L_Ind_e;
				if( i == 0 ) L_Ind_s++;
				L_Ind_s += 4*i;
				L_Ind_e += 4*(i+1);
				U_Ind = U_Ind_s;
				L_Ind = L_Ind_s;
				for( k = 0; k < 4; k++ ){
					isUpTri = true;
					for( triInd = 0; triInd < tris; triInd++ ){
						if( isUpTri ){
							Pt0 = U_Ind;
							Pt1 = L_Ind;
							L_Ind++;
							if( L_Ind > L_Ind_e ) L_Ind = L_Ind_s;
							Pt2 = L_Ind;
							isUpTri = false;
						} else {
							Pt0 = L_Ind;
							Pt2 = U_Ind;
							U_Ind++;
							if( U_Ind > U_Ind_e ) U_Ind = U_Ind_s;
							Pt1 = U_Ind;
							isUpTri = true;
						}
						aFace.push( new Triangle3D( this, [ aVertice[Pt0],aVertice[Pt1],aVertice[Pt2] ], null, [ aUV[Pt0],aUV[Pt1],aUV[Pt2] ] ) );
					}
				}
				tris += 2;
			}
			U_Ind_s = L_Ind_s; U_Ind_e = L_Ind_e;
			// Build the lower four sections
			for( i = iVerts-1; i >= 0; i-- ){
				L_Ind_s = U_Ind_s; L_Ind_e = U_Ind_e; U_Ind_s = L_Ind_s + 4*(i+1); U_Ind_e = L_Ind_e + 4*i;
				if( i == 0 ) U_Ind_e++;
				tris -= 2;
				U_Ind = U_Ind_s;
				L_Ind = L_Ind_s;
				for( k = 0; k < 4; k++ ){
					isUpTri = true;
					for( triInd = 0; triInd < tris; triInd++ ){
						if( isUpTri ){
							Pt0 = U_Ind;
							Pt1 = L_Ind;
							L_Ind++;
							if( L_Ind > L_Ind_e ) L_Ind = L_Ind_s;
							Pt2 = L_Ind;
							isUpTri = false;
						} else {
							Pt0 = L_Ind;
							Pt2 = U_Ind;
							U_Ind++;
							if( U_Ind > U_Ind_e ) U_Ind = U_Ind_s;
							Pt1 = U_Ind;
							isUpTri = true;
						}
						aFace.push( new Triangle3D( this, [ aVertice[Pt0],aVertice[Pt2],aVertice[Pt1] ], null, [ aUV[Pt0],aUV[Pt2],aUV[Pt1] ] ) );
					}
				}
			}
			this.geometry.ready = true;
		}
	}
}