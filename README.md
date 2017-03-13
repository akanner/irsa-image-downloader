# irsa-image-downloader

 Bash script to download jpg images from [nasa's wise telescope](http://irsa.ipac.caltech.edu/applications/wise/) (it downloads images of the bands 3 & 4)
  using a file with a list of the desired objects's coordinates 
  
  



## What this script does?

The script will:
* Download the fits images for the coords given
* Transform the fits image into 3 jpeg (using the Cool Hsv and Rainbow palettes from DS9)
* generate a csv file with all the resulting files's information
 
 ## Requirements
 
* wget (`apt-get install wget`) 
* SAOImage DS9 (http://ds9.si.edu/site/Home.html)
* make sure that you have executing permission over the script and write permissions in the current folder

## Usage
  ./irsa-image-downloader.sh __path/to/list/file__ __[size]__
  
  ### size
  
  used to cut out the original fits image.
  
  #### From http://irsa.ipac.caltech.edu/ibe/cutouts.html
  The size parameter consists of one or two (comma separated) values followed by an optional units specification. Units can be pixels (px, pix, pixels) or angular (arcsec, arcmin, deg, rad); the default is degrees. The first size value (x) is taken to be the full-width of the desired cutout along the first image axis (NAXIS1), and the second (y) is taken to be the full-height along the second axis (NAXIS2). If only one size value is specified, it is used as both the full-width and full-height. Negative sizes are illegal. (from )
  
__If size is not specify, the fits image will not be cutted__

  Examples:

* 0.1
* 200px
* 100,200px
* 3arcmin
* 30,45arcsec


### Usage Examples
 * ./irsa-image-downloader.sh example-list/list.example
 * ./irsa-image-downloader.sh example-list/list.example 100
 * ./irsa-image-downloader.sh example-list/list.example 200arcsec
 * ./irsa-image-downloader.sh example-list/list.example 100,200px

### List syntax

the coordinates list has this syntax:

```
object_name;right ascention;declination
```

* __object_name__: this name will be used to name the output jpgs

#### Example

```
some_object;20;40
another_object;30;20
```

##### TODO

Here are some ideas:

* build a better parameter interface.
* Add a new parameter to specify the output folder and the output file's name.
* Add the possibility to choose different palettes (through new parameters).
* Add the possibility to generate RGB images
	* To do this, it may be needed to add a new band (to use one band per color)
