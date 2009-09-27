package com.eyesee360.geometry
{
	import flash.events.IEventDispatcher;
	
	public interface IProjection
	{
		function get type():String;
		
		/*
		For cartesian projections: Returns an array of four angles in radians:
		[panMin, tiltMin, panRange, tiltRange]
		
		For rectilinear (i.e. perspective) projection: Returns an array of four
		coordinates defining a rectangle on the viewing plane:
		[left, bottom, width, height]
		*/ 
		function get bounds():Array;
		function get boundsDeg():Array;
	}
}