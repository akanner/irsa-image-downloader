#!/usr/bin/python


#plots a circle in an existing jpg

from PIL import Image
from PIL import ImageDraw

import sys
import os

#gets the current path

#219.24678 219.49592
img_path = sys.argv[1]
#coords
x = float(sys.argv[2])
y = float(sys.argv[3])
r = 50

image = Image.open(img_path);
#In PIL y=0 is the TOP of the image
#In DS9 y=0 is de bottom of the image
y = image.height - y;
draw = ImageDraw.Draw(image);
draw.ellipse((x-r, y-r, x+r, y+r), outline=(255,0,0,0))

image.save(img_path, 'JPEG')