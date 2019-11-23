#!/usr/bin/python


#plots a circle in an existing jpg

from PIL import Image
from PIL import ImageDraw

import sys
import os

def draw_ellipse(image, bounds, width=1, outline='white', antialias=4):
    """Improved ellipse drawing function, based on PIL.ImageDraw."""

    # Use a single channel image (mode='L') as mask.
    # The size of the mask can be increased relative to the imput image
    # to get smoother looking results. 
    mask = Image.new(
        size=[int(dim * antialias) for dim in image.size],
        mode='L', color='black')
    draw = ImageDraw.Draw(mask)

    # draw outer shape in white (color) and inner shape in black (transparent)
    for offset, fill in (width/-2.0, 'white'), (width/2.0, 'black'):
        left, top = [(value + offset) * antialias for value in bounds[:2]]
        right, bottom = [(value - offset) * antialias for value in bounds[2:]]
        draw.ellipse([left, top, right, bottom], fill=fill)

    # downsample the mask using PIL.Image.LANCZOS 
    # (a high-quality downsampling filter).
    mask = mask.resize(image.size, Image.LANCZOS)
    # paste outline color to input image through the mask
    image.paste(outline, mask=mask)

#gets the current path

#219.24678 219.49592
img_path = sys.argv[1]
#coords
x = float(sys.argv[2])
y = float(sys.argv[3])


image = Image.open(img_path);
#In PIL y=0 is the TOP of the image
#In DS9 y=0 is de bottom of the image
y = image.height - y;
#uses the width of the image to draw a circle with a radius of 15 % the width of the image
r = image.width *10 / 100;
draw = ImageDraw.Draw(image);
#circles points
x1 = x-r;
y1 = y-r;
x2 = x+r;
y2 = y+r;
circleBounds = [x1,y1,x2,y2];
circleWidth = image.width *0.5 / 100; #0.5% of the image's width

#draw.ellipse((x1, y1, x2, y2), outline=(255,255,255,0))

draw_ellipse(image,circleBounds,circleWidth)

image.save(img_path, 'JPEG')
