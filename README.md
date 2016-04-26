# zbs-texturepacker
Zerobrane Studio Integration for libGDX texture packer 

Usage
-----
 1. Copy contents of this repo into either `.zbstudio/packages` or into `packages` folder under zerobranestudio install
 2. Confirm it installed by running ZBS and seeing the `Texture Packer Project Settings` option under `Project` menu
 3. Create atlas by creating folders containing all images to pack into an atlas
 4. right click on folder containing images and select `Create Texture Atlas`
 5. Configure atlas accordingly (pack name is the name of resulting png and atlas files)
 6. Build atlas by clicking on new atlas button in toolbar, or right clicking on atlas folder in project outline and selecting `Build Texture Atlas`
 7. To install `atlasreader.lua` and `moaiatlas.lua` into your source, right click on the folder where you would like the files and select `Install Atlas Reader`
 
Using created atlas files
-------------------------
Assuming you had an atlas with pack name `testatlas` with a file `flag_blue.png`, and you have already built it using `build texture atlas` and installed the libs then 
you can load and use texture atlas for moai as below:

```lua
local Atlas = require('moaiatlas')

MOAISim.openWindow ( "test", 320, 480 )

viewport = MOAIViewport.new ()
viewport:setSize ( 320, 480 )
viewport:setScale ( 320, 480 )

layer = MOAILayer2D.new ()
layer:setViewport ( viewport )
MOAISim.pushRenderPass ( layer )


local testatlas = Atlas('testatlas.atlas')

local prop = MOAIProp2D.new ()

testatlas:assignToProp('flag_blue',prop)

prop:setLoc ( 0, 80 )
layer:insertProp ( prop )

```

assignToProp sets the props Deck and Index to the correct values for it to show the given image.

Tips:
----
See libgdx texture packer docs for more info https://github.com/libgdx/libgdx/wiki/Texture-packer

 * Files ending in _X where x is a number, will have the _X removed and will be stored with multiple indexes in the deck
   eg, number_1.png, number_2.png, number_3.png might come out of the atlas as a deck with texture=atlas.png name="number" index=2,3,4
   you could then animate the prop index to get a flipbook animation.
 * Once a texture has been built, you can double click on the atlas folder to see the compiled atlas
 * Too many images to fit in a single atlas texture will bleed over to another texture and deck, but will still remain accessible the same way.

Contribution
------------

This works enough to share with you all, but contributions are welcome to clean it up.


