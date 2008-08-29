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

package zephyr.objects.primitives
{
	import org.papervision3d.core.*;
	import org.papervision3d.core.proto.*;
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.Triangle3D;
	import org.papervision3d.core.geom.renderables.Vertex3D;
	import org.papervision3d.core.math.NumberUV;
	
	/**
	* GeodesicSphere implements octahedron-based geodesic sphere.
	*
	* <p>Compared to regular sphere, this primitive produces geometry with more
	* evenly distributed triangles (code ported from Away3D mostly as is, with
	* the exception of U/V mapping).</p>
	*
	* @author		makc
	* @version		3.0.3
	* @date 		10.04.2008
	*
	* @see http://en.wikipedia.org/wiki/Geodesic_dome
	* @see http://en.wikipedia.org/wiki/Octahedron
	*/
	public class GeodesicSphere extends TriangleMesh3D {
		 
		private var radius_in:Number;
        private var fractures_in:int;
		
		/**
		* Creates a GeodesicSphere primitive.
		*
		* @param p_sName	A string identifier for this object.
		* @param p_nRadius	Sphere radius.
		* @param p_nFractures	Tesselation quality.
		*/
		public function GeodesicSphere ( material:MaterialObject3D=null, p_nRadius : Number = 100, p_nFractures : Number = 2, reverse : Boolean = false)
        {
            super( material, new Array(), new Array(), null );

			radius_in = p_nRadius;
            fractures_in = Math.max (2, p_nFractures);
			 
			buildGeodesicSphere(reverse);
		}
		
		/**
		* @private
		*/
		public function buildGeodesicSphere(reverse:Boolean):void
		{
			var revFaces:Number = reverse ? -1 : 1;
			
			//var l_oGeometry3D:Geometry3D = new Geometry3D();
			var aVertice:Array = this.geometry.vertices;
			var aFace:Array = this.geometry.faces;
			var aUV:Array = new Array();

			// Set up variables for keeping track of the vertices, faces, and texture coords.
			var nVertices:int = 0, nFaces:int = 0;
			var aPacificFaces:Array = [], aVertexNormals:Array = [];
			
			// Set up variables for keeping track of the number of iterations and the angles
			var iVerts:uint = fractures_in + 1, jVerts:uint;
			var j:uint, Theta:Number=0, Phi:Number=0, ThetaDel:Number, PhiDel:Number;
			var cosTheta:Number, sinTheta:Number, cosPhi:Number, sinPhi:Number;

			// Although original code used quite clever diamond projection, let's change it to
			// equirectangular just to see how it performs compared to standard Sphere - makc

			var Pd4:Number = Math.PI / 4, cosPd4:Number = Math.cos(Pd4), sinPd4:Number = Math.sin(Pd4), PIInv:Number = 1/Math.PI;
			var R_00:Number = cosPd4, R_01:Number = -sinPd4, R_10:Number = sinPd4, R_11:Number = cosPd4;
			var z_vtx:Vertex3D, z_uv:NumberUV;

			PhiDel = Math.PI / ( 2 * iVerts);

			Phi += PhiDel;

			// Build vertices for the sphere progressing in rings around the sphere
			var i:int, q:int, aI:Array = [];
			for (q = 1; q <= iVerts; q++) aI.push (q);
			for (q = iVerts -1; q > 0; q--) aI.push (q);

			for (q = 0; q < aI.length; q++) {
				i = aI[q]; j = 0; jVerts = i*4;
				Theta = 0;
				ThetaDel = 2* Math.PI / jVerts;
				cosPhi = Math.cos( Phi );
				sinPhi = Math.sin( Phi );
				for( j; j < jVerts; j++ )
				{
					cosTheta = Math.cos( Theta );
					sinTheta = Math.sin( Theta );
					
					z_vtx = new Vertex3D(cosTheta * sinPhi * radius_in, cosPhi * radius_in * revFaces, sinTheta * sinPhi * radius_in  );
					z_uv = new NumberUV(1-Theta * PIInv * 0.5, Phi * PIInv);
					aVertice.push( z_vtx );
					aUV.push( z_uv );
					//l_oGeometry3D.setVertex (nVertices, cosTheta * sinPhi * radius_in, cosPhi * radius_in, sinTheta * sinPhi * radius_in);
					//l_oGeometry3D.setVertexNormal (nVertices, cosTheta * sinPhi, cosPhi, sinTheta * sinPhi);
					//l_oGeometry3D.setUVCoords (nVertices, Theta * PIInv * 0.5, Phi * PIInv); 
					nVertices++;

					Theta += ThetaDel;
				}
				Phi += PhiDel;
			}
			
			// Four triangles meet at every pole, so we make 8 polar vertices to reduce polar distortions
			for (i = 0; i < 8; i++)
			{ 
				z_vtx = new Vertex3D( 0, ((i < 4) ? radius_in : -radius_in) * revFaces, 0 );
				z_uv = new NumberUV( 1-0.25 * (i%4 + 0.5), (i < 4) ? 0 : 1 );
				aVertice.push( z_vtx );
				aUV.push( z_uv );
				//l_oGeometry3D.setVertex (nVertices + i, 0, (i < 4) ? radius_in : -radius_in, 0);
				//l_oGeometry3D.setVertexNormal (nVertices + i, 0, (i < 4) ? 1 : -1, 0);
				//l_oGeometry3D.setUVCoords (nVertices + i, 0.25 * (i%4 + 0.5), (i < 4) ? 0 : 1);
			}

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
							if( U_Ind > U_Ind_e ) {
								// pacific problem - correct vertex does not exist
								aPacificFaces.push (
									(Pt2 % 2 == 0) ?
									[ Pt2 -1, Pt0 -1, U_Ind_s -1 ] :
									[ Pt0 -1, Pt2 -1, U_Ind_s -1 ]);
								continue;
							}
							Pt1 = U_Ind;
							isUpTri = true;
						}

						// use extra vertices for pole
						if (Pt0 == 0)
						{ 
							Pt0 = Pt1 + nVertices; 
							if (Pt1 == 4) {
								// pacific problem at North pole
								aPacificFaces.push ([ Pt0 -1, Pt1 -1, Pt2 -1 ]);
								continue;
							}
						}
						
						//aVertice[nFaces] = new Vertex3D(Pt0 -1, Pt1 -1, Pt2 -1);
						//aUV[nFaces] = new NumberUV(Pt0 -1, Pt1 -1, Pt2 -1);
						aFace.push( new Triangle3D( this, [ aVertice[Pt0 -1],aVertice[Pt1 -1],aVertice[Pt2 -1] ], null, [ aUV[Pt0 -1],aUV[Pt1 -1],aUV[Pt2 -1] ] ) );
						//l_oGeometry3D.setFaceVertexIds (nFaces, Pt0 -1, Pt1 -1, Pt2 -1);
						//l_oGeometry3D.setFaceUVCoordsIds (nFaces, Pt0 -1, Pt1 -1, Pt2 -1); 
						nFaces++;
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
							if( U_Ind > U_Ind_e ) {
								if (Pt2 %2 == 0)
									aPacificFaces.push ([ Pt0 -1, Pt2 -1, U_Ind_s -1 ]);
								else
									aPacificFaces.push ([ Pt0 -1, U_Ind_s -1, L_Ind_s -1 ]);
								continue;
							}
							Pt1 = U_Ind;
							isUpTri = true;
						}

						// use extra vertices for pole
						if (Pt0 == nVertices +1)
						{
							Pt0 = Pt1 + 8;
							if (Pt1 == nVertices) {
								// pacific problem at South pole
								aPacificFaces.push ([ Pt0 -1, Pt2 -1, Pt1 -1 ]);
								continue;
							}
						}
						
						//aVertice[nFaces] = new Vertex3D(Pt0 -1, Pt2 -1, Pt1 -1);
						//aUV[nFaces] = new NumberUV(Pt0 -1, Pt2 -1, Pt1 -1);
						aFace.push( new Triangle3D( this, [ aVertice[Pt0 -1],aVertice[Pt2 -1],aVertice[Pt1 -1] ], null, [ aUV[Pt0 -1],aUV[Pt2 -1],aUV[Pt1 -1] ] ) );
						//l_oGeometry3D.setFaceVertexIds (nFaces, Pt0 -1, Pt2 -1, Pt1 -1);
						//l_oGeometry3D.setFaceUVCoordsIds (nFaces, Pt0 -1, Pt2 -1, Pt1 -1); 
						nFaces++;
					}
				}
			}
			
			// only now we can fix pacific problem
			// (because doing so in any other way would break Gabriel code ;)
			nVertices = aVertice.length;
			//nVertices = l_oGeometry3D.aVertex.length;
			for (i = 0; i < aPacificFaces.length; i++)
			{
				for (k = 0; k < 3; k++)
				{
					var p:int = aPacificFaces [i][k];
					if (aUV[p].u == reverse ? 1 : 0 )
					{
 						if ( !aVertice[nVertices] ) aVertice[nVertices] = aVertice[p];
 						if ( !aUV[nVertices] ) aUV[nVertices] = new NumberUV(reverse ? 0 : 1, aUV[p].v);
						
						aPacificFaces [i][k] = nVertices;
						nVertices++;
					}
					
// 					if (l_oGeometry3D.aUVCoords [p].u == 0)
// 					{
// 						l_oGeometry3D.setVertex (nVertices,
// 							l_oGeometry3D.aVertex [p].x,
// 							l_oGeometry3D.aVertex [p].y,
// 							l_oGeometry3D.aVertex [p].z);
// 						l_oGeometry3D.setVertexNormal (nVertices,
// 							l_oGeometry3D.aVertexNormals [p].x,
// 							l_oGeometry3D.aVertexNormals [p].y,
// 							l_oGeometry3D.aVertexNormals [p].z);
// 						l_oGeometry3D.setUVCoords (nVertices, 1,
// 							l_oGeometry3D.aUVCoords [p].v);
// 						aPacificFaces [i][k] = nVertices;
// 						nVertices++;
// 					}
				}
				aFace.push( new Triangle3D( this, [ aVertice[ aPacificFaces [i][0] ],aVertice[ aPacificFaces [i][1] ],aVertice[ aPacificFaces [i][2] ] ], null, [ aUV[ aPacificFaces [i][0] ],aUV[ aPacificFaces [i][1] ],aUV[ aPacificFaces [i][2] ] ] ) );
				//l_oGeometry3D.setFaceVertexIds (nFaces, aPacificFaces [i][0], aPacificFaces [i][1], aPacificFaces [i][2]);
				//l_oGeometry3D.setFaceUVCoordsIds (nFaces, aPacificFaces [i][0], aPacificFaces [i][1], aPacificFaces [i][2]);

				nFaces++;
			}

			//return l_oGeometry3D;
		}
	}
}