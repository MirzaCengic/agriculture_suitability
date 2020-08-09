

reclassify_vals_gdal <- function (x, y, size, outpath, outfile, 
                                  vals_included, vals_excluded,
                                  category, number_of_cores = 1) 
{
  # Argument checks
  stopifnot(!missing(outfile), !missing(category))
  if (inherits(x, "Raster")) {
    x <- x@file@name
    y <- y@file@name
  }
  x_info <- rgdal::GDALinfo(x)
  if (missing(size)) {
    size <- x_info["res.x"] * 1000
  }
  print(size)
  tiles_x <- GSIF::getSpatialTiles(x_info, block.x = size, 
                                   return.SpatialPolygons = FALSE)
  if (missing(outpath)) {
    outpath <- fs::path_temp("Mosaic_tempdir")
  }
  fs::dir_create(outpath)
  if (number_of_cores > 1) {
    cat(paste0("Running in parallel with ", number_of_cores, 
               " cores."), "\n")
  }
  cl <- parallel::makeCluster(number_of_cores)
  doParallel::registerDoParallel(cl)
  
  # DEL
  # i = 1
  #
  
  # Do stuff in parallel
  foreach::foreach(i = 1:nrow(tiles_x)) %dopar% {
    x_load <- rgdal::readGDAL(x, offset = unlist(tiles_x[i, c("offset.y", "offset.x")]),
                              region.dim = unlist(tiles_x[i, c("region.dim.y", "region.dim.x")]),
                              output.dim = unlist(tiles_x[i, c("region.dim.y", "region.dim.x")]), silent = TRUE)
    y_load <- rgdal::readGDAL(y, offset = unlist(tiles_x[i, c("offset.y", "offset.x")]),
                              region.dim = unlist(tiles_x[i, c("region.dim.y", "region.dim.x")]),
                              output.dim = unlist(tiles_x[i, c("region.dim.y", "region.dim.x")]), silent = TRUE)
    x_ras <- raster::raster(x_load)
    y_ras <- raster::raster(y_load)
    #### Get values
    vals_x <- raster::getValues(x_ras)
    vals_y <- raster::getValues(y_ras)
    # Reclassify x
    vals_x[vals_x %in% vals_included] <- 0
    vals_x[vals_x %in% vals_excluded] <- 1
    x_rast <- raster::setValues(x_ras, vals_x)
    # Reclassify y
    vals_y[vals_y %in% vals_included] <- 0
    vals_y[vals_y %in% vals_excluded] <- 1
    y_rast <- raster::setValues(y_ras, vals_y)
    ####
    sum_raster <- x_rast + y_rast
    vals_sum <- raster::getValues(sum_raster)
    vals_sum[vals_sum %in% 1:2] <- NA
    sum_raster <- raster::setValues(sum_raster, vals_sum)
    
    outmosaic <- paste0(outpath, "/", "tmpmosaic_", i, ".tif")
    raster::writeRaster(sum_raster, outmosaic, format = "GTiff", 
                        overwrite = TRUE, options = "COMPRESS=LZW")
  }
  # return(sum_raster)
  parallel::stopCluster(cl)
  
  out_folder_path <- paste0(outpath, "/*.tif")
  raster_rcl <- gdalR::GDAL_mosaic_tile(outfile, folder_path = out_folder_path,
                                        large_tif = TRUE, return_raster = TRUE)
  if (file.exists(outfile)) {
    fs::dir_delete(outpath)
  }
  else {
    stop("Error: output file has not been created.")
  }
  return(raster_rcl)
  
}

