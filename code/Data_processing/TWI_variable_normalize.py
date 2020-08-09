# Normalize TWI
# srun -p milkun --mem 290G --time 2:00:00 --pty python3.5

import os
from osgeo import gdal
import ogr 
from osgeo import gdal_array
import gdal, ogr, osr
import numpy as np
import os.path

# Define function for array to raster

def array2raster(newRasterfn,rasterOrigin,pixelWidth,pixelHeight,array, nd):
	cols = array.shape[1]
	rows = array.shape[0]
	originX = rasterOrigin[0]
	originY = rasterOrigin[1]
	driver = gdal.GetDriverByName('GTiff')
	outRaster = driver.Create(newRasterfn, cols, rows, 1, gdal.GDT_Float32)
	outRaster.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
	outband = outRaster.GetRasterBand(1)
	outband.WriteArray(array)
	outband.SetNoDataValue(nd)
	outRasterSRS = osr.SpatialReference()
	outRasterSRS.ImportFromEPSG(4326)
	outRaster.SetProjection(outRasterSRS.ExportToWkt())
	outband.FlushCache()
	outRaster = None


def main(newRasterfn,rasterOrigin,pixelWidth,pixelHeight,array, nd):
    #reversed_arr = array[::-1] # reverse array so the tif looks like the array
    array2raster(newRasterfn,rasterOrigin,pixelWidth,pixelHeight,array, nd) # convert array to raster

# Set path for the raster files 

twi_var = "/TWI_resampled.tif"
twi_norm = "/TWI_norm.tif"

####""
# Get list of files
# r=root, d=directories, f = files

#for f in files:
#	print(f)
####
# Open the rasters

raster = gdal.Open(twi_var)
band = raster.GetRasterBand(1)
rasterArray = raster.ReadAsArray().astype('float32')
nodata = band.GetNoDataValue()
object_info = raster.GetGeoTransform()
rasterArray_mask = np.ma.masked_less_equal(rasterArray, rasterArray[1][1])
rasterArray = None
raster = None
sd_val = rasterArray_mask.std()
mean_val = rasterArray_mask.mean()
raster_norm = (rasterArray_mask - mean_val) / sd_val
rasterArray_mask = None
if __name__ == "__main__":
	rasterOrigin = (object_info[0], object_info[3])
	pixelWidth = object_info[1]
	pixelHeight = object_info[5]
	newRasterfn = twi_norm
	array = raster_norm
	nd = nodata

main(newRasterfn,rasterOrigin,pixelWidth,pixelHeight,array, nd)
##################
##################

