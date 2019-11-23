#!/usr/bin/python


from PIL import Image
from PIL import ImageDraw

import sys
import os

#gets the current path

#219.24678 219.49592
img_path = sys.argv[1]
#coords
x = int(float(sys.argv[2]))
y = int(float(sys.argv[3]))

#script path
pathname = os.path.dirname(sys.argv[0]);

background = Image.open(img_path);
alpha = Image.open(img_path);

foreground = Image.open(pathname + "/star-transparency5.png");
#In PIL y=0 is the TOP of the image
#In DS9 y=0 is the bottom of the image
y = background.height - y;

#adjust coorditates with the foreground image
x = x - (foreground.width / 2);
y = y - (foreground.height / 2);


background.paste(foreground, (x,y), foreground);
#uses the width of the image to draw a circle with a radius of 15 % the width of the image
r = background.width *10 / 100;

draw = ImageDraw.Draw(background);


background.save(img_path, 'JPEG')