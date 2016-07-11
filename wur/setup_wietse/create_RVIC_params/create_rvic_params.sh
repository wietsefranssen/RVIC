#!/bin/bash
## 1. Obtain Flow Direction Raster 
# Documentation: 
# http://rvic.readthedocs.org/en/latest/user-guide/parameters/ 
dateTotal1=$(date -u +"%s") # start time of the RUN
datePart1=$(date -u +"%s") # start time of the RUN

####### ONLY ADAPT THOSE LINES
outputPath="./output_new3/"

flowDirectionInput="ddm30"
#flowDirectionInput="download" #--> not working yet

#minLon="-179.75"; maxLon="179.75"; minLat="-55.75" ; maxLat="83.75"; domainName="global"
#minLon="-85.25" ; maxLon="-30.25"; minLat="-60.25" ; maxLat="15.25"; domainName="S-America"
minLon="-24.25" ; maxLon="39.75" ; minLat="33.25"  ; maxLat="71.75"; domainName="EU"
#minLon="0.25"   ; maxLon="10.25" ; minLat="50.25"  ; maxLat="55.25"; domainName="NL"
#minLon="-0.75"   ; maxLon="10.75" ; minLat="49.75"  ; maxLat="55.75"; domainName="NL_2"
####### ONLY ADAPT THOSE LINES

domain=$minLon","$maxLon","$minLat","$maxLat
rvicPath="$(pwd)/../../../"
tonicParamsPath="../create_VIC_params/"
inputPath="./input/"
tempPath="./temp/"
domainFile="/home/wietse/Documents/WORKDIRS/anaconda3_downloadedProjects/RVIC/wur/setup_wietse/create_RVIC_params/output_new2/domain_"$domainName".nc"

rm -r $tempPath
rm -r $outputPath

mkdir -p $inputPath
mkdir -p $outputPath
mkdir -p $tempPath

outputFile="RVIC_input_"$domainName".nc"

echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Obtaining the file(s)"    
echo "***************************************" 
if [ "$flowDirectionInput" == "download" ]
then
  # Obtain the files: 
  wget ftp://ftp.ntsg.umt.edu/pub/data/DRT/upscaled_global_hydrography/by_HYDRO1K/WGS84/flow_direction/DRT_FDR_globe_ARCGIS_half.asc --directory-prefix=$inputPath"/data"
  wget ftp://ftp.ntsg.umt.edu/pub/data/DRT/upscaled_global_hydrography/by_HYDRO1K/WGS84/upstream_drainagearea/DRT_Source_Area_float_globe_half_geo.asc --directory-prefix=$inputPath"/data"

  # Rename to standard name
  mv $inputPath"/data/DRT_FDR_globe_ARCGIS_half.asc" $tempPath"flowdirection.asc"
  mv $inputPath"/data/DRT_Source_Area_float_globe_half_geo.asc" $tempPath"sourcearea.asc"

  ## Temp step to correct for wrong lat values... 
  sed -i "s/yllcorner.*/yllcorner -55.00/" $tempPath"flowdirection.asc"
  sed -i "s/yllcorner.*/yllcorner -55.00/" $tempPath"sourcearea.asc"
  
  gdal_translate $tempPath"sourcearea.asc" -of netCDF $tempPath"sourcearea.nc"
  ncrename -v Band1,source_area $tempPath"sourcearea.nc"
  # select domain
  cdo sellonlatbox,$domain $tempPath"sourcearea.nc" $tempPath"sourcearea_"$domainName".nc"
  gdal_translate -of AAIGrid $tempPath"sourcearea.nc" $tempPath"sourcearea_"$domainName".asc"
else
  cp $inputPath"/data/ddm30_flowdir_cru_neva.asc_VIC" $tempPath"flowdirection.asc"
fi

# Convert the files 
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Converting the file(s)"    
echo "***************************************" 
gdal_translate $tempPath"flowdirection.asc" -of netCDF $tempPath"flowdirection.nc"
ncrename -v Band1,flow_direction $tempPath"flowdirection.nc"

# select domain
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Select domain"    
echo "***************************************" 
cdo sellonlatbox,$domain $tempPath"flowdirection.nc" $tempPath"flowdirection_"$domainName".nc"
gdal_translate -of AAIGrid $tempPath"flowdirection_"$domainName".nc" $tempPath"flowdirection_"$domainName".asc"

## 2. Calculate grid box Flow Distance 
# compile create_xmask
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Compile and apply create_xmask"    
echo "***************************************" 
gcc $inputPath"/create_xmask.c" -o $tempPath"/create_xmask" -lm
# create DRT_Flowdistance_globe_ARCGIS_half.asc
$tempPath"/create_xmask" $tempPath"flowdirection_"$domainName".asc" $tempPath"flowdistance_"$domainName".asc"
gdal_translate $tempPath"flowdistance_"$domainName".asc" -of netCDF $tempPath"flowdistance_"$domainName".nc"
ncrename -v Band1,flow_distance $tempPath"flowdistance_"$domainName".nc"

## 3. Calculate basin_id and land mask
## and
## 4. Calculate Source_Area
# create mask
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Create mask"    
echo "***************************************" 
cdo eq $tempPath"flowdirection_"$domainName".nc" $tempPath"flowdirection_"$domainName".nc" $tempPath"mask_"$domainName".nc"
ncrename -v flow_direction,mask $tempPath"mask_"$domainName".nc"
## create basin_id and sourcearea (flow accumulation)
Rscript $inputPath"/accumulate.R" $tempPath"flowdirection_"$domainName".nc" $tempPath"flowaccumulation_"$domainName".nc"

#############################
## Create RVIC input file
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Create RVIC input file"    
echo "***************************************" 
#ncks -A $tempPath"mask_"$domainName".nc" $outputPath$outputFile
ncks -A $tempPath"flowdirection_"$domainName".nc" $outputPath$outputFile
ncks -A $tempPath"flowdistance_"$domainName".nc" $outputPath$outputFile
ncks -A $tempPath"flowaccumulation_"$domainName".nc" $outputPath$outputFile
ncks -A $domainFile $outputPath$outputFile

#############################
## Create Pour Points File
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Create Pour Points File"    
echo "***************************************" 
python $rvicPath"/tools/find_pour_points.py" $outputPath$outputFile $outputPath"RVIC_pour_points_"$domainName".csv" --which_points all 
#############################
## Create UH BOX File
# todo

#############################
## Create RVIC parameters
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Create rvic parameter file"    
echo "***************************************" 
cp $inputPath"/rvic_parameters.conf" $tempPath"/rvic_parameters.conf"
sed -i "s|FILE_NAME = ./pour_points.csv|FILE_NAME = ./output/RVIC_pour_points_$domainName.csv|" $tempPath"/rvic_parameters.conf"  
sed -i "s|FILE_NAME = ./input.nc|FILE_NAME = ./output/RVIC_input_$domainName.nc|" $tempPath"/rvic_parameters.conf"  
sed -i "s|FILE_NAME = ./domain.nc|FILE_NAME = ./output/domain_$domainName.nc|" $tempPath"/rvic_parameters.conf"  
sed -i "s|CASEID = casename|CASEID = $domainName|" $tempPath"/rvic_parameters.conf"  
rvic parameters $tempPath"/rvic_parameters.conf"

mv $(find $tempPath"/RVIC_params/output/params/" -type f | grep rvic) $outputPath"/RVIC_params_"$domainName"_tmp.nc"

#############################
## Convert RVIC parameters lonlat
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Create latlon file from rvic parameter file"    
echo "***************************************" 
Rscript $inputPath"/convertRVICParams2Latlon.R" $outputPath"/RVIC_params_"$domainName".nc" $outputPath"/domain_"$domainName".nc" $outputPath"/RVIC_params_"$domainName"_lonlat.nc"

#############################
## Create VIC parameters
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Create vic parameter file"    
echo "***************************************" 

##############################
### Update the domain file
## select variable out of file
#echo 
#echo "***************************************" 
#echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
#echo "** update the domain file (combine VIC and RVIC mask)"    
#echo "***************************************" 
#ncks -v mask $outputPath"domain_"$domainName".nc" $tempPath"/RVIC_mask_"$domainName".nc" 
#ncks -v cellnum $outputPath"VIC_params_"$domainName".nc" $tempPath"/VIC_cellnum_"$domainName".nc"
#
## correct strange error(?)
#ncdump $tempPath"/VIC_cellnum_"$domainName".nc" > $tempPath"/VIC_cellnum_"$domainName".txt"
#ncgen $tempPath"/VIC_cellnum_"$domainName".txt" -o $tempPath"/VIC_cellnum_"$domainName".nc"
#
## make all values higher than 0: 1
#cdo ifthenc,1 $tempPath"/VIC_cellnum_"$domainName".nc" $tempPath"/VIC_mask_"$domainName".nc"
#
## combine both masks
#cdo mul $tempPath"/RVIC_mask_"$domainName".nc" $tempPath"/VIC_mask_"$domainName".nc" $tempPath"/new_mask_"$domainName".nc"
#
## update the old domain file.
#ncks -A $tempPath"/new_mask_"$domainName".nc" $outputPath"domain_"$domainName"_tmp.nc"
## convert float mask to int mask
#ncap2 -s 'mask=int(mask)' $outputPath"domain_"$domainName"_tmp.nc" $outputPath"domain_"$domainName".nc"
#rm $outputPath"domain_"$domainName"_tmp.nc" 
#ncks -A $tempPath"/RVIC_mask_"$domainName".nc" $outputPath"domain2_"$domainName".nc"
#
#############################
## Clean
#rm -r $tempPath

#############################
## Done
### TOTAL DURATION OF THE RUN
dateTotal2=$(date -u +"%s") # end time
diffTotal=$(($dateTotal2-$dateTotal1))
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** SUMMARY" 
echo "** "
echo "** TOTAL: $(($diffTotal / 60)) minutes and $(($diffTotal % 60))"
echo "** "
echo "** ouput is written to: "$outputPath
echo "***************************************" 
