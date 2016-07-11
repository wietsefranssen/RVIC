#!/bin/bash
## 1. Obtain Flow Direction Raster 
# Documentation: 
# http://rvic.readthedocs.org/en/latest/user-guide/parameters/ 
dateTotal1=$(date -u +"%s") # start time of the RUN
datePart1=$(date -u +"%s") # start time of the RUN

####### ONLY ADAPT THOSE LINES
domainInFile="./output/domain_EU.nc"
forcingFile="/home/wietse/Documents/Projects/VIC/VIC_testsetups/image_test/forcing/WFDEI_GPCC_EU.1981.nc"

tempPath="./temp/"
scriptName="$0"

rm -r $tempPath
mkdir -p $tempPath

#############################
## Make mask based on forcing-data file 
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Update the domain file"    
echo "***************************************" 
cdo seltimestep,1 $forcingFile $tempPath"/focing_t1.nc"
ncks -v Tair  $tempPath"/focing_t1.nc" $tempPath"/temp_mask.nc"
ncrename -v Tair,mask1 $tempPath"/temp_mask.nc"
# make all values higher than 0: 1
cdo ifthenc,1 $tempPath"/temp_mask.nc" $tempPath"/temp_forcing_mask.nc"

ncks -v mask $domainInFile $tempPath"/temp_domain_mask.nc"
cdo setctomiss,0 $tempPath"/temp_domain_mask.nc" $tempPath"/temp_domain_mask_missValue.nc"

# combine both masks
cdo mul $tempPath"/temp_domain_mask_missValue.nc" $tempPath"/temp_forcing_mask.nc" $tempPath"/temp_combined_mask.nc" 

#############################
## Update domain file
echo 
echo "***************************************" 
echo "** since previous part: $(printf "%03d\n" $(($(date -u +"%s")-$datePart1))) sec *******"; datePart1=$(date -u +"%s")
echo "** Update the domain file"    
echo "***************************************" 
ncks -A -v mask $tempPath"/temp_combined_mask.nc" $domainInFile


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
