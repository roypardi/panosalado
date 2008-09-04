package org.papervision3d.materials.special
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import org.papervision3d.core.geom.renderables.Particle;
	import org.papervision3d.core.render.data.RenderSessionData;
	import org.papervision3d.core.render.draw.IParticleDrawer;

	public class BitmapParticleMaterial extends ParticleMaterial implements IParticleDrawer
	{
		
		private var scaleMatrix:Matrix;
		
		private var renderRect:Rectangle; 
	
		
		public function BitmapParticleMaterial(bitmap:BitmapData)
		{
			super(0,0);
			this.bitmap = bitmap;
			this.scaleMatrix = new Matrix();
			renderRect = new Rectangle() ;
		}
		
		override public function drawParticle(particle:Particle, graphics:Graphics, renderSessionData:RenderSessionData):void
		{
			/*
			scaleMatrix.a = particle.renderScale;
			scaleMatrix.d = particle.renderScale;	
			scaleMatrix.tx = particle.vertex3D.vertex3DInstance.x;
			scaleMatrix.ty = particle.vertex3D.vertex3DInstance.y;
			graphics.beginBitmapFill(bitmap, scaleMatrix, false, smooth);
			graphics.drawRect(particle.vertex3D.vertex3DInstance.x, particle.vertex3D.vertex3DInstance.y,particle.renderScale*particle.size,particle.renderScale*particle.size);
			graphics.endFill();
			renderSessionData.renderStatistics.particles++;
			*/
			
			var cullingrect:Rectangle = renderSessionData.viewPort.cullingRectangle;
			renderRect = cullingrect.intersection(particle.renderRect);
			graphics.beginBitmapFill(bitmap, scaleMatrix, false, smooth);
			graphics.drawRect(renderRect.x, renderRect.y, renderRect.width, renderRect.height);
			graphics.endFill();
			renderSessionData.renderStatistics.particles++;
			
			
		}
		
		override public function updateRenderRect(particle : Particle) :void
		{
			scaleMatrix.identity();
			var renderrect:Rectangle = particle.renderRect; 
			
			scaleMatrix.tx = 0;//spriteRect.left; 
			scaleMatrix.ty = 0;//spriteRect.top; 
			scaleMatrix.scale(particle.renderScale*particle.size, particle.renderScale*particle.size);
			var osx:Number = scaleMatrix.tx; 
			var osy:Number = scaleMatrix.ty; 
			
			scaleMatrix.translate(particle.vertex3D.vertex3DInstance.x, particle.vertex3D.vertex3DInstance.y); 
			
			
			
			renderrect.x = particle.vertex3D.vertex3DInstance.x+osx;
			renderrect.y = particle.vertex3D.vertex3DInstance.y+osy;
			renderrect.width = particle.renderScale*particle.size*bitmap.width;
			renderrect.height = particle.renderScale*particle.size*bitmap.height;
			
			
		}
		
		
	}
}