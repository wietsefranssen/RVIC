#http://www.hydro.washington.edu/Lettenmaier/Models/VIC/Documentation/Routing/FlowDirection.shtml
#http://pro.arcgis.com/en/pro-app/tool-reference/spatial-analyst/how-flow-accumulation-works.htm
#http://rvic.readthedocs.org/en/latest/user-guide/parameters/
rm (list = ls())

args = commandArgs(trailingOnly=TRUE)

if (length(args)!=2) {
  print("two arguments must be supplied (input file and output file).", call.=FALSE)
  print("Using defaults...")
  inFile = "./temp/ddm30_flowdir_cru_neva.asc_VIC.nc"
  # inFile = "/home/wietse/new/flowdirection_EU.nc"
  outFile = "./temp/output.nc"
} else if (length(args)==2) {
  # default output file
  inFile = args[1]
  outFile = args[2]
}

print(inFile)
print(outFile)
library(ncdf4)

lonDir<-function(direction) {
  change<-0
  if (direction == 1 || direction == 2 || direction == 128) change<- +1
  if (direction == 8 || direction == 16 || direction == 32) change<- -1
  # if (direction == 1 || direction == 2 || direction == 128) change<- -1
  # if (direction == 8 || direction == 16 || direction == 32) change<- +1
  return(change)
}

latDir<-function(direction) {
  change<-0
  # if (direction == 32 || direction == 64 || direction == 128) {change <- -1}
  # if (direction == 2 || direction == 4 || direction == 8) {change <- +1}
  if (direction == 32 || direction == 64 || direction == 128) {change <- +1}
  if (direction == 2 || direction == 4 || direction == 8) {change <- -1}
  return(change)
}

ncid<-nc_open(file = inFile)
flowDir<-ncvar_get(ncid,"flow_direction")
lons<-ncvar_get(ncid,"lon")
lats<-ncvar_get(ncid,"lat")
nlon<-ncid$dim$lon$len
nlat<-ncid$dim$lat$len
nc_close(ncid)

# print(flowDir)
# flowDir<-t(apply(flowDir,1,rev))
#flowDir_t2<-t(apply(flowDir_t,1,rev))
########flowDir_t2<-t(apply(flowDir_t,2,rev))
#flowDir_t<-apply(flowDir,1,rev) 
#flowDir_t<-apply(t(flowDir),1,rev)
#print(flowDir)

flowDir[flowDir==0]<-9990
flowDir[flowDir==1]<-9991
flowDir[flowDir==2]<-9992
flowDir[flowDir==3]<-9993
flowDir[flowDir==4]<-9994
flowDir[flowDir==5]<-9995
flowDir[flowDir==6]<-9996
flowDir[flowDir==7]<-9997
flowDir[flowDir==8]<-9998
flowDir[flowDir==9]<-9999

flowDir[flowDir==9990]<-0
flowDir[flowDir==9991]<-64
flowDir[flowDir==9992]<-128
flowDir[flowDir==9993]<-1
flowDir[flowDir==9994]<-2
flowDir[flowDir==9995]<-4
flowDir[flowDir==9996]<-8
flowDir[flowDir==9997]<-16
flowDir[flowDir==9998]<-32
flowDir[flowDir==9999]<-0

flowAcc<-array(data = NA, dim = c(nlon,nlat))
flowAcc[!is.na(flowDir)]<-0
aBasinID<-array(data = NA, dim = c(nlon,nlat))
aFlowDone<-array(data = NA, dim = c(nlon,nlat))

nBasin <- 0
iBasin <- 0
total<-0
iLon<-0

for (iLat in 1:nlat) {
  print(sprintf("iLat: %03i,%03i (%5.2f)", iLat, nlat, lats[iLat]))
  for (iLon in 1:nlon) {
    iLonTmp<-iLon
    iLatTmp<-iLat
    # aFlowDone[!is.na(aFlowDone)]<-NA
    
    if (!is.na(flowDir[iLonTmp,iLatTmp])) {
      # print(sprintf("iLon: %03i,%03i, iLat: %03i,%03i  (%5.2f, %5.2f), flowdir: %s", iLon, nlon,iLat, nlat, lons[iLon], lats[iLat],flowDir[iLon,iLat]))
      outletFound <- FALSE
      while (outletFound == FALSE) {
        iLonTmpPrev <-iLonTmp
        iLatTmpPrev <-iLatTmp 
        iLonDir <- lonDir(flowDir[iLonTmp,iLatTmp])
        iLatDir <- latDir(flowDir[iLonTmp,iLatTmp])
        # print(sprintf("Prev: iLonTmp: %03i,%03i, iLatTmp: %03i,%03i  (%5.2f, %5.2f), flowdir: %s, lon:%i lat:%i", iLonTmp, nlon,iLatTmp, nlat, lons[iLonTmp], lats[iLatTmp],flowDir[iLonTmp,iLatTmp], iLonDir, iLatDir))
        iLonTmp <- iLonTmp + iLonDir 
        iLatTmp <- iLatTmp + iLatDir
        # print(sprintf("    : iLonTmp: %03i,%03i, iLatTmp: %03i,%03i  (%5.2f, %5.2f), flowdir: %s, lon:%i lat:%i", iLonTmp, nlon,iLatTmp, nlat, lons[iLonTmp], lats[iLatTmp],flowDir[iLonTmp,iLatTmp], iLonDir, iLatDir))
        rm(iLonDir,iLatDir)
        
        # Check if outletFound (out-of-bounds, 0 or NA)
        if (iLonTmp <= 0 || iLonTmp > nlon || iLatTmp <= 0 || iLatTmp > nlat ) {
          outletFound<-TRUE
        } else if (is.na(flowDir[iLonTmp,iLatTmp])) {
          outletFound<-TRUE
        } else if (flowDir[iLonTmpPrev,iLatTmpPrev] == 0) {
          outletFound<-TRUE
        }
        
        if (!outletFound) { 
          flowAcc[iLonTmp,iLatTmp] <- flowAcc[iLonTmp,iLatTmp] + 1
        }
        
        # if (!outletFound) {
        #   if (is.na(aFlowDone[iLonTmp,iLatTmp])) {
        #     aFlowDone[iLonTmp,iLatTmp]<-1
        #   } else {
        #     outletFound <- TRUE
        #   }
        # }
        
        ##########
        if (outletFound) {
          if (is.na(aBasinID[iLonTmpPrev,iLatTmpPrev])) {
            nBasin <- nBasin + 1
            aBasinID[iLonTmpPrev,iLatTmpPrev] <- nBasin
            iBasin <- aBasinID[iLonTmpPrev,iLatTmpPrev]
          } else {
            iBasin <- aBasinID[iLonTmpPrev,iLatTmpPrev]
          }
        }
      }
      ##########
      iLonTmp<-iLon
      iLatTmp<-iLat
      if (!is.na(flowDir[iLonTmp,iLatTmp])) {
        outletReached <- FALSE
        while (outletReached == FALSE) {
          iLonTmp2 <- lonDir(flowDir[iLonTmp,iLatTmp])
          iLatTmp2 <- latDir(flowDir[iLonTmp,iLatTmp])
          iLonTmpPrev <-iLonTmp
          iLatTmpPrev <-iLatTmp
          iLonTmp <- iLonTmp + iLonTmp2
          iLatTmp <- iLatTmp + iLatTmp2
          rm(iLonTmp2,iLatTmp2)
          
          # Check if outletFound (out-of-bounds, 0 or NA)
          if (iLonTmp <= 0 || iLonTmp > nlon || iLatTmp <= 0 || iLatTmp > nlat ) {
            outletReached<-TRUE
          } else if (is.na(flowDir[iLonTmp,iLatTmp])) {
            outletReached<-TRUE
          } else if (flowDir[iLonTmpPrev,iLatTmpPrev] == 0) {
            outletReached<-TRUE
          }
          
          if (!outletReached) {
            aBasinID[iLonTmpPrev,iLatTmpPrev] <- iBasin
          }
          
          # if (!outletReached) {
          #   if (is.na(aFlowDone[iLonTmp,iLatTmp])) {
          #     aFlowDone[iLonTmp,iLatTmp]<-1
          #   } else {
          #     outletReached <- TRUE
          #   }
          # }
        }
      }
    }
  }
}

#image(flowDir)
#image(aBasinID)
#image(flowAcc)

###Flip ddm30 terug!!
# flowDir<-t(apply(flowDir,1,rev))
# aBasinID<-t(apply(aBasinID,1,rev))
# flowAcc<-t(apply(flowAcc,1,rev))



missValue<- -999999
flowAcc[is.na(flowAcc)]<-missValue
aBasinID[is.na(aBasinID)]<-missValue

##############
dimLon <- ncdim_def( name = "lon", units = "", vals = c(1:length(lons)), create_dimvar = FALSE )
dimLat <- ncdim_def( name = "lat", units = "", vals = c(1:length(lats)), create_dimvar = FALSE )

varLon <- ncvar_def(name = "lon", units = "degrees_east", dim = dimLon, longname="longitude", prec="float", missval = NULL)
varLat <- ncvar_def(name = "lat", units = "degrees_north", dim = dimLat, longname="latitude", prec="float", missval = NULL)

varBasinId <- ncvar_def(name = "Basin_ID", units = "id", dim = list(dimLon,dimLat), longname="Basin Id", prec="integer", missval = missValue)
#varFlowAcc <- ncvar_def(name = "flow_acc", units = "count", dim = list(dimLon,dimLat), longname="Flow accumulation", prec="integer", missval = missValue)
varFlowAcc <- ncvar_def(name = "Source_Area", units = "count", dim = list(dimLon,dimLat), longname="Flow accumulation", prec="integer", missval = missValue)

# Create a netCDF file with the variables
ncout <- nc_create( filename = outFile, vars = list(varLon, varLat, varFlowAcc, varBasinId) )

# Fill the netCDF variables
ncvar_put( ncout, varLon, lons )
ncvar_put( ncout, varLat, lats )
ncvar_put( ncout, varFlowAcc, flowAcc )
ncvar_put( ncout, varBasinId, aBasinID )

nc_close(ncout)

