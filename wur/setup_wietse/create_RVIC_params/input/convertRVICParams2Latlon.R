rm (list = ls())

args = commandArgs(trailingOnly=TRUE)

if (length(args)!=3) {
  print("two arguments must be supplied (input file, domain file and output file).", call.=FALSE)
  print("Using defaults...")
  domainFile<-"/home/wietse/Documents/Projects/VIC/VIC_testsetups/image_test/input/LibsAndParams_isimip/mask_WFDEI_EU.nc"
  #domainFile<-"/home/wietse/Desktop/domain.rvic.europe.20160208.nc"
  
  paramFile<-"/home/wietse/Desktop/output_noRemap_3600/params/europe_all.rvic.prm.domain.20160425.nc"
  outFile<-"/home/wietse/Desktop/europe_all.rvic.prm.domain.20160425_lonlat2.nc"
  
  paramFile<-"//home/wietse/Desktop/RVIC_params/output_remap_86400/params/europe_all.rvic.prm.domain.20160425.nc"
  outFile<-paste0(paramFile,"_lonlat.nc")
  
  paramFile<-"/home/wietse/Desktop/Werk/RVIC_params/output_noRemap_86400/params/europe_all.rvic.prm.domain.20160425.nc"
  outFile<-paste0(paramFile,"_lonlat.nc")
  
  #paramFile<-"/home/wietse/Desktop/RVIC_params/output_remap_86400_new2/params/europe_all.rvic.prm.domain.20160426.nc"
  #outFile<-paste0(paramFile,"_lonlat.nc")
  
  #paramFile<-"/home/wietse/Desktop/europe_all.rvic.prm.domain.20160426.nc"
  #outFile<-paste0(paramFile,"_lonlat.nc")
  
  #paramFile<-"/home/wietse/Desktop/Werk/MakeRVICParams/RVIC_params/output_noRemap_86400/params/europe_all.rvic.prm.domain.20160503.nc"
  #outFile<-paste0(paramFile,"_lonlat.nc")
} else if (length(args)==3) {
  # default output file
  paramFile <- args[1]
  domainFile <- args[2]
  outFile <- args[3]
  #outFile<-paste0(paramFile,"_lonlat.nc")
}

print(paramFile)
print(outFile)
library(ncdf4)

## Get domain info
nc_domain<-nc_open(domainFile)
lons<-ncvar_get(nc_domain,"lon")
nlon<-length(lons)
lats<-ncvar_get(nc_domain,"lat")
nlat<-length(lats)
nc_close(nc_domain)

## Open param file
nc_param<-nc_open(paramFile)
timesteps<-ncvar_get(nc_param,"timesteps")
nTime<-length(timesteps)

## OUTLET INFO
outlet_lons<-ncvar_get(nc_param,"outlet_lon")
outlet_lats<-ncvar_get(nc_param,"outlet_lat")
nOutlets<-nc_param$dim$outlets$len

outlet_decomp_ind<-array(data = NA, dim = c(nlon,nlat))
outlet_mask<-array(data = NA, dim = c(nlon,nlat))
outlet_number<-array(data = NA, dim = c(nlon,nlat))
outlet_upstream_area<-array(data = NA, dim = c(nlon,nlat))
outlet_upstream_gridcells<-array(data = NA, dim = c(nlon,nlat))
outlet_x_ind<-array(data = NA, dim = c(nlon,nlat))
outlet_y_ind<-array(data = NA, dim = c(nlon,nlat))

v_outlet_decomp_ind<-ncvar_get(nc_param,"outlet_decomp_ind")
v_outlet_mask<-ncvar_get(nc_param,"outlet_mask")
v_outlet_number<-ncvar_get(nc_param,"outlet_number")
v_outlet_upstream_area<-ncvar_get(nc_param,"outlet_upstream_area")
v_outlet_upstream_gridcells<-ncvar_get(nc_param,"outlet_upstream_gridcells")
v_outlet_x_ind<-ncvar_get(nc_param,"outlet_x_ind")
v_outlet_y_ind<-ncvar_get(nc_param,"outlet_y_ind")

for (iOutlet in 1:nOutlets) {
  iLon<-outlet_lons[iOutlet]
  iLat<-outlet_lats[iOutlet]
  print(sprintf("iLon: %5.2f, iLat %5.2f, iOutlet %10.0f", iLon, iLat, iOutlet))
  outlet_decomp_ind[lons==iLon,lats==iLat]<-v_outlet_decomp_ind[iOutlet]
  outlet_mask[lons==iLon,lats==iLat]<-v_outlet_mask[iOutlet]
  outlet_number[lons==iLon,lats==iLat]<-v_outlet_number[iOutlet]
  outlet_upstream_area[lons==iLon,lats==iLat]<-v_outlet_upstream_area[iOutlet]
  outlet_upstream_gridcells[lons==iLon,lats==iLat]<-v_outlet_upstream_gridcells[iOutlet]
  outlet_x_ind[lons==iLon,lats==iLat]<-v_outlet_x_ind[iOutlet]
  outlet_y_ind[lons==iLon,lats==iLat]<-v_outlet_y_ind[iOutlet]
}

#image(outlet_upstream_gridcells)

## SOURCE INFO
source_lons<-ncvar_get(nc_param,"source_lon")
source_lats<-ncvar_get(nc_param,"source_lat")
nSources<-nc_param$dim$sources$len

source2outlet_ind<-array(data = NA, dim = c(nlon,nlat))
source_decomp_ind<-array(data = NA, dim = c(nlon,nlat))
source_time_offset<-array(data = NA, dim = c(nlon,nlat))
source_x_ind<-array(data = NA, dim = c(nlon,nlat))
source_y_ind<-array(data = NA, dim = c(nlon,nlat))
unit_hydrograph<-array(data = NA, dim = c(nlon,nlat,nTime))

v_source2outlet_ind<-ncvar_get(nc_param,"source2outlet_ind")
v_source_decomp_ind<-ncvar_get(nc_param,"source_decomp_ind")
v_source_time_offset<-ncvar_get(nc_param,"source_time_offset")
v_source_x_ind<-ncvar_get(nc_param,"source_x_ind")
v_source_y_ind<-ncvar_get(nc_param,"source_y_ind")
v_unit_hydrograph<-ncvar_get(nc_param,"unit_hydrograph")

for (iSource in 1:nSources) {
  iLon<-source_lons[iSource]
  iLat<-source_lats[iSource]
  source2outlet_ind[lons==iLon,lats==iLat]<-v_source2outlet_ind[iSource]
  source_decomp_ind[lons==iLon,lats==iLat]<-v_source_decomp_ind[iSource]
  source_time_offset[lons==iLon,lats==iLat]<-v_source_time_offset[iSource]
  source_x_ind[lons==iLon,lats==iLat]<-v_source_x_ind[iSource]
  source_y_ind[lons==iLon,lats==iLat]<-v_source_y_ind[iSource]
  for (iTime in 1:nTime) {
    unit_hydrograph[lons==iLon,lats==iLat, iTime]<-v_unit_hydrograph[iSource, iTime]
  }
}

## Close param file
nc_close(nc_param)

## Create new file
dimLon <- ncdim_def( "lon", "degrees_east", lons )
dimLat <- ncdim_def( "lat", "degrees_north", lats )
dimTime<- ncdim_def( "time", "days since 0000-01-01 00:00", timesteps )

var_outlet_decomp_ind<-ncvar_def(name = "outlet_decomp_ind", dim = list(dimLon,dimLat), units = "index", compression=4)
var_outlet_mask<-ncvar_def(name = "outlet_mask", dim = list(dimLon,dimLat), units = "index", compression=4)
var_outlet_number<-ncvar_def(name = "outlet_number", dim = list(dimLon,dimLat), units = "index", compression=4)
var_outlet_upstream_area<-ncvar_def(name = "outlet_upstream_area", dim = list(dimLon,dimLat), units = "index", compression=4)
var_outlet_upstream_gridcells<-ncvar_def(name = "outlet_upstream_gridcells", dim = list(dimLon,dimLat), units = "index", compression=4)
var_outlet_x_ind<-ncvar_def(name = "outlet_x_ind", dim = list(dimLon,dimLat), units = "index", compression=4)
var_outlet_y_ind<-ncvar_def(name = "outlet_y_ind", dim = list(dimLon,dimLat), units = "index", compression=4)

var_source2outlet_ind<-ncvar_def(name = "source2outlet_ind", dim = list(dimLon,dimLat), units = "index", compression=4)
var_source_decomp_ind<-ncvar_def(name = "source_decomp_ind", dim = list(dimLon,dimLat), units = "index", compression=4)
var_source_time_offset<-ncvar_def(name = "source_time_offset", dim = list(dimLon,dimLat), units = "index", compression=4)
var_source_x_ind<-ncvar_def(name = "source_x_ind", dim = list(dimLon,dimLat), units = "index", compression=4)
var_source_y_ind<-ncvar_def(name = "source_y_ind", dim = list(dimLon,dimLat), units = "index", compression=4)
var_unit_hydrograph<-ncvar_def(name = "unit_hydrograph", dim = list(dimLon,dimLat, dimTime), units = "index", compression=4)

# Create a netCDF file with this variable
ncnew <- nc_create( outFile,vars=list(var_outlet_decomp_ind, 
                                      var_outlet_mask,
                                      var_outlet_number,
                                      var_outlet_upstream_area,
                                      var_outlet_upstream_gridcells,
                                      var_outlet_x_ind,
                                      var_outlet_y_ind,
                                      var_source2outlet_ind,
                                      var_source_decomp_ind,
                                      var_source_time_offset,
                                      var_source_x_ind,
                                      var_source_y_ind,
                                      var_unit_hydrograph))

ncvar_put( ncnew, var_outlet_decomp_ind, outlet_decomp_ind )
ncvar_put( ncnew, var_outlet_mask, outlet_mask )
ncvar_put( ncnew, var_outlet_number, outlet_number )
ncvar_put( ncnew, var_outlet_upstream_area, outlet_upstream_area )
ncvar_put( ncnew, var_outlet_upstream_gridcells, outlet_upstream_gridcells )
ncvar_put( ncnew, var_outlet_x_ind, outlet_x_ind )
ncvar_put( ncnew, var_outlet_y_ind, outlet_y_ind )
ncvar_put( ncnew, var_outlet_decomp_ind, outlet_decomp_ind )

ncvar_put( ncnew, var_source2outlet_ind, source2outlet_ind )
ncvar_put( ncnew, var_source_decomp_ind, source_decomp_ind )
ncvar_put( ncnew, var_source_time_offset, source_time_offset )
ncvar_put( ncnew, var_source_x_ind, source_x_ind )
ncvar_put( ncnew, var_source_y_ind, source_y_ind )
ncvar_put( ncnew, var_unit_hydrograph, unit_hydrograph )

nc_close(ncnew)
