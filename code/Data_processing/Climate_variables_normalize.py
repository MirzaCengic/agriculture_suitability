#### Normalize variables 

# srun -p milkun --mem 16G --time 2:00:00 -w cn37 --pty python3.5

import os
from osgeo import gdal
import ogr 
from osgeo import gdal_array
import gdal, ogr, osr
import numpy as np

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

	
# Set path for the raster files of climate variables
# Logtransformed layer

lyr1 = "CHELSA_bio10_1.tif"
lyr2 = "CHELSA_bio10_4.tif"
lyr3 = "CHELSA_bio12_logtr.tif"
lyr4 = "CHELSA_bio10_15.tif"


####
path = "Data/Predictors_temp/"
# Get list of files
files = []
# r=root, d=directories, f = files
for r, d, f in os.walk(path):
	for file in f:
		if 'wc' in file:
			files.append(os.path.join(r, file))

####
# Open the rasters


for my_layer in files:
	print(my_layer)
	raster = gdal.Open(my_layer)
	band = raster.GetRasterBand(1)
	rasterArray = raster.ReadAsArray().astype('float64')
	nodata = band.GetNoDataValue()
	var_name = my_layer.replace("Data/Predictors_temp/", "")
	var_name_normalized = "Data/Predictors_intermediate/" + var_name.replace("_temp1.tif", "") + "_norm.tif"
	rasterArray_mask = np.ma.masked_less_equal(rasterArray, rasterArray[1][1])
	sd_val = rasterArray_mask.std()
	mean_val = rasterArray_mask.mean()
	raster_norm = (rasterArray_mask - mean_val) / sd_val
	object_info = raster.GetGeoTransform()
	if __name__ == "__main__":
		rasterOrigin = (object_info[0], object_info[3])
		pixelWidth = object_info[1]
		pixelHeight = object_info[5]
		newRasterfn = var_name_normalized
		array = raster_norm
		nd = nodata
	main(newRasterfn,rasterOrigin,pixelWidth,pixelHeight,array, nd)

###############################################