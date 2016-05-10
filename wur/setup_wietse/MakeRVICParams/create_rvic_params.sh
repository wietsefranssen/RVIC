#!/bin/bash
## 1. Obtain Flow Direction Raster 
# Documentation: 
# http://rvic.readthedocs.org/en/latest/user-guide/parameters/ 

####### ONLY ADAPT THOSE LINES
outputPath="./output/"

flowDirectionInput="ddm30"
#flowDirectionInput="download" #--> not working yet

domain="-179.75,179.75,-55.75,83.75"; domainName="global"
domain="-24.25,39.75,33.25,71.75"; domainName="EU"
domain="0.25,10.25,50.25,55.55"; domainName="NL"
#domain="-85.25,-30.25,-60.25,15.25"; domainName="S-America"
####### ONLY ADAPT THOSE LINES


rvicPath="$(pwd)/../../../"
inputPath="./input/"
tempPath="./temp/"

rm -r $tempPath
rm -r $outputPath

mkdir -p $inputPath
mkdir -p $outputPath
mkdir -p $tempPath

outputFile="input_"$domainName".nc"

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
gdal_translate $tempPath"flowdirection.asc" -of netCDF $tempPath"flowdirection.nc"
ncrename -v Band1,flow_direction $tempPath"flowdirection.nc"

# select domain
cdo sellonlatbox,$domain $tempPath"flowdirection.nc" $tempPath"flowdirection_"$domainName".nc"
gdal_translate -of AAIGrid $tempPath"flowdirection_"$domainName".nc" $tempPath"flowdirection_"$domainName".asc"

## 2. Calculate grid box Flow Distance 
# compile create_xmask
gcc $inputPath"/create_xmask.c" -o $tempPath"/create_xmask" -lm
# create DRT_Flowdistance_globe_ARCGIS_half.asc
$tempPath"/create_xmask" $tempPath"flowdirection_"$domainName".asc" $tempPath"flowdistance_"$domainName".asc"
gdal_translate $tempPath"flowdistance_"$domainName".asc" -of netCDF $tempPath"flowdistance_"$domainName".nc"
ncrename -v Band1,flow_distance $tempPath"flowdistance_"$domainName".nc"

## 3. Calculate basin_id and land mask
## and
## 4. Calculate Source_Area
# create mask
cdo eq $tempPath"flowdirection_"$domainName".nc" $tempPath"flowdirection_"$domainName".nc" $tempPath"mask_"$domainName".nc"
ncrename -v flow_direction,mask $tempPath"mask_"$domainName".nc"
## create basin_id and sourcearea (flow accumulation)
Rscript $inputPath"/accumulate.R" $tempPath"flowdirection_"$domainName".nc" $tempPath"flowaccumulation_"$domainName".nc"

#############################
## Create domain file
# convert netcdf to ascii
gdal_translate -of AAIGrid $tempPath"mask_"$domainName".nc" $tempPath"fraction_"$domainName".asc"

# establish the domain file (domain.rvic.europe.20160208.nc)
$rvicPath"/tools/fraction2domain.bash" $tempPath"fraction_"$domainName".asc" $domainName
mv "domain.rvic_"$domainName".nc" $outputPath"domain_"$domainName".nc"
ncrename -v mask,Land_Mask $outputPath"domain_"$domainName".nc"

## 5. Combine all into netcdf format file
#ncks -A $tempPath"mask_"$domainName".nc" $outputPath$outputFile
ncks -A $tempPath"flowdirection_"$domainName".nc" $outputPath$outputFile
ncks -A $tempPath"flowdistance_"$domainName".nc" $outputPath$outputFile
ncks -A $tempPath"flowaccumulation_"$domainName".nc" $outputPath$outputFile
ncks -A $outputPath"domain_"$domainName".nc" $outputPath$outputFile

#############################
## Create Pour Points File
python2.7 $rvicPath"/tools/find_pour_points.py" $outputPath$outputFile $outputPath"pour_points_"$domainName".csv" --which_points all 
#############################
## Create UH BOX File
# todo

#############################
## Create RVIC parameters
#source activate rvic
cp $inputPath"/rvic_parameters.conf" $tempPath"/rvic_parameters.conf"
sed -i "s|FILE_NAME = ./pour_points.csv|FILE_NAME = ./output/pour_points_$domainName.csv|" $tempPath"/rvic_parameters.conf"  
sed -i "s|FILE_NAME = ./input.nc|FILE_NAME = ./output/input_$domainName.nc|" $tempPath"/rvic_parameters.conf"  
sed -i "s|FILE_NAME = ./domain.nc|FILE_NAME = ./output/domain_$domainName.nc|" $tempPath"/rvic_parameters.conf"  
sed -i "s|CASEID = casename|CASEID = $domainName|" $tempPath"/rvic_parameters.conf"  
rvic parameters $tempPath"/rvic_parameters.conf"

mv $(find $tempPath"/RVIC_params/output/params/" -type f | grep rvic) $outputPath"/RVIC_params_"$domainName".nc"


#############################
## Convert RVIC parameters lonlat
Rscript $inputPath"/convertRVICParams2Latlon.R" $outputPath"/RVIC_params_"$domainName".nc" $outputPath"/domain_"$domainName".nc" $outputPath"/RVIC_params_"$domainName"_lonlat.nc"

#############################
## Clean
rm -r $tempPath

#############################
## Done
echo ""
echo "***********************"
echo "****** DONE! **********"
echo "***********************"
echo "ouput is written to: "$outputPath
