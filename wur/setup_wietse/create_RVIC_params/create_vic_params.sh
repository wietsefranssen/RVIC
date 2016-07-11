#!/bin/bash
## 1. Obtain Flow Direction Raster 
# Documentation: 
# http://rvic.readthedocs.org/en/latest/user-guide/parameters/ 
dateTotal1=$(date -u +"%s") # start time of the RUN
datePart1=$(date -u +"%s") # start time of the RUN

####### ONLY ADAPT THOSE LINES
outputPath="./output/"

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
scriptName="$0"

rm -r $tempPath
rm -r $outputPath

mkdir -p $inputPath
mkdir -p $outputPath
mkdir -p $tempPath

outputFile="VIC_input_"$domainName".nc"

#############################
## Create VIC parameters
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Create vic parameter file"    
echo "***************************************" 
domainFile=$outputPath"domain_"$domainName".nc"
outVICParamFile=$outputPath"VIC_params_"$domainName".nc"
cp $inputPath"/create_vic_params.py" $tempPath
sed -i "s|soil_file   = ''|soil_file   = '$tonicParamsPath/LibsAndParams_isimip/global_soil_file.new.arno.modified.wb.isimip'|" $tempPath"/create_vic_params.py" 
sed -i "s|snow_file   = ''|snow_file   = '$tonicParamsPath/LibsAndParams_wietse/new_snow'|" $tempPath"/create_vic_params.py" 
sed -i "s|veg_file    = ''|veg_file    = '$tonicParamsPath/LibsAndParams_isimip/global_veg_param.txt'|" $tempPath"/create_vic_params.py" 
sed -i "s|veglib_file = ''|veglib_file = '$tonicParamsPath/LibsAndParams_isimip/world_veg_lib.txt'|" $tempPath"/create_vic_params.py" 
sed -i "s|domain_file = ''|domain_file = '$domainFile'|" $tempPath"/create_vic_params.py" 
sed -i "s|out_file    = ''|out_file    = '$outVICParamFile'|" $tempPath"/create_vic_params.py" 
sed -i "s|lonlat      = ,,,|lonlat      = $domain|" $tempPath"/create_vic_params.py" 
python $tempPath"/create_vic_params.py"

#############################
## Create domain file
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Establish the domain file"    
echo "***************************************" 
ncks -v run_cell $outVICParamFile $domainFile
ncrename -v run_cell,frac $domainFile
ncatted -O -a long_name,frac,o,c,"fraction of grid cell that is active" $domainFile
ncatted -O -a note,frac,a,c,"unitless" $domainFile
ncatted -h -a history,global,d,, $domainFile 

cdo gridarea $domainFile $tempPath"/area_"$domainName".nc"
ncrename -v cell_area,area $tempPath"/area_"$domainName".nc"
ncks -A -v area $tempPath"/area_"$domainName".nc" $domainFile

ncap2 -O -v -s 'mask=frac' $domainFile $tempPath"/mask1_"$domainName".nc"
ncap2 -O -v -s 'where(mask>0.0000001) mask=1; elsewhere mask=0;' $tempPath"/mask1_"$domainName".nc" $tempPath"/mask_"$domainName".nc"
ncatted -O -a long_name,mask,a,c,"domain mask" $tempPath"/mask1_"$domainName".nc"
ncatted -O -a note,mask,a,c,"unitless" $tempPath"/mask1_"$domainName".nc"
ncatted -O -a comment,mask,a,c,"0 value indicates cell is not active" $tempPath"/mask1_"$domainName".nc"
ncks -A -v mask $tempPath"/mask1_"$domainName".nc" $domainFile

ncatted -O -a title,global,a,c,"RVIC domain data" $domainFile
ncatted -O -a source,global,o,c,"$scriptName" $domainFile
ncatted -h -a history,global,o,c,"created by $(whoami) at $(eval date +%Y-%m-%d-%T)" $domainFile

#############################
## TOTAL DURATION OF THE RUN
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
