#!/bin/bash
#path to the objects list
CSV_PATH="$1";
#default jpeg size
FITS_SIZE="$2";
#sets ";" as the field separator
export IFS=";";


#getCoaddId##########################################################################################################################
#
# gets the id of the resource containing the object with coordinates RA,DEC
# $1 string Right Ascention
# $2 string declination
#
# returns string coaddID
#
# usage COADD_ID = $(getCoaddId $RA $DEC)
getCoaddId(){
	local RA=$1
	local DEC=$2
	#---------------------------------------------------------------
	#gets the id of the coadd containing the coordinate RA,DEC
	#----------------------------------------------------------------
	# wget makes a call through the IRSA's api to get the metadata of the coadd containing the coordinate RA,DEC (http://irsa.ipac.caltech.edu/ibe/queries.html)
	# awk  'FNR == 5 {print}' filters the fifth row of the table returned by wget
	# awk '{print $17}' gets the seventeenth column of the row returned by the previous awk
	COADD_URL="http://irsa.ipac.caltech.edu/ibe/search/wise/allwise/p3am_cdd?POS=${RA},${DEC}"
	COADD_ID=$(wget -q -O - "${COADD_URL}" |  awk 'FNR == 5 {print}' | awk '{print $17;}')

	echo $COADD_ID
}
#transformFitsToJpeg#################################################################################################################
#
# transforms a fits image to a jpeg image usign SAO DS9
# $1 string fits name
# $2 string jpeg name
# $3 string ds9 scale mode
# $4 string ds9 scale distribution
# $5 string ds9 colour map
# $6 string x-axis value for the center of a circle surrounding the target object
# $7 string y-axis value for the center of a circle surrounding the target object
#
# returns 
transformFitsToJpeg(){
	local JPEG_NAME=$2;
	local FITS_NAME=$1;
	local JPEG_SCALE_MODE=$3;
	local JPEG_SCALE_DISTRIBUTION=$4;
	local CMAP=$5;
	local X=$6;
	local Y=$7;

	#fits to jpeg transformation
	#----------------------------------------------------
	#ds9 can convert a fits image to a jpeg image
	#----------------------------------------------------
	# scale mode changes the scale of the pixels's intensity
	# cmap Cool applies a blue based colour palette

	# export jpeg  XX saves the image as JPEG conserving XX% of the original quality of the fits image 
	# exit exits ds9
	#converts fits to JPEG
	ds9 $FITS_NAME -scale $JPEG_SCALE_DISTRIBUTION -scale mode $JPEG_SCALE_MODE -zoom to fit -cmap $CMAP -export jpeg $JPEG_NAME 100 -exit;
	#adds a circle around the targeted object
	drawCircleInJpeg $JPEG_NAME $FITS_NAME $X $Y
} 
#drawCircleInJpeg###################################################################################################################
#
# Draws a circle inside a jpeg image using the given xy coordinates
# $1 string path to the jpeg file
# $2 string path to the source fits file
# $3 string ra-coord of the circle's center
# $4 string dec-coord of the circle's center
drawCircleInJpeg (){
	local JPEG_NAME=$1;
	local FITS_NAME=$2;
	local RA=$3;
	local DEC=$4;

	#creates a region (circle) around the targeted object and saves it
	# ds9 can't save a jpg with regions on it (it will save the plain jpg discarding all the regions)
	# we create a file that contains the coordinates (in pixels) x y to draw the circle with another tool
	#
	#-regions command "FK5;circle(${RA}d,${DEC}d,0.01d)#color=red" draws a circle around the targeted object
	#-regions format xy Sets coordinates system to xy
	# -regions system image sets coordinates units to pixels
	#stores IFS (;) so that ";" can be printed in the ds9 command
	local OLD_IFS=$IFS;
	IFS="@";
	REGION_FILE="${JPEG_NAME}.reg";
	ds9 $FITS_NAME  -regions command "FK5;circle(${RA}d,${DEC}d,0.01d)" -regions format xy -regions system image -regions save $REGION_FILE -exit
	#gets the circle center coords inside the image
	CIRCLE_CENTER=$(cat $REGION_FILE | sed 's/^ *//;s/ *$//'); #trim
	#ensures that the IFS is ' \t\n'
	IFS=$' \t\n' 
	CIRCLE_COORDS=($CIRCLE_CENTER);
	#restores the old IFS
	IFS=$OLD_IFS
	#adds the circle
	python circle_plotter.py "${ACTUAL_FOLDER}/${JPEG_NAME}" ${CIRCLE_COORDS[0]} ${CIRCLE_COORDS[1]}
	#deletes the region file
	rm $REGION_FILE;
}
#createRGBImage#####################################################################################################################
#
# Creates a RGB image using three fits images
# 
# $1 string path of the fits image used for the green channel
# $2 string path of the fits image used for the blue channel
# $3 string path of the fits image used for the red channel
# $4 string path for the result jpeg image
# $5 string x-axis value for the center of a circle surrounding the target object
# $6 string y-axis value for the center of a circle surrounding the target object
createRGBImage(){
	local GREEN_FITS=$1;
	local BLUE_FITS=$2;
	local RED_FITS=$3;

	local JPEG_NAME=$4;

	local X=$5;
	local Y=$6;

	ds9 -rgb -green $GREEN_FITS -blue $BLUE_FITS -red $RED_FITS -export jpeg $JPEG_NAME 100 -exit

	drawCircleInJpeg $JPEG_NAME $GREEN_FITS $X $Y

}

#getFitsBand########################################################################################################################
#
# Gets he band of a fits file based on its file name
#
# $1 string fits filename
#
# return string fits's band
getFitsBand(){
	local FITS_FILENAME=$1;

	local OLD_IFS=$IFS;
	IFS="-";
	#example 
	#
	# 0045p711_ac51-w3-int-3.fits
	# splitted by '-' will result in [0045p711_ac51,w3(band),int-3.fits]
	FITS_NAME_SPLITTED=($FITS_FILENAME);

	IFS=$OLD_IFS
	echo ${FITS_NAME_SPLITTED[1]};
}



#MAIN###############################################################################################################################


# Basically this script has four steps:
# for-each line of the file indicated by CSV_PATH
#	 Step 1: Get the coadd id of the resource that contains the requested object
#	 Step 2: Get the fits files for the first, third and fourth band
#	 Step 3: Transforms the fits images to jpeg images (using only the third and fourth band)
#	 Step 4: using all 3 fits images, create a RGB Image
#
#
#

#Creates the folder "fits"
$(mkdir -p fits)
#Creates the folder "jpg"
$(mkdir -p jpg)
#writes header output
echo "name;coords;band;size;fits_path;palette;jpeg_path;scale_distribution;scale_mode" > output.csv;
while read NAME RA DEC JPG_SIZE; do #reads from a file specified by CSV_PATH
	##############################################################################
	#STEP 1: GETS THE COADD ID OF THE RESOURCE CONTAINING THE OBJECT
	echo "------------------------------------"
	echo "Getting coadd's metadata...";
	COADD_ID=$(getCoaddId $RA $DEC)
	echo "coaddId = $COADD_ID";
	echo "------------------------------------"
	##############################################################################


	COADD_GRP=${COADD_ID:0:2};
	COADD_RA=${COADD_ID:0:4};

	#IF defined CUTOUT_SIZE will override the default jpg size
	CUTOUT_SIZE=$FITS_SIZE;
	if [[ ! -z $JPG_SIZE ]];
	then	
		CUTOUT_SIZE=$JPG_SIZE;
	fi

	##############################################################################
	#STEP 2: DOWNLOAD THE FITS IMAGE FOR BANDS 1,3 & 4
	#atores the fitses names
	FITS_NAMES=();
	#gets bands 1,3 & 4 of each coordinate
	for BAND in 1 3 4; do
		ACTUAL_FOLDER=$(pwd);
		RESOURCE_NAME="$COADD_ID-w$BAND-int-3";

		FITS_NAME="$RESOURCE_NAME.fits";
		FITS_NAMES+=($FITS_NAME);
		#sets the fits's size (the size of the actual area of the photo not the byte size)
		REQUEST_PARAMATERS=""
		OUTPUT_SIZE_VALUE="7200arcsec" #value of the output's fits size
		if [[ $CUTOUT_SIZE != "" && $CUTOUT_SIZE != "0" ]];
                  then  
                    #-----------------------------------------------------------
                    # Used to do cutouts to the original fits file
                    #-----------------------------------------------------------
                    REQUEST_PARAMATERS="?center=${RA},${DEC}&size=${CUTOUT_SIZE}"
                    OUTPUT_SIZE_VALUE="${CUTOUT_SIZE}"
                fi
		#-----------------------------------------------------------
		# Fits's URL 
		FITS_URL="http://irsa.ipac.caltech.edu/ibe/data/wise/allwise/p3am_cdd/$COADD_GRP/$COADD_RA/$COADD_ID/$FITS_NAME.gz${REQUEST_PARAMATERS}";
		echo "downloading $FITS_NAME ....";	 
		$(wget -P fits/ --content-disposition $FITS_URL);
		echo "uncompressing file...";
		$(cd fits && gzip -df ${FITS_NAME}.gz);
	done #end for-each band
	##############################################################################

	##############################################################################
	# STEP 3: TRANSFROM THE FITS INTO JPG
	echo "transforming fits to JPG...";
	for FITS_NAME in ${FITS_NAMES[1]} ${FITS_NAMES[2]}; do #only transforms bands 3 & 4
		for cmap in Cool Hsv Heat; do
			#sets pixels´s scale of intensity
			JPEG_SCALE_MODE=99.5;
			JPEG_SCALE_DISTRIBUTION="pow";
			#gets the fits band
			BAND=$(getFitsBand $FITS_NAME)
			#transforms the fits into a jpg file

			JPEG_NAME="${NAME}-${BAND}-${cmap}-${JPEG_SCALE_DISTRIBUTION}-${JPEG_SCALE_MODE}.jpg";
			transformFitsToJpeg "fits/${FITS_NAME}" "jpg/${JPEG_NAME}" $JPEG_SCALE_MODE $JPEG_SCALE_DISTRIBUTION $cmap $RA $DEC

			#writes output
			$(sed -i "$ a ${NAME};${RA},${DEC};$BAND;$OUTPUT_SIZE_VALUE;${ACTUAL_FOLDER}/${FITS_NAME};${cmap};${ACTUAL_FOLDER}/jpg/${JPEG_NAME};${JPEG_SCALE_DISTRIBUTION};${JPEG_SCALE_MODE}" output.csv);	
			echo "$FITS_NAME converted to $JPEG_NAME";
			echo "------------------------------------"
		done #end jpeg transformations
	done #fits processing
	##############################################################################

	##############################################################################
	# STEP 4 CREATES RGB IMAGE
	echo "Creating a RGB image...";
	RGB_IMAGE_NAME="jpg/${NAME}-rgb.jpg";
	createRGBImage "fits/${FITS_NAMES[0]}" "fits/${FITS_NAMES[1]}" "fits/${FITS_NAMES[2]}" $RGB_IMAGE_NAME $RA $DEC;
	#writes to output
	$(sed -i "$ a ${NAME};${RA},${DEC};;$OUTPUT_SIZE_VALUE;${FITS_NAMES[0]},${FITS_NAMES[1]},${FITS_NAMES[2]};RGB;${ACTUAL_FOLDER}/jpg/${JPEG_NAME};;" output.csv);
	echo "${RGB_IMAGE_NAME} created...";
	##############################################################################
	#end of while  
done < $CSV_PATH #reads from a file specified by CSV_PATH