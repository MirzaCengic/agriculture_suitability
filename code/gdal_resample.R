##########################################
####  GDAL resample
##########################################
#### | Project name: Agriculture modeling
#### | Creator: Mirza Cengic
#### | Contact: mirzaceng@gmail.com
##########################################

# Modified function for gdal resample, used to aggregate merged mosaics to a coarser resolution

GDAL_resample2 <- function(infile, outfile, target_resolution, target_extent, method, large_tif = FALSE, return_raster = FALSE)
{
  
  if (!method %in% c("near", "bilinear", "cubic", "cubicspline", "lanczos",
                     "average", "mode", "max", "min", "med", "q1", "q3")) {
    stop("Resampling method not available.")
  }
  
  # If input is raster, extract the file path
  if (inherits(infile, "Raster"))
  {
    infile <- infile@file@name
  }
  
  resample_command <- paste0("gdalwarp -multi -of vrt -tr ", " ", target_resolution, " ", target_resolution, " -r ", method, " -te ", target_extent, " ",
                             infile, " ", gsub(tools::file_ext(outfile), "vrt", outfile))
  
  if (large_tif == TRUE)
  {
    VRT2TIF <- paste0("gdal_translate -co compress=LZW -co BIGTIFF=YES", " ", gsub(tools::file_ext(outfile), "vrt", outfile),
                      " ", gsub(tools::file_ext(outfile), "tif", outfile))
  } else {
    VRT2TIF <- paste0("gdal_translate -co compress=LZW", " ", gsub(tools::file_ext(outfile), "vrt", outfile),
                      " ", gsub(tools::file_ext(outfile), "tif", outfile))
  }
  
  system(resample_command)
  system(VRT2TIF)
  # Remove vrt
  unlink(gsub(tools::file_ext(outfile), "vrt", outfile))
  
  if (isTRUE(return_raster))
  {
    outfile <- raster::raster(outfile)
    return(outfile)
  }
}

