# DualCam
Fiji Macro to automatically split and transform microscopy images with dualcam setting.

### Installation

1. Download the zip file and decompress.

2. Copy "_DualCamera.ijm" to the Fiji directory (Mac: Fiji.App) > Plugins.

3. Start Fiji.

4. The macro should be now in Plugins > DualCamera.

### Process

1. Select if you want to calibrate your image.
  a. If yes, select the calibration image.
  b. If no, select a transformation matrix.
  
2. Select the images for processing.

  a. If there is only one image in the folder, it will be processed automatically.
  
  b. If there are multiple images, select all or just one image for processing.
  
### Requirements

- Store the calibration image in a separate folder from the images for processing.
- Only tif files are supported.
- TurboReg has to be installed in Fiji (http://bigwww.epfl.ch/thevenaz/turboreg/).
- MultiStackReg has to be installed in Fiji (http://bradbusse.net/sciencedownloads.html).
