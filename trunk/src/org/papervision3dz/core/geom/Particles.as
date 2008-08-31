package org.papervision3d.core.geom
{
	/**
	 * @Author Ralph Hauwert
	 * 
	 * - 	updated by Seb Lee-Delisle to allow the updating of a renderRect property of a particle
	 * 		used for smart culling of particles
	 */
	import org.papervision3d.core.geom.renderables.Vertex3DInstance;	
	import org.papervision3d.core.geom.renderables.Vertex3D;	
	
	import flash.geom.Rectangle;	
	
	import org.papervision3d.core.math.Matrix3D;	
	import org.papervision3d.core.geom.renderables.Particle;
	import org.papervision3d.core.render.data.RenderSessionData;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.core.culling.IObjectCuller;	
	public class Particles extends Vertices3D
	{
		
		private var vertices:Array;
		public var particles:Array;
		
		/**
		 * VertexParticles
		 * 
		 * A simple Particle Renderer for Papervision3D.
		 * 
		 * Renders added particles to a given container using Flash's drawing API.
		 */
		public function Particles(name:String = "VertexParticles")
		{
			this.vertices = new Array();
			this.particles = new Array();
			
			super(vertices, name);
		}
		
		/**
		 * Project
		 */
		public override function project( parent :DisplayObject3D, renderSessionData:RenderSessionData ):Number
		{
			super.project(parent,renderSessionData);
			
			var viewport : Rectangle = renderSessionData.camera.viewport;
			// TODO (MEDIUM) implement Frustum camera rendering for Particles
			
				//return projectFrustum(parent, renderSessionData);
			if(this.culled) return 0; 

			var p:Particle;
			
			
		
			for each(p in particles)
			{
				if( renderSessionData.camera is IObjectCuller )
				{
					var v:Vertex3D = p.vertex3D;
					p.renderScale = viewport.width /2 /(v.x * view.n41 + v.y * view.n42 + v.z * view.n43 + view.n44) ;
					//trace("frustum scale ", p.renderScale);
				} 
				else
				{	
					var fz:Number = (renderSessionData.camera.focus*renderSessionData.camera.zoom);
					p.renderScale = fz / (renderSessionData.camera.focus + p.vertex3D.vertex3DInstance.z);
					//trace("freecam scale ", p.renderScale);
				}
				p.updateRenderRect();
				
				if(renderSessionData.viewPort.particleCuller.testParticle(p)){
					p.renderCommand.screenDepth = p.vertex3D.vertex3DInstance.z;
					renderSessionData.renderer.addToRenderList(p.renderCommand);	
				}else{
					renderSessionData.renderStatistics.culledParticles++;
					//trace("culled!");
				}
			}
			return 1;
		}
		
		/*
		public override function projectFrustum( parent :DisplayObject3D, renderSessionData:RenderSessionData ):Number 
		{
			
		
			var view : Matrix3D = this.view,
				viewport : Rectangle = renderSessionData.camera.viewport,
				m11 :Number = view.n11,
				m12 :Number = view.n12,
				m13 :Number = view.n13,
				m21 :Number = view.n21,
				m22 :Number = view.n22,
				m23 :Number = view.n23,
				m31 :Number = view.n31,
				m32 :Number = view.n32,
				m33 :Number = view.n33,
				m41 :Number = view.n41,
				m42 :Number = view.n42,
				m43 :Number = view.n43,
				vx	:Number,
				vy	:Number,
				vz	:Number,
				s_x	:Number,
				s_y	:Number,
				s_z	:Number,
				s_w :Number,
				vpw :Number = viewport.width / 2,
				vph :Number = viewport.height / 2,
				vertex : Vertex3D, 
				screen : Vertex3DInstance,
				vertices :Array  = this.geometry.vertices,
				i        :int    = particles.length,
				p		: Particle; 
				
			while( p = particles[--i] )
			{
				vertex = p.vertex3D; 
				
				// Center position
				vx = vertex.x;
				vy = vertex.y;
				vz = vertex.z;
				
				s_z = vx * m31 + vy * m32 + vz * m33 + view.n34;
				s_w = vx * m41 + vy * m42 + vz * m43 + view.n44;
				
				//trace(s_w);
				
				screen = vertex.vertex3DInstance;
				
				// to normalized clip space (0.0 to 1.0)
				// NOTE: can skip and simply test (s_z < 0) and save a div
				s_z /= s_w;
			
				// is point between near- and far-plane?
				if( screen.visible = (s_z > 0 && s_z < 1) )
				{
					// to normalized clip space (-1,-1) to (1, 1)
					s_x = (vx * m11 + vy * m12 + vz * m13 + view.n14) / s_w;
					s_y = (vx * m21 + vy * m22 + vz * m23 + view.n24) / s_w;
					
					// NOTE: optionally we can flag screen verts here 
					//screen.visible = (s_x > -1 && s_x < 1 && s_y > -1 && s_y < 1);
					
					// project to viewport.
					screen.x = s_x * vpw;
					
					screen.y = s_y * vph;
					
					//Papervision3D.logger.debug( "sx:" + screen.x + " " +screen.y );
					// NOTE: z not lineair, value increases when nearing far-plane.
					screen.z = s_z*s_w;
				} 
					trace("particles projectfrustum vertex  visible :", screen.visible);
				
			}
			
			return 0;
		}
		
		*/
		
		/**
		 * addParticle(particle);
		 * 
		 * @param	particle	partical to be added and rendered by to this VertexParticles Object.
		 */
		public function addParticle(particle:Particle):void
		{
			particle.instance = this;
			particles.push(particle);
			vertices.push(particle.vertex3D);
		}
		
		/**
		 * removeParticle(particle);
		 * 
		 * @param	particle	particle to be removed from this VertexParticles Object.
		 */
		public function removeParticle(particle:Particle):void
		{
			particle.instance = null;
			particles.splice(particles.indexOf(particle,0), 1);
			vertices.splice(vertices.indexOf(particle.vertex3D,0), 1);
		}
		
		/**
		 * removeAllParticles()
		 * 
		 * removes all particles in this VertexParticles Object.
		 */
		public function removeAllParticles():void
		{
			particles = new Array();
			vertices = new Array();
			geometry.vertices = vertices;
		}
		
		
	}
}