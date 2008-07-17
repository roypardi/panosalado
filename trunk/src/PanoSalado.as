package 
{
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	
	import br.com.stimuli.loading.BulkLoader;
	import br.com.stimuli.loading.BulkProgressEvent;
	import br.com.stimuli.loading.BulkErrorEvent;
	
	import flash.utils.Dictionary;
	
	import flash.display.*;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.geom.Rectangle;
	
	import zephyr.cameracontrol.CameraController;
	import zephyr.cameracontrol.CameraControllerEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.MouseEvent;
	
//	import zephyr.cameras.FOVCamera3D;
	
	import org.papervision3d.cameras.Camera3D;
	import zephyr.objects.primitives.Cube;
	import org.papervision3d.objects.primitives.Plane;
	import org.papervision3d.objects.primitives.Sphere;
	import org.papervision3d.render.BasicRenderEngine;
	import org.papervision3d.scenes.Scene3D;
	import org.papervision3d.view.Viewport3D;
	import org.papervision3d.events.InteractiveScene3DEvent;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.materials.BitmapMaterial;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.core.proto.MaterialObject3D;
	import org.papervision3d.events.RendererEvent;
	import org.papervision3d.core.render.data.RenderStatistics;
	import org.papervision3d.core.math.Number3D;
	
	//import gs.TweenFilterLite;
	import gs.TweenLite;
	import zephyr.transitions.None;
	import zephyr.transitions.Quad;
	import zephyr.transitions.Cubic;
	import zephyr.transitions.Quart;
	import zephyr.transitions.Quint;
	import zephyr.transitions.Sine;
	import zephyr.transitions.Circ;
	import zephyr.transitions.Expo;
	import zephyr.transitions.Elastic;
	import zephyr.transitions.Back;
	import zephyr.transitions.Bounce;
	
	import zephyr.objects.StageAlignedSprite;
	import zephyr.objects.TargetFacingPlane;
	
	import org.papervision3d.view.stats.StatsView;


	public class PanoSalado extends Sprite
	{
		
		public var bulkLoader : BulkLoader;
				
		public var ui:Sprite = new Sprite();
		
		public var spaces:Array = new Array();
		
		public var viewports:Sprite = new Sprite();
		
		public var cameraController:CameraController;
		
		public var currentSpace:String = "";
		
		public var lastSpace:String = "";
		
		private var interactionEquivalents:Object = { mouseClick:"onClick", mouseOver:"onOver", mouseOut:"onOut", mousePress:"onPress", mouseRelease:"onRelease", mouseMove:"onMouseMove", mouseDown:"onPress", mouseUp:"onRelease", click:"onClick" };
		
		private var unclaimedMaterials:Dictionary = new Dictionary(true);
		
		private var _worldDirty:Boolean = false;
		
		public var settings : XML;
		
		public var loadMeter:Sprite = new Sprite();
		
		public var resizeDict:Object = new Object();
		
		public function PanoSalado() 
		{
			addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true);
			
			var xmlLoader:URLLoader = new URLLoader();
			xmlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			xmlLoader.load( new URLRequest( loaderInfo.parameters.xml?loaderInfo.parameters.xml:"PanoSalado.xml" ) );
			xmlLoader.addEventListener(Event.COMPLETE, onXMLLoaded, false, 0, true);
			
			//add viewports sprite to display list.  It will hold all the viewports so they can be iterated/isolated from other items
			addChild(viewports);
			
			addEventListener(Event.ENTER_FRAME, doRender, false, 0, true);
			
			//set up bulk loader
			bulkLoader = new BulkLoader("bulkLoader");
			
			bulkLoader.addEventListener(BulkProgressEvent.PROGRESS, onAllProgress, false, 0, true);
			bulkLoader.addEventListener(BulkLoader.COMPLETE, onAllLoaded, false, 0, true);
			
			addChild(ui);
			ui.addEventListener(MouseEvent.CLICK, mouseEventHandler, false, 0, true);
			ui.addEventListener(MouseEvent.MOUSE_OVER, mouseEventHandler, false, 0, true);
			ui.addEventListener(MouseEvent.MOUSE_OUT, mouseEventHandler, false, 0, true);
			ui.addEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler, false, 0, true); 
			ui.addEventListener(MouseEvent.MOUSE_UP, mouseEventHandler, false, 0, true); 
			ui.addEventListener(MouseEvent.MOUSE_MOVE, mouseEventHandler, false, 0, true); 
			
		}
		
		public function stageReady(e:Event):void
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.frameRate = 60;
			stage.quality = StageQuality.MEDIUM
			
			loadMeter.graphics.beginFill(0xFFFFFF);
			loadMeter.graphics.drawRect(0,0,stage.stageWidth,3);
			loadMeter.graphics.endFill();
			//loadMeter.scaleX = 0;
			addChild(loadMeter);
		}
		
		private function onXMLLoaded(e:Event):void
		{
			settings = XML(e.target.data);
			
			cameraController = new CameraController
			( 
				root, 
				getBooleanInXML(settings.@autorotator, true), 
				getNumberInXML(settings.@autorotatorDelay, 15000) 
			);

			cameraController.sensitivity = 		getNumberInXML(settings.@cameraSensitivity, 	60);
			cameraController.friction = 		getNumberInXML(settings.@cameraFriction, 		0.3);
			cameraController.threshold = 		getNumberInXML(settings.@cameraThreshold, 		0.0001);
			cameraController.keyIncrement = 	getNumberInXML(settings.@keyIncrement, 			75);
			cameraController.zoomIncrement = 	getNumberInXML(settings.@zoomIncrement, 		0.2);
			
			cameraController.addEventListener(CameraControllerEvent.DECELERATING, changeQuality, false, 0, true);
			cameraController.addEventListener(CameraControllerEvent.ACCELERATING, changeQuality, false, 0, true);
			cameraController.addEventListener(CameraControllerEvent.STOPPED, changeQuality, false, 0, true);
			cameraController.addEventListener(CameraControllerEvent.MOVING, moveCamera, false, 0, true);
			cameraController.addEventListener(CameraControllerEvent.AUTOROTATING, autorotate, false, 0, true);
			
			refresh();
			
			//onStart code hook, pass second arg false to NOT check for onStart in non-existent current scene node.
			XMLCodeHook("onStart", false);
			
		}
		
		private function refresh():void
		{
			maxTilt = findNumberInXML("maxTilt", 9999);
			minTilt = findNumberInXML("minTilt", 9999);
			
			maxPan = findNumberInXML("maxPan", 9999);
			minPan = findNumberInXML("minPan", 9999);
			
			minZoom = findNumberInXML("minZoom", 1);
			maxZoom = findNumberInXML("maxZoom", 25);
			
			accSmooth = getBooleanInXML(settings.@accelerating_smooth, false);
			accPrecise = getBooleanInXML(settings.@accelerating_precise, false);
			accPrecision = getIntInXML(settings.@accelerating_precision, 64);
			
			decSmooth = getBooleanInXML(settings.@decelerating_smooth, true);
			decPrecise = getBooleanInXML(settings.@decelerating_precise, true);
			decPrecision = getIntInXML(settings.@decelerating_precision, 16);
			
			stopSmooth = getBooleanInXML(settings.@stopped_smooth, true);
			stopPrecise = getBooleanInXML(settings.@stopped_precise, true);
			stopPrecision = getIntInXML(settings.@stopped_precision, 1);
			
			da = getNumberInXML(settings.@autorotatorIncrement,0.25);
		}
		
		private function onSingleItemLoaded(e:Event):void
		{			
			var bm:BitmapMaterial = new BitmapMaterial( BitmapData(e.target._content.bitmapData) );
			unclaimedMaterials[ e.target.url.url.toString() ] = bm ;
		}
		
		private function onAllProgress(e : BulkProgressEvent) : void
		{
		 	//trace("progress event: loaded" , e.bytesLoaded," of ",  e.bytesTotal);
		 	loadMeter.scaleX = e.weightPercent;
		}
		
		private function onAllLoaded(e : BulkProgressEvent) : void
		{
			trace("PS: " + currentSpace + " has loaded");
			
			// create a new space (viewport, scene, and camera)
			var idx:int = instantiateNewSpace();
			
			var thisSpace:Object = spaces[idx];
			
			//set-up camera
			setupCamera(thisSpace["camera"], spaces[idx-1]);
			
			//iterate through all the objects in the scene (pano, hotspots, etc)
			for each (var xml:XML in settings.child( currentSpace ).children() )
			{
				var nodeName:String = xml.name().localName.toString();
				
				//create papervision primitive by calling the function bearing its name (cube, plane, sphere, etc)
				var primitive:Object = root[ nodeName ].call(null, xml);
				
				if ( nodeName != "stageAlignedSprite" )
				{
					primitive.name = xml.@id.toString();
					
					//set position and rotation of primitive, using += so that it can be pre adjusted e.g. sphere
					primitive.x += getIntInXML(xml.@x, 0);
					primitive.y += getIntInXML(xml.@y, 0);
					primitive.z += getIntInXML(xml.@z, 0);
					
					primitive.rotationX += getIntInXML(xml.@rotationX, 0);
					primitive.rotationY += getIntInXML(xml.@rotationY, 0); 
					primitive.rotationZ += getIntInXML(xml.@rotationZ, 0); 
					
					primitive.visible = getBooleanInXML(xml.@visible, true);
					
					if ( getStringInXML(xml.@onClick) != null ) { primitive.addEventListener(InteractiveScene3DEvent.OBJECT_CLICK, interactionScene3DEventHandler, false, 0, true); }
					if ( getStringInXML(xml.@onOver) != null ) { primitive.addEventListener(InteractiveScene3DEvent.OBJECT_OVER, interactionScene3DEventHandler, false, 0, true); }
					if ( getStringInXML(xml.@onOut) != null ) { primitive.addEventListener(InteractiveScene3DEvent.OBJECT_OUT, interactionScene3DEventHandler, false, 0, true); }
					if ( getStringInXML(xml.@onPress) != null ) { primitive.addEventListener(InteractiveScene3DEvent.OBJECT_PRESS, interactionScene3DEventHandler, false, 0, true); }
					if ( getStringInXML(xml.@onRelease) != null ) { primitive.addEventListener(InteractiveScene3DEvent.OBJECT_RELEASE, interactionScene3DEventHandler, false, 0, true); }
					if ( getStringInXML(xml.@onOverMove) != null ) { primitive.addEventListener(InteractiveScene3DEvent.OBJECT_MOVE, interactionScene3DEventHandler, false, 0, true); }
					
					primitive.addEventListener(InteractiveScene3DEvent.OBJECT_OVER, cursorHandler, false, 0, true);
					primitive.addEventListener(InteractiveScene3DEvent.OBJECT_OUT, cursorHandler, false, 0, true);
					
					primitive.updateTransform();
					
					thisSpace["scene"].addChild( primitive, xml.@id.toString() );
				}
				else 
				{
					ui.addChild( StageAlignedSprite(primitive) );trace("i");
				}
			}
			
			//onResize();
			
			bulkLoader.removeAll();
			
			thisSpace["viewport"].interactive = findBooleanInXML("interactive", false);
			
			// add viewport to the displaylist
			viewports.addChild( thisSpace["viewport"] );
						
			//transitionStart code hook
			XMLCodeHook("onTransitionStart");
			
			//Do transition and transitionEnd code hook
			var transArr:Array = findStringInXML("transition").split(",");
			var time:Number = transArr[0] != null ? Number( transArr[0] ) : 3;
			var type:String = transArr[1] != null ? transArr[1] : "alpha";
			var val:Number = transArr[2] != null ? transArr[2] : 0;
			var ease:String = transArr[3] != null ? transArr[3] : "Expo.easeInOutExpo";
			var easeArr:Array = ease.split(".");
			var easeEq:String = easeArr[0];
			var easeFunc:String = easeArr[1];
			var initObject:Object = new Object();
			initObject.onComplete = XMLCodeHook;
			initObject.onCompleteParams = new Array("onTransitionEnd")
			initObject.ease = [easeEq][easeFunc];
			initObject[type] = val;
			
			TweenLite.from(thisSpace["viewport"], time, initObject );
			
			_worldDirty = true;
			//if mouse is not down, cameraController will not be requesting renders onEnterFrame, therefore must call here
// 			if ( ! cameraController.enterFrameListenerActive ) 
// 			{	
// 				_worldDirty = true;
// 				doRender();
// 				
// 			}
			
			
			//code hook
			XMLCodeHook("onDisplay");
			
			//remove onDisplay so it doesn't trigger again
			settings.@onDisplay = "";
			
		}
		
		private function setupCamera(camera:Camera3D, lastSpace:Object=null):void
		{
			// set up camera: 
			var cameraContinuity:String = findStringInXML("cameraContinuity");
			var pan:Number = findNumberInXML("pan", 0 );
			var tilt:Number = findNumberInXML("tilt", 0);
			var zoom:Number = findNumberInXML("zoom", 12);
			var focus:Number = findNumberInXML("focus", 100);
			var camX:Number = findNumberInXML("cameraX", 0);
			var camY:Number = findNumberInXML("cameraY", 0);
			var camZ:Number = findNumberInXML("cameraZ", 0);
			
			// leash free or default unspecified leashing
			if (cameraContinuity == "free" || cameraContinuity == "")
			{
				camera.rotationX = tilt;
				camera.rotationY = pan;
				camera.rotationZ = 0;
				camera.zoom = zoom;
				camera.focus = focus;
				camera.x = camX;
				camera.y = camY;
				camera.z = camZ;
				}
			else if ( cameraContinuity == "lock" )
			{
				//leash = lock
				camera.rotationX = lastSpace != null ? lastSpace["camera"].rotationX : tilt ;
				camera.rotationY = lastSpace != null ? lastSpace["camera"].rotationY : pan ;
				camera.rotationZ = lastSpace != null ? lastSpace["camera"].rotationZ : 0 ;
				camera.zoom = lastSpace != null ? lastSpace["camera"].zoom : zoom ;
				camera.focus = lastSpace != null ? lastSpace["camera"].focus : focus ;
				camera.x = lastSpace != null ? lastSpace["camera"].x : camX ;
				camera.y = lastSpace != null ? lastSpace["camera"].y : camY ;
				camera.z = lastSpace != null ? lastSpace["camera"].z : camZ ;
			}
		}
		

		
		private function createBitmapMaterial(xml:XML):BitmapMaterial
		{
			//var material:BitmapMaterial = new BitmapMaterial( bulkLoader.getBitmapData(xml.file.toString(), true) );
			var material:BitmapMaterial =  unclaimedMaterials[xml.file.toString()];
			
			material.oneSide = getBooleanInXML( xml.@oneSide, true );
			
			material.smooth = getBooleanInXML( xml.@smooth, false );
			
			material.interactive = getBooleanInXML( xml.@interactive, false );
			
			material.precise = getBooleanInXML( xml.@precise, false );
			
			material.precision = getIntInXML( xml.@precision, 1 );
			
			return material
		}
		
		private function sphere(xml:XML):Object
		{
			
			var material:BitmapMaterial = createBitmapMaterial(xml);
			//var material:BitmapMaterial =  BitmapMaterial(unclaimedMaterials[xml.file.toString()]);
			
			var segments:int = getIntInXML( xml.@segments, 24 );
			
			var radius:int = getIntInXML( xml.@radius, 1000 );
			
			var sphere:Sphere = new Sphere(material, radius, segments, segments );
			
			sphere.rotationY = 77;
			sphere.rotationZ = 1;
						
			return sphere;
		}
		
		private function cube(xml:XML):Object
		{
			
			var materials:MaterialsList = new MaterialsList();
			
			for each (var file:XML in xml.file)
			{
				//var material:BitmapMaterial = new BitmapMaterial( bulkLoader.getBitmapData(file.toString(), true) );
				
				
				var material:BitmapMaterial =  BitmapMaterial(unclaimedMaterials[file.toString()]);
				
				material.oneSide = getBooleanInXML( xml.@oneSide, true );
			
				material.interactive = getBooleanInXML( xml.@interactive, false );
				
				if ( getBooleanInXML(settings.@dyanmicQualityAdjustment, true) )
				{
					material.smooth = getBooleanInXML( settings.@stopped_smooth, true );
					
					material.precise = getBooleanInXML( settings.@stopped_precise, true );
				
					material.precision = getIntInXML( settings.@stopped_precision, 1 );
				}
				else
				{
					material.smooth = getBooleanInXML( xml.@smooth, false );
					
					material.precise = getBooleanInXML( xml.@precise, true );
				
					material.precision = getIntInXML( xml.@precision, 8 );
				}
				
				materials.addMaterial( material, file.@id.toString() );
			}
			
			var insideFaces  :int = Cube.ALL;
			var excludeFaces :int = Cube.NONE;
			
			var segments:int = getIntInXML( xml.@segments, 15 );
			
			var width:int = getIntInXML( xml.@width, 100000 );
			
			var cube:Cube = new Cube( materials, width, width, width, segments, segments, segments, insideFaces, excludeFaces );
			
			return cube;
		}
		
		private function targetFacingPlane(xml:XML):Object
		{
			var bmd:BitmapData = bulkLoader.getBitmapData(xml.file.toString(), false);
			var width:Number = (2 / bmd.width ) * 40000;
			var height:Number = (2 / bmd.height ) * 40000;
			
			var material:BitmapMaterial = createBitmapMaterial(xml);
			//var material:BitmapMaterial =  BitmapMaterial(unclaimedMaterials[xml.file.toString()]);
			
			var segments:int = getIntInXML( xml.@segments, 24 );
			
			var pan:Number = getNumberInXML( xml.@pan, 0 );
			
			var tilt:Number = getNumberInXML( xml.@tilt, 0 );
			
			//Plane( material:MaterialObject3D=null, width:Number=0, height:Number=0, segmentsW:Number=0, segmentsH:Number=0, initObject:Object=null )
			//var tfp:TargetFacingPlane = new TargetFacingPlane(getSpaceByName( currentSpace )["camera"] as DisplayObject3D, material, width, height, segments, segments, pinToSphere(40000,pan,tilt) );
			var tfp:TargetFacingPlane = new TargetFacingPlane(getSpaceByName( currentSpace )["camera"] as DisplayObject3D, material, width, height, segments, segments );
			
			var p:Number3D = pinToSphere(40000,pan,tilt);
			
			tfp.x = p.x;
			tfp.y = p.y;
			tfp.z = p.z;
			
			//plane.lookAt(getSpaceByName( currentSpace )["camera"] as DisplayObject3D);
			
			return tfp;
			
			//tooltipTexts[plane.name] = "Alternate View";
		}
		
		private function plane(xml:XML):Object
		{
			//var bmd:BitmapData = bulkLoader.getBitmapData(xml.file.toString(), false);
			var width:Number = getIntInXML( xml.@width, 100 );
			var height:Number = getIntInXML( xml.@height, 100 );
			
			var material:BitmapMaterial = createBitmapMaterial(xml);
			//var material:BitmapMaterial =  BitmapMaterial(unclaimedMaterials[xml.file.toString()]);
			
			var segments:int = getIntInXML( xml.@segments, 2 );
			
			//var pan:Number = getNumberInXML( xml.@pan, 0 );
			
			//var tilt:Number = getNumberInXML( xml.@tilt, 0 );
			
			//Plane( material:MaterialObject3D=null, width:Number=0, height:Number=0, segmentsW:Number=0, segmentsH:Number=0, initObject:Object=null )
			var plane:Plane = new Plane( material, width, height, segments, segments );
			
			//plane.lookAt(getSpaceByName( currentSpace )["camera"] as DisplayObject3D);
			
			return plane;
			
			//tooltipTexts[plane.name] = "Alternate View";
		}
		
		private function stageAlignedSprite(xml:XML):Object
		{
			var bm:BitmapData = bulkLoader.getBitmapData(xml.file.toString(), true);
			
			var sp:StageAlignedSprite = new StageAlignedSprite();
			
			sp.graphics.beginBitmapFill(bm, null, false, false);
			
			sp.graphics.drawRect(0,0,bm.width,bm.height);
			
			sp.graphics.endFill();
			
			sp.scaleX = getNumberInXML(xml.@scaleX, 1);
			
			sp.scaleY = getNumberInXML(xml.@scaleY, 1);
			
			sp.rotation = getNumberInXML(xml.@rotation, 0);
			
			sp.alpha = getNumberInXML(xml.@alpha, 1);
			
			sp.visible = getBooleanInXML(xml.@visible, true);
			//sp.smoothing = getBooleanInXML(xml.@smoothing, false);
			
			sp.cacheAsBitmap = getBooleanInXML(xml.@cacheAsBitmap, false);
			
			sp.blendMode = getStringInXML(xml.@blendMode, "normal");
			
			sp.name = getStringInXML(xml.@id, "");
			
			sp.alignment = getStringInXML(xml.@align, "tl");
			
			sp.offsetX = getNumberInXML(xml.@offsetX, 0);
			
			sp.offsetY = getNumberInXML(xml.@offsetY, 0);
			//sp.align();
			return sp;
		}
		
		
		
		protected var matsToChange:Array = new Array(),
		objsToChange:Array,
		numObjsToChange:int,
		objToChange:DisplayObject3D,
		matToChange:MaterialObject3D,
		bmToChange:BitmapMaterial,
		accSmooth:Boolean,
		accPrecise:Boolean,
		accPrecision:int,
		decSmooth:Boolean,
		decPrecise:Boolean,
		decPrecision:int,
		stopSmooth:Boolean,
		stopPrecise:Boolean,
		stopPrecision:int
		;
		
		private function changeQuality(e:CameraControllerEvent):void
		{ 
		/* change precise, smooth, and precision while moving camera for better fps
		loops through all the scenes in all the spaces, getting all the objects from each, 
		and then pushing either the materials from the materialsList, or the material into
		an array, and then applies the changes to each item in the array.
		*/
			if ( getBooleanInXML(settings.@dyanmicQualityAdjustment, true) )
			{
				for (var i:int = 0; i < spaces.length; i++)
				{
					objsToChange = spaces[i]["scene"].objects as Array;
					numObjsToChange = objsToChange.length;
					for ( var j:int=0; j < numObjsToChange; j++ )
					{
						objToChange = DisplayObject3D(objsToChange[ j ]);
						
						if (objToChange.materials)
						{/// obj.materials is the materialsList, if it is not null add them
							for each(  matToChange in objToChange.materials.materialsByName )
							{
								matsToChange.push(matToChange);
							}
						}
						else 
						{// obj.material is the material, add it
							matsToChange.push( objToChange.material );
						}
						while ( matToChange = matsToChange.pop() )
						{
							if (matToChange is BitmapMaterial)
							{
								bmToChange = BitmapMaterial(matToChange);
								if (e.type == CameraControllerEvent.ACCELERATING)
								{
									bmToChange.smooth = accSmooth;
									bmToChange.precise = accPrecise;
									bmToChange.precision = accPrecision;
								}
								else if (e.type == CameraControllerEvent.DECELERATING)
								{
									bmToChange.smooth = decSmooth;
									bmToChange.precise = decPrecise;
									bmToChange.precision = decPrecision;
								}
								else if (e.type == CameraControllerEvent.STOPPED)
								{
									bmToChange.smooth = stopSmooth;
									bmToChange.precise = stopPrecise;
									bmToChange.precision = stopPrecision;
								}
							}
						}
					}
				}
			}
			
			//_worldDirty is set when camera or objects in scene have changed and need rendering.
			_worldDirty = true;
		}
		
		
		protected var dp:Number,
		dt:Number,
		maxTilt:Number,
		minTilt:Number,
		maxPan:Number,
		minPan:Number,
		cam:Camera3D,
		newTilt:Number,
		newPan:Number,
		maxZoom:Number,
		minZoom:Number;
		
		private function moveCamera(e:CameraControllerEvent):void
		{
			 dp = e.deltaPan;
			 dt = e.deltaTilt;
			
			for (var i:uint=0; i < spaces.length; i++)
			{
				var cam:Camera3D = Camera3D(spaces[i]["camera"]);
				
				if (maxTilt == 9999)
					maxTilt = 90 + cam.vfov*0.5;
				if (minTilt == 9999)
					minTilt = -90 - cam.vfov*0.5;
				
				if (dt >= 0)
				{
					newTilt = cam.rotationX + dt + cam.vfov*0.5;
					if (newTilt <= maxTilt)
						cam.rotationX += dt;
				}
				else
				{
					newTilt = cam.rotationX + dt - cam.vfov*0.5;
					if (newTilt >= minTilt)
						cam.rotationX += dt;
				}
				
				if (dp >= 0)
				{
					if (maxPan == 9999)
						{ cam.rotationY += dp; }
					else 
					{
						newPan = cam.rotationY + dp + cam.hfov*0.5;
						if (newPan <= maxPan)
							cam.rotationY += dp;
					}
				}
				else
				{
					if (minPan == 9999)
						{ cam.rotationY += dp; }
					else 
					{
						newPan = cam.rotationY + dp - cam.hfov*0.5;
						if (newPan >= minPan)
							cam.rotationY += dp;
					}
				}
				
				//zoom 
				cam.zoom += e.deltaZoom;
				if (cam.zoom < minZoom) { cam.zoom = minZoom }
				if (cam.zoom > maxZoom) { cam.zoom = maxZoom }
			}
			
			//_worldDirty is set when camera or objects in scene have changed and need rendering.
			_worldDirty = true;
		}
		
		protected var da:Number;
		private function autorotate(e:CameraControllerEvent):void
		{
			da = getNumberInXML(settings.@autorotatorIncrement,0.25);
			for (var i:uint=0; i < spaces.length; i++)
			{
				var cam:Camera3D = Camera3D(spaces[i]["camera"]);
				if (da > 0)
				{
					if (cam.rotationX > da ) { cam.rotationX -= da; }
					else if (cam.rotationX < -da ) { cam.rotationX += da; }
				}
				else
				{
					if (cam.rotationX < da ) { cam.rotationX -= da; }
					else if (cam.rotationX > -da ) { cam.rotationX += da; }
				}
				cam.rotationY += da;
			}
			_worldDirty = true;
		}
		
		private function doRender(e:Event=null):void
		{
			if ( _worldDirty )
			{
				for (var i:int = 0; i < spaces.length; i++)
				{
					BasicRenderEngine(spaces[i]["renderer"]).renderScene
					( 
					Scene3D(spaces[i]["scene"]), 
					Camera3D(spaces[i]["camera"]), 
					Viewport3D(spaces[i]["viewport"]) 
					);
				}
				
				_worldDirty = false;
			}
		}
		
		
		
		public function cursorHandler(e:InteractiveScene3DEvent=null):void
		{
			// do nothing
		}
		
		private function interactionScene3DEventHandler(e:InteractiveScene3DEvent=null):void
		{
			var name:String = e.target.name;
			
			trace("PS:" + interactionEquivalents[e.type] + " at " + name );
			
			//execute( settings.child( currentSpace ).children().(attribute('id') == name).attribute( interactionEquivalents[e.type] ).toString() );
			execute( settings..*.(hasOwnProperty("@id") && @id == name).attribute( interactionEquivalents[e.type] ).toString() );
		}
		private function mouseEventHandler(e:MouseEvent=null):void
		{
			//trace("mouse event", e.target.name, e.type);
			
			var name:String = e.target.name;
			
			//trace("PS:" + interactionEquivalents[e.type] + " at " + name );
			
			execute( settings..*.(hasOwnProperty("@id") && @id == name).attribute( interactionEquivalents[e.type] ).toString() );
			
		}
		
		
		
		
		
		
		//functions called by XML code hooks
		
		private function keyDown(direction:String):void
		{
			trace("PS: go:"+direction);
			
			var e:KeyboardEvent = new KeyboardEvent(KeyboardEvent.KEY_DOWN);
			
			e.keyCode = Keyboard[direction.toUpperCase()]
			
			stage.dispatchEvent(e)
		}
		private function keyUp(direction:String):void
		{			
			trace("PS: stop:"+direction);
			
			var e:KeyboardEvent = new KeyboardEvent(KeyboardEvent.KEY_UP);
			
			e.keyCode = Keyboard[direction.toUpperCase()]
			
			stage.dispatchEvent(e)
		}
		
		private function toggleFullscreen():void
		{
			switch(stage.displayState) 
			{
				case "normal":
					stage.displayState = "fullScreen";    
					break;
				case "fullScreen":
				default:
				stage.displayState = "normal";    
					break;
			}
		}
		
		private function toggleAutorotator():void
		{
			trace("PS: toggleAutorotator");
			
			if (cameraController.isAutorotating)
			{
				cameraController.autorotatorOn = false;
			}
			else
			{
				cameraController.startAutorotatorNow();
			}
		}
		
		private function set(str:String):void
		{
			trace("PS: set: ", str);
			
			var leftSide:String = str.slice(0, str.indexOf("=") );
			
			var rightSide:String = str.slice( str.indexOf("=")+1, str.length );
			
			var leftArray:Array = leftSide.split(".");
			
			var rightArray:Array = rightSide.split(",");
			
			var rightObject:Object = new Object();
			
			for (var i:int=0; i< rightArray.length; i++)
			{
				var name:String = rightArray[i].slice(0, rightArray[i].indexOf(":") );
				var value:String = rightArray[i].slice(rightArray[i].indexOf(":")+1 );
				
				rightObject[name] = value;
			}
			
			
		}
		
		
		public function loadSpaceAndInterface(name:String):void
		{
			trace("PS: loadSpaceAndInterface:"+name); 
			
			for each (var xml:XML in settings.child( name ).children() )
			{
				for each (var mat:XML in xml.file)
				{
					bulkLoader.add(mat.toString(), { type:"image", weight: (mat.@weight || 10) });
				
					if (xml.name().localName.toString() != "bitmap")
					{
						bulkLoader.get(mat.toString()).addEventListener(Event.COMPLETE, onSingleItemLoaded, false, 100, true);
					
					}
				}
			}
			
			lastSpace = currentSpace;
			
			currentSpace = name;
			
			bulkLoader.start();
			
		}
		
		
		
		public function loadSpace(name:String):void
		{
			trace("PS: loadSpace:"+name);
			
			for each (var mat:XML in settings.child(name)..file)
			{
				bulkLoader.add(mat.toString(), { type:"image", weight: (mat.@weight || 10) });
				
				bulkLoader.get(mat.toString()).addEventListener(Event.COMPLETE, onSingleItemLoaded, false, 100, true)
				
			}
			
			lastSpace = currentSpace;
			
			currentSpace = name;
			
			bulkLoader.start();
			
			
		}
		
		public function removeLastSpace():void
		{
			if (viewports.numChildren > 1 )
			{
				trace("PS: removeLastSpace:"+lastSpace);
				
				viewports.removeChild( viewports.getChildByName( lastSpace ) );
				
				var spaceToRemove:Object = getSpaceByName(lastSpace);
				
				spaceToRemove["viewport"].destroy();
				
				var objects:Array = spaceToRemove["scene"].objects;
				var len:int = objects.length;
				for ( var j:int=0; j < len; j++ )
				{
					var obj:DisplayObject3D = objects[ j ];
					
					// objects, e.g. cube with multiple materials have to have materials accessed with a loop on the matList
					if (obj is Cube)
					{
						for each(  var mo3d:MaterialObject3D in obj.materials.materialsByName )
						{
							if (mo3d is BitmapMaterial)
							{
								BitmapMaterial(mo3d).destroy();
							}
							else { mo3d.destroy(); }
						}
					}
					else
					{ // object has only one material accessed this way:
						var mat:MaterialObject3D = obj.material;
						if (mat is BitmapMaterial)
						{
							BitmapMaterial(mat).destroy();
						}
						else { mat.destroy(); }
					}
					
					obj = null;
				}
				
				spaceToRemove["renderer"].destroy();
				
				spaceToRemove["scene"] = null;
				
				spaceToRemove["camera"] = null;
				
				spaceToRemove["stats"] = null;
				
				// this needs to be improved.  needs to search for the right space by name and splice it out.
				spaces.splice(spaces.length-2, 1);
				
				spaceToRemove = null;
				
			}
			else trace("PS: removeLastSpace: there is no last space to remove"); 
		}
		
		private function instantiateNewSpace():int
		{
			spaces.push( new Object() );
			
			var idx:uint = spaces.length-1;
			
			//Viewport3D(viewportWidth:Number = 640, viewportHeight:Number = 480, autoScaleToStage:Boolean = false, interactive:Boolean = false, autoClipping:Boolean = true, autoCulling:Boolean = true)
			var viewport:Viewport3D = new Viewport3D( 640, 480, true, false, true, true);
			
			viewport.name = currentSpace;
			
			spaces[idx]["viewport"] = viewport;
			
			var scene:Scene3D = new Scene3D();
			
			spaces[idx]["scene"] = scene;
			
			var camera:Camera3D = new Camera3D();
			
			var vp:Rectangle = new Rectangle();
			vp.width = viewport.viewportWidth;
			vp.height = viewport.viewportHeight;
			camera.update(vp);
			
			spaces[idx]["camera"] = camera;
			
			var renderer:BasicRenderEngine = new BasicRenderEngine();
			
			spaces[idx]["renderer"] = renderer;
			
			spaces[idx]["name"] = currentSpace;
			
			var stats:StatsView = new StatsView( spaces[idx]["renderer"] );
			spaces[idx]["stats"] = stats;
			viewport.addChild(stats);
			
			return idx;
		}
		
		public function getSpaceByName(name:String):Object
		{
			var i:int = 0;
			
			while (i<spaces.length)
			{
				if (spaces[i]["name"] == name) 
				{ 
					return spaces[i]; 
				}
				i++
			}
			return null;
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		//tools
		private function pinToSphere(r:Number, p:Number, t:Number):Number3D
		{
			var pr:Number	= (-1*(p - 90)) * (Math.PI/180); 
			var tr:Number	= t * (Math.PI/180);
			var xc:Number = r * Math.cos(pr) * Math.cos(tr);
			var yc:Number = r * Math.sin(tr);
			var zc:Number = r * Math.sin(pr) * Math.cos(tr);
			
			var n:Number3D = new Number3D();
			n.x = xc;
			n.y = yc;
			n.z = zc;
			return n;
		}
		
		// XML Tools
		private function XMLCodeHook(name:String, checkCurrentSceneFirst:Boolean=true):void
		{	
			var attr:String;
			
			if (checkCurrentSceneFirst)
			{
				attr = findStringInXML(name);
			}
			else attr = settings.attribute(name).toString();
			
			if ( attr != null && attr != "")
			{
				execute(attr);
			}
		}
		
		public function execute(attr:String):void
		{
			
			if ( attr != null && attr != "")
			{
				trace("PS: execute: "+attr);
				
				var lines:Array = attr.split(";");
				for (var i:uint = 0; i < lines.length; i++)
				{	
					if ( lines[i].indexOf(":") != -1 )
					{
						var action:Array = lines[i].split(":");
						var func:String = action[0];
						var argStr:String = action[1];
						var args:Array = argStr.split(",");	
						root[func].apply(root, args);
					}
					else 
					{
						root[lines[i]].call(root);
					}
				}
			}
		}
		
		//search in child node first, then in settings node
		private function findNumberInXML(name:String, def:Number=0):Number
		{
			if ( settings.child(currentSpace).attribute(name).toString().length != 0 )
			{
				return Number( settings.child(currentSpace).attribute(name) );
			}
			if ( settings.attribute(name).toString().length != 0 )
			{
				return Number( settings.attribute(name) );
			}
			else return def;
		}
		private function findIntInXML(name:String, def:int=0):int
		{
			if ( settings.child(currentSpace).attribute(name).toString().length != 0 )
			{
				return int( settings.child(currentSpace).attribute(name) );
			}
			if ( settings.attribute(name).toString().length != 0 )
			{
				return int( settings.attribute(name) );
			}
			else return def;
		}
		private function findBooleanInXML(name:String, def:Boolean=false):Boolean
		{
			if ( settings.child(currentSpace).attribute(name).toString().length != 0 )
			{
				if ( settings.child(currentSpace).attribute(name) == "true" ) return true;
				
				else return false;
			}
			if ( settings.attribute(name).toString().length != 0 )
			{
				if ( settings.attribute(name) == "true" ) return true;
				
				else return false;
			}
			else return def;
		}
		private function findStringInXML(name:String, def:String=null):String
		{
			if ( settings.child(currentSpace).attribute(name).toString().length != 0 )
			{
				return String( settings.child(currentSpace).attribute(name) );
			}
			if ( settings.attribute(name).toString().length != 0 )
			{
				return String( settings.attribute(name) );
			}
			else return def;
		}
		
		private function getBooleanInXML(name:String, def:Boolean=false):Boolean
		{
			if ( name.length != 0 )
			{
				if (name == "true") { return true }
				else { return false }
				
			}
			
			else { return def; }
		}
		private function getNumberInXML(name:String, def:Number=0):Number
		{
			if ( name.length != 0 ) return Number(name);
			else return def;
		}
		private function getIntInXML(name:String, def:int=0):int
		{
			if ( name.length != 0 ) return int(name);
			else return def;
		}
		private function getStringInXML(name:String, def:String=null):String
		{
			if ( name.length != 0 ) return String(name);
			else return def;
		}
		
	}
}