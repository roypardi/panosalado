#/bin/sh
# Builds all PanoSalado and VideoWarp Player swfs using flex sdk and mxmlc

mxmlc PanoSalado.as
mxmlc PanoSaladoLoadMeter.as
mxmlc layout_7.mxml
mxmlc ModuleLoader.as
mxmlc VideoWarpPlayer.mxml

