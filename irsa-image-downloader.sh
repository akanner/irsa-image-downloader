#!/bin/bash

CSV_PATH="$1";
FITS_SIZE="$2";
#sets ";" as the field separator
export IFS=";";




#Creates the folder "fits"
$(mkdir -p fits)
#Creates the folder "jpg"
$(mkdir -p jpg)
#writes header output
echo "name;coords;band;size;fits_path;palette;jpeg_path;scale_distribution;scale_mode" > output.csv;
while read NAME RA DEC JPG_SIZE; do #reads from a file specified by CSV_PATH
	echo "------------------------------------"
	echo "Getting coadd's metadata...";
	#---------------------------------------------------------------
	#gets the id of the coadd containing the coordinate RA,DEC
	#----------------------------------------------------------------
	# wget makes a call through the IRSA's api to get the metadata of the coadd containing the coordinate RA,DEC (http://irsa.ipac.caltech.edu/ibe/queries.html)
	# awk  'FNR == 5 {print}' filters the fifth row of the table returned by wget
	# awk '{print $17}' gets the seventeenth column of the row returned by the previous awk
	COADD_URL="http://irsa.ipac.caltech.edu/ibe/search/wise/allwise/p3am_cdd?POS=${RA},${DEC}"
	COADD_ID=$(wget -q -O - "${COADD_URL}" |  awk 'FNR == 5 {print}' | awk '{print $17;}')
	#IF defined JPG_SIZE will override the default jpg_size
	if [[ ! -z $JPG_SIZE ]];
	then	
		FITS_SIZE=$JPG_SIZE;
	fi
	echo "coaddId = $COADD_ID";

	COADD_GRP=${COADD_ID:0:2};
	COADD_RA=${COADD_ID:0:4};


	echo "Generating fits image's URL...";
	#gets bands 3 & 4 of each coordinate
	for BAND in 3 4; do
		ACTUAL_FOLDER=$(pwd);
		RESOURCE_NAME="$COADD_ID-w$BAND-int-3";

		FITS_NAME="$RESOURCE_NAME.fits";
		#sets the fits's size (the size of the actual area of the photo not the byte size)
		REQUEST_PARAMATERS=""
		OUTPUT_SIZE_VALUE="standard-nasa-size" #value of the output's fits size
		if [[ $FITS_SIZE != "" && $FITS_SIZE != "0" ]];
                  then  
                    #-----------------------------------------------------------
                    # Used to do cutouts to the original fits file
                    #-----------------------------------------------------------
                    REQUEST_PARAMATERS="?center=${RA},${DEC}&size=${FITS_SIZE}"
                    OUTPUT_SIZE_VALUE="${FITS_SIZE}"
                fi
		#-----------------------------------------------------------
		# Fits's URL 
		FITS_URL="http://irsa.ipac.caltech.edu/ibe/data/wise/allwise/p3am_cdd/$COADD_GRP/$COADD_RA/$COADD_ID/$FITS_NAME.gz${REQUEST_PARAMATERS}";
		echo "downloading $FITS_NAME ....";	 
		$(wget -P fits/ --content-disposition $FITS_URL);
		echo "uncompressing file...";
		$(cd fits && gzip -df ${FITS_NAME}.gz);
		echo "transforming fits to JPG";
		
		#sets pixels´s scale of intensity
		JPEG_SCALE_MODE=99.5;
		JPEG_SCALE_DISTRIBUTION="pow";
		#----------------------------------------------------
		#ds9 can convert a fits image to a jpeg image
		#----------------------------------------------------
		# scale mode changes the scale of the pixels's intensity
		# cmap Cool applies a blue based colour palette
		# -regions command "FK5;circle(${RA}d,${DEC}d,0.01d)#color=red" draws a circle around the targeted object
		# export jpeg  XX saves the image as JPEG conserving XX% of the original quality of the fits image 
		# exit exits ds9
		
		for cmap in Cool Hsv Rainbow; do
		  JPEG_NAME="${NAME}-${RESOURCE_NAME}-${cmap}-${JPEG_SCALE_DISTRIBUTION}-${JPEG_SCALE_MODE}.jpg";
		  #fits to jpeg transformation
		  #stores IFS (;) so that ";" can be printed in the ds9 command
		  OLD_IFS=$IFS;
		  IFS="@";
	  	  ds9 fits/$FITS_NAME -scale $JPEG_SCALE_DISTRIBUTION -scale mode $JPEG_SCALE_MODE -zoom to fit -cmap $cmap -regions command "FK5;circle(${RA}d,${DEC}d,0.01d)#color=red" -export jpeg jpg/$JPEG_NAME 75 -exit;
	  	  #restores IFS
	  	  IFS=$OLD_IFS;
		  #writes output
	  	  $(sed -i "$ a ${NAME};${RA},${DEC};$BAND;$OUTPUT_SIZE_VALUE;${ACTUAL_FOLDER}/${FITS_NAME};${cmap};${ACTUAL_FOLDER}/jpg/${JPEG_NAME};${JPEG_SCALE_DISTRIBUTION};${JPEG_SCALE_MODE}" output.csv);	
		  echo "$FITS_NAME converted to $JPEG_NAME";
		  echo "------------------------------------"
		done #end jpeg transformations
	echo "------------------------------------"
	done #end for-each band
	#end of while  
done < $CSV_PATH #reads from a file specified by CSV_PATH