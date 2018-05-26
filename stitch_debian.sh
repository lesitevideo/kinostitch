#!/bin/bash

SECONDS=0;
list=(./enfused/*.jpg)

echo $((${#list[@]})) fichiers
echo $((${#list[@]}/4)) panos

nd=$((${#list[@]}/4))

nf=4                     


for (( i=1; i<=nd; i++ )); do
	filestostitch=${list[@]:(i-1)*nf:nf}
	stitchto="./panos/pano"$i".jpg"
	
	echo $filestostitch
	echo $stitchto

		FN="stitched.pto"
		OFN="stitched"
		FOV=180  #118  #109.7
		projectionNumber=2 #0 - rectilinear, 2 - equirectangular, 3 - full-frame fisheye ...
		maskName="boardInTheMiddle.msk"
		
		#generate .pto
		pto_gen -o $FN -f $FOV -p $projectionNumber $filestostitch
        
		# get control points
		cpfind -v --multirow --celeste -o $FN $FN
        
        #control errors cpfind
        ret=$?
        if [ $ret -ne 0 ]
        then
          echo "ERROR cpfind: $ret"
          exit $ret
        fi
        
		celeste_standalone -d ./celeste.model -i $FN -o $FN

		cpclean -o $FN $FN
		autooptimiser -a -l -s -o $FN $FN	
		
		# panorama options (straighten, set FOV to auto, optimal size)
		pano_modify -s -c --canvas=AUTO -o $FN $FN
		
		for r in $(seq 0 3)
		do
			nona -z LZW -r ldr -m TIFF_m -o $OFN -i $r $FN
			#nona -r ldr -m PNG_m -o $OFN -i $r $FN
		done
		
		#enblend --compression=LZW -w -f17058x4131+0+2422 -o "${OFN}.tif" -- "${OFN}0000.tif" "${OFN}0001.tif" "${OFN}0002.tif" "${OFN}0003.tif"
		enblend --compression=LZW -o stitched.tif -- stitched0000.tif stitched0001.tif stitched0002.tif stitched0003.tif

		imgwidth=$(identify -format '%w' stitched.tif)
		imgheight=$(identify -format '%h' stitched.tif)
		
		echo "Burning final jpeg (normalized), size :"
		echo $((imgwidth))x$(( imgwidth/2 ))

		convert stitched.tif -background black -sharpen 0x1.0 -normalize -extent $((imgwidth))x$(( imgwidth/2 )) $stitchto
		
		echo "Exifing panorama ..."
		exiftool -overwrite_original -Make=Kinoki.fr -Model=KINOBOT -Software=KINOSTITCH -FullPanoWidthPixels=$((imgwidth)) -FullPanoHeightPixels=$(( imgwidth/2 )) -CroppedAreaImageWidthPixels=$((imgwidth)) -CroppedAreaImageHeightPixels=$(( imgwidth/2 )) -CroppedAreaLeftPixels=0 -CroppedAreaTopPixels=0 -UsePanoramaViewer=True -ProjectionType=equirectangular -PoseHeadingDegrees=0 $stitchto
		
		rm "${OFN}0000.tif" "${OFN}0001.tif" "${OFN}0002.tif" "${OFN}0003.tif" "${FN}" stitched.tif

		echo "fini "$stitchto
	
done

echo "fini de stitcher en "$SECONDS" secondes"
