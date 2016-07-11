# first run: source activate tonic 
from tonic.models.vic.grid_params import soil, snow, veg, veg_class, Cols, Desc, calc_grid, grid_params, write_netcdf, read_netcdf
import numpy as np

soil_file   = ''
snow_file   = ''
veg_file    = ''
veglib_file = ''
domain_file = ''
out_file    = ''
lonlat      = ,,,

lon = np.arange(lonlat[0],lonlat[1]+0.000001,.5)
lat = np.arange(lonlat[2],lonlat[3]+0.000001,.5)
lon_array = np.zeros(len(lon)*len(lat))
lat_array = np.zeros(len(lon)*len(lat))

count=0
#print(len(lon_array))
for j in range(0, len(lat)):
  for i in range(0, len(lon)):
    lon_array[count] = lon[i]
    lat_array[count] = lat[j]
    count = count+1
    

root_zones = 3
months_per_year = 12

# Read the soil parameters
soil_dict = soil(soil_file, c=Cols(nlayers=root_zones))

# Read the snow parameters
snow_dict = snow(snow_file, soil_dict, c=Cols(snow_bands=25))

# Read the veg parameter file
veg_dict = veg(veg_file, soil_dict, vegparam_lai=True, max_roots=3)

# Read the veg library file
veg_lib = veg_class(veglib_file)

# Determine the grid shape
#target_grid, target_attrs = read_netcdf(domain_file)
#target_grid, target_attrs = calc_grid(soil_dict['lats'], soil_dict['lons'])
target_grid, target_attrs = calc_grid(lat_array, lon_array)

# Grid all the parameters
grid_dict = grid_params(soil_dict, target_grid,veg_dict=veg_dict, veglib_dict=veg_lib[0], snow_dict=snow_dict)

# Write a netCDF file with all the parameters
write_netcdf(out_file, target_attrs,
             target_grid=target_grid,
             soil_grid=grid_dict['soil_dict'],
             snow_grid=grid_dict['snow_dict'],
             veg_grid=grid_dict['veg_dict'])
