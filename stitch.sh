#!/bin/bash


list=(./enfused/*)

echo $((${#list[@]})) fichiers
echo $((${#list[@]}/4)) panos

nd=$((${#list[@]}/4))

nf=4    #((nf = (${#list[@]} / nd) + 1))                         


for (( i=1; i<=nd; i++ )); do
	filestostitch=${list[@]:(i-1)*nf:nf}
	stitchto="./stitched/pano"$i".jpg"
	
	echo $filestostitch
	echo $stitchto

		FN="stitched.pto"
		OFN="stitched"
		FOV=180
		projectionNumber=3
		maskName="boardInTheMiddle.msk"
		
		yaw0=90
		yaw1=0
		yaw2=180
		yaw3=270
		pitch0=0
		pitch1=0
		pitch2=0
		pitch3=0
		roll0=0
		roll1=0
		roll2=0
		roll3=0
		
		./MacOS/pto_gen -o $FN -f $FOV -p $projectionNumber $filestostitch
		./MacOS/pto_var -o $FN --set y0=$yaw0,p0=$pitch0,r0=$roll0 $FN
		./MacOS/pto_var -o $FN --set y1=$yaw1,p1=$pitch1,r1=$roll1 $FN
		./MacOS/pto_var -o $FN --set y2=$yaw2,p2=$pitch2,r2=$roll2 $FN
		./MacOS/pto_var -o $FN --set y3=$yaw3,p3=$pitch3,r3=$roll3 $FN
		
		
		# get control points
		./MacOS/cpfind --multirow -o $FN $FN
		./MacOS/celeste_standalone -i $FN -o $FN
		#./MacOS/cpclean -v --output $FN $FN
		./MacOS/cpclean -o $FN $FN
		./MacOS/autooptimiser -a -l -s -o $FN $FN
		
		
		
		# create the panorama tiff
		./MacOS/pano_modify -s -c --canvas=auto --fov=360x180 -o $FN $FN
		
		for r in $(seq 0 3)
		do
			./MacOS/nona -z LZW -r ldr -m TIFF_m -o $OFN -i $r $FN
		done
		
		#enblend --compression=LZW -w -f17058x4131+0+2422 -o "${OFN}.tif" -- "${OFN}0000.tif" "${OFN}0001.tif" "${OFN}0002.tif" "${OFN}0003.tif"
		./MacOS/enblend -o stitched.tif -- stitched0000.tif stitched0001.tif stitched0002.tif stitched0003.tif
		
		imgwidth=$(identify -format '%w' stitched.tif)
		imgheight=$(identify -format '%h' stitched.tif)
		
		echo "Burning final jpeg (normalized), size :"
		echo $((imgwidth))x$(( imgwidth/2 ))
		
		convert stitched.tif -background black -sharpen 0x1.0 -normalize -gravity north -extent $((imgwidth))x$(( imgwidth/2 )) $stitchto
		
		echo "Exifing final jpeg ..."
		exiftool -overwrite_original -Make=Kinoki.fr -Model=KINOBOT -Software=KINOSTITCH -FullPanoWidthPixels=$((imgwidth)) -FullPanoHeightPixels=$(( imgwidth/2 )) -CroppedAreaImageWidthPixels=$((imgwidth)) -CroppedAreaImageHeightPixels=$(( imgwidth/2 )) -CroppedAreaLeftPixels=0 -CroppedAreaTopPixels=0 -UsePanoramaViewer=True -ProjectionType=equirectangular -PoseHeadingDegrees=0 $stitchto
		
		rm "${OFN}0000.tif" "${OFN}0001.tif" "${OFN}0002.tif" "${OFN}0003.tif" "${FN}" stitched.tif

		echo "fini "$stitchto
	
    #echo "${list[@]:(i-1)*nf:nf}" "./enfused/pano$i"
	#mv "${list[@]:(i-1)*nf:nf}" "./enfused/pano$i"
done

echo "fini de stitcher"
