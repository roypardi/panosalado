# Brief Summary #
**PanoSalado is no longer maintained here. PanoSalado version 2 is released under the GPL and is maintained at: http://os.ivrpa.org/panosalado/**.

# Original Summary and info #
**PanoSalado** is a panoramic image display engine built in Actionscript 3.  Includes a modified Papervision3D core.

Supports cube faces and equirectangulars ("sphericals"), and can support cylinders, QTVR, and "video VR".  Extensible architecture separates the interface from the panorama.

Flex 3 and Flash AS3 friendly.

**Blog**:
http://sourceforge.net/apps/wordpress/panosalado/

**API**:
http://os.ivrpa.org/panosalado/downloads

**Download source files and/or example sets**:
[Downloads](http://os.ivrpa.org/panosalado/downloads)

**Forum**:
http://sourceforge.net/projects/panosalado/

# Less Brief Summary #
**PanoSalado** is an Open Source Flash-based panorama viewer headquartered here and at PanoSalado.com. PanoSalado is based atop a Papervision3D core, accessible to both the Flash IDE and Flex developer alike, and hugely extensible.

The advanced Actionscripter can reach right in to the PanoSalado.as file (plus modified Papervision libraries & PanoSalado libraries) and tweak to their heart's content; Those less inclined to Actionscript-at-the-core can edit an XML file or two, create their own modular Flash (.swf) add-ons or plugins if they want, and run, run, run with the ball. Other than being free, what could be better? :-)

The basic right-out-of-the-box idea is:
  * Create a basic XML file which describes the panorama(s)
  * Point the PanoSalado engine at your XML

Extending it further:
  * Create an advanced XML file which describes the panorama(s)
    1. Include element describing/pointing to an interface .swf to be layered over panorama
    1. Include another element describing/pointing to another .swf
    1. Include "hotspot" elements which will be pinned to the panorama(s) in 3D space, and can execute functions/tweens, etc.
    1. and so on
  * Build onto ModuleLoader.swf to integrate the PanoSalado environment into a larger Flash application
  * Create other interface .swf file(s) which communicate with PanoSalado engine, and can execute functions/tweens, etc. Flex users can reference the included Flex MXML and Actionscript as a starting point.

The image quality and performance match or better the quality of any of the commercial Flash panorama viewers out there, so we think it's worth a look. Enjoy!

**If you're trying it out, or deploying it, we'd love to know!**
http://sourceforge.net/projects/panosalado/