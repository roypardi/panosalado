package zephyr.render
{
	import org.papervision3d.render.BasicRenderEngine;
	import org.papervision3d.core.render.data.RenderSessionData;
	import org.papervision3d.core.render.data.RenderStatistics;
	import org.papervision3d.core.render.filter.BasicRenderFilter;
	import org.papervision3d.core.render.filter.IRenderFilter;
	import org.papervision3d.core.render.project.BasicProjectionPipeline;
	import org.papervision3d.core.render.project.ProjectionPipeline;
	import org.papervision3d.core.render.sort.NullSorter;
	import org.papervision3d.core.render.sort.IRenderSorter;
	import org.papervision3d.core.utils.StopWatch;
	import org.papervision3d.events.RendererEvent;
	
	public class PSRenderEngine extends BasicRenderEngine
	{
		
		
		/** @private */
		override protected function init():void
		{
			renderStatistics = new RenderStatistics();
			
			projectionPipeline = new BasicProjectionPipeline();
			
			stopWatch = new StopWatch();
				
			sorter = new NullSorter();
			filter = new BasicRenderFilter();
			
			renderList = new Array();
			clipping = null;
			
			renderSessionData = new RenderSessionData();
			renderSessionData.renderer = this;
			
			projectionDoneEvent = new RendererEvent(RendererEvent.PROJECTION_DONE, renderSessionData);
			renderDoneEvent = new RendererEvent(RendererEvent.RENDER_DONE, renderSessionData);
		}
	}
}