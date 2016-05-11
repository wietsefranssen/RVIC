# first run: source activate tonic 
from tonic.models.vic.grid_params import soil, snow, veg, veg_class, Cols, Desc, calc_grid, grid_params, write_netcdf, read_netcdf
import numpy as np

soil_file   = ''
snow_file   = ''
veg_file    = ''
veglib_file = ''
domain_file = ''
out_file    = ''

n_veg_classes = 11
root_zones = 3
months_per_year = 12

# Read the soil parameters
soil_dict = soil(soil_file, c=Cols(nlayers=root_zones))

# Read the snow parameters
snow_dict = snow(snow_file, soil_dict, c=Cols(snow_bands=25))

# Read the veg parameter file
veg_dict = veg(veg_file, soil_dict, lai_index=True, veg_classes=n_veg_classes)

# Read the veg library file
veg_lib = veg_class(veglib_file, skiprows=2)

# Determine the grid shape
target_grid, target_attrs = read_netcdf(domain_file)

# Grid all the parameters
grid_dict = grid_params(soil_dict, target_grid, version='5.0.dev',
                        veg_dict=veg_dict, veglib_dict=veg_lib, snow_dict=snow_dict)

# Write a netCDF file with all the parameters
write_netcdf(out_file, target_attrs,
             target_grid=target_grid,
             soil_grid=grid_dict['soil_dict'],
             snow_grid=grid_dict['snow_dict'],
             veglib_dict=veg_lib,
             veg_grid=grid_dict['veg_dict'],
             version='5.0.dev')
