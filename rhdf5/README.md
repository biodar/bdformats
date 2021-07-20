Going from hdf5 to PointClouds
================

## Load 24hr data

For this Rmd file, we will try 50 files out of some \~540. According to
\[@martin2007discrimination\], a typical dBZ is (17). There does not
seem to be a standard let a lone a gold standard value as elsewhere it
was something like 0-4dbZ.

``` r
library(data.table)
library(rhdf5)
```

    ## Warning: package 'rhdf5' was built under R version 4.0.3

``` r
library(bioRad)
```

    ## Welcome to bioRad version 0.5.2

    ## Docker daemon running, Docker functionality enabled

    ## No vol2bird Docker image found. Please run update_docker() to download.

``` r
library(magrittr)
p = "~/Documents/Research/BioDAR/Example_Met_Office_H5_Data_Share/"
n = 50
# keep the sample to 0 degrees?
files = list.files(p, full.names = TRUE, pattern="_polar_pl_radar20b0")
files = sample(files, n)

d = unlist(lapply(files, function(x)h5read(x, "dataset1/data1/data")))
a = unlist(lapply(files, function(x)mean(h5read(x,"/dataset1/how/elangles")))) %>% round
  
dt = data.frame(value=d,theta=rep(c(1:360),425),radius=rep(c(1:425)*600,each=360), a=rep(a, each=(360*425)))
dt = as.data.table(dt)

rl = unique(lapply(files[1:50], function(x) h5readAttributes(x,"/where")))
if(length(rl) != 1) stop("different radar dataset")

# get x,y,z
dt$x = dt$radius*sin(90-dt$a)*cos(dt$theta)
dt$y = dt$radius*sin(90-dt$a)*sin(dt$theta)
dt$z = (beam_height(dt$radius, dt$a, k = 4/3, lat = rl[[1]]$lat, re = 6378, rp = 6357) + rl[[1]]$height) %>% round

# continue Chris's comments/code
# Now calculate the change in latitude and longitude for each of those points
# https://stackoverflow.com/questions/2187657/calculate-second-point-knowing-the-starting-point-and-distance
delta_lon = dt$x/(111320*cos(rl[[1]]$lat))  # dx, dy in meters
delta_lat = dt$y/110540                       # result in degrees long/lat
# Calculate the lat and long of each point in the radar scan
dt$lat  = rl[[1]]$lat + delta_lat
dt$long = rl[[1]]$lon + delta_lon

# get gain & offset
go = lapply(files, function(x)h5readAttributes(x,"dataset1/data1/what"))

dt$gain = rep(unlist(lapply(go, function(x) x$gain)), 360*425)
dt$offset = rep(unlist(lapply(go, function(x) x$offset)), 360*425)

# add in the dates (time really)
l = gregexpr("_polar_pl_radar20", basename(files[1]))
dates = substr(basename(files), 1, l[[1]][1] - 1)
dates = as.POSIXct(dates, format = "%Y%m%d%H%M")
dt$date = rep(dates, each=360*425)

# clean up
dt = dt[dt$value != 0]

# calc Z/dbZ
dt$value = (dt$value * dt$gain) + dt$offset

dt$gain = NULL
dt$offset = NULL
# dt$theta = NULL
# dt$radius = NULL
# dt$a = NULL
rm(delta_lon, delta_lat, go)

# bio targets between 0 & 2
# dt = dt[dt$value > 0 & dt$value <= 2]
# plot(table(dt$value[dt$value]))
# summary of values
summary(dt$value)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##  -31.90   -9.30   -5.20   -1.93    0.40   80.30

## Understand .h5

`/dataset1/data1/data` has what is in `dataset1/data1/what` which in our
case is a 360x425 matrix explained here by Chris.

<div style="width:100%; background-color:#f00">

<table style="width:100%;">

<thead>

<tr>

<th>

</th>

<th>

</th>

<th colspan="5">

Angles from due north

</th>

</tr>

</thead>

<tbody>

<tr>

<td>

</td>

<td>

</td>

<td>

1

</td>

<td>

2

</td>

<td>

3

</td>

<td>

…

</td>

<td>

360

</td>

</tr>

<tr>

<td rowspan="5">

Distance <br>from radar

</td>

<td>

1

</td>

<td colspan="5" rowspan="5">

Values in the matrix give the values for the radar variable –
dataset1/data1/what tells you what the variable is under “quantity”.
dataset1/data1, dataset1/data2, etc, give the 10 different radar
variables.

</td>

</tr>

<tr>

<td>

2

</td>

</tr>

<tr>

<td>

3

</td>

</tr>

<tr>

<td>

…

</td>

</tr>

<tr>

<td>

425

</td>

</tr>

</tbody>

</table>

</div>

> If you convert the matrix to a long format with the distance (called
> “range”) and angle (“theta”) then use some trigonometry
> (<https://github.com/biodar/bdformats/commit/20502b63b6f252c26e1eddf4487b25379bc50a54>)
> then you can plot the coordinates (I haven’t incorporated the height):

``` r
library(rgdal)
```

    ## Loading required package: sp

    ## rgdal: version: 1.5-23, (SVN revision 1121)
    ## Geospatial Data Abstraction Library extensions to R successfully loaded
    ## Loaded GDAL runtime: GDAL 3.2.1, released 2020/12/29
    ## Path to GDAL shared files: /Library/Frameworks/R.framework/Versions/4.0/Resources/library/rgdal/gdal
    ## GDAL binary built with GEOS: TRUE 
    ## Loaded PROJ runtime: Rel. 7.2.1, January 1st, 2021, [PJ_VERSION: 721]
    ## Path to PROJ shared files: /Library/Frameworks/R.framework/Versions/4.0/Resources/library/rgdal/proj
    ## PROJ CDN enabled: FALSE
    ## Linking to sp version:1.4-5
    ## To mute warnings of possible GDAL/OSR exportToProj4() degradation,
    ## use options("rgdal_show_exportToProj4_warnings"="none") before loading rgdal.
    ## Overwritten PROJ_LIB was /Library/Frameworks/R.framework/Versions/4.0/Resources/library/rgdal/proj

``` r
library(rhdf5)

f <- "https://github.com/biodar/bdformats/releases/download/1/sample.h5"
if(!file.exists(basename(f))) {
  download.file(f, destfile = basename(f))
}
# Load in example dataset
testData<-h5read(basename(f),"/dataset1/data1/data")
str(testData)
```

    ##  int [1:425, 1:360] 0 438 373 291 275 250 253 283 309 229 ...

``` r
# Turn matrix into long format, add angles and distances from radar to build polar coordinates
data.df<-data.frame(value=as.vector(testData),theta=rep(c(1:360),425),radius=rep(c(1:425),each=360))

# Extract lat and long of the radar from the /where data in the h5 file
RadarLoc<-h5readAttributes(basename(f),"/where")
# Trigonometry to calculate x and y coordinates of each point in the scan
# note that the scan is a single elevation, so treating it as flat for now)
data.df$x = data.df$radius*cos(data.df$theta)
data.df$y = data.df$radius*sin(data.df$theta)

# Now calculate the change in latitude and longitude for each of those points
# https://stackoverflow.com/questions/2187657/calculate-second-point-knowing-the-starting-point-and-distance
delta_longitude = data.df$x/(111320*cos(RadarLoc$lat))  # dx, dy in meters
delta_latitude = data.df$y/110540                       # result in degrees long/lat

# Calculate the lat and long of each point in the radar scan
data.df$lat  = RadarLoc$lat+delta_latitude
data.df$long = RadarLoc$lon+delta_longitude

# Where value is zero, assuming NoData
data.df$value[data.df$value==0]<-NA

# Quick plot - big dataset!
plot(data.df$x,data.df$y,cex=0.1)
```

![](README_files/figure-gfm/chris-code-1.png)<!-- -->

``` r
# Quick plot - big dataset!
plot(data.df$long,data.df$lat,cex=0.1)
```

![](README_files/figure-gfm/chris-code-2.png)<!-- -->

``` r
# Apply the value offest to convert the integer values stored in the h5 dataset back to the radar variable
# The gain and offset are in the "what" part of the h5 data1 dataset
#   :gain = 0.1; // double
#   :offset = -32.0; // double
# I am not sure if I have applied them correctly here...
data.df$value<-(data.df$value*0.1)-32

# Make dataset smaller by removing points further than 5km from the radar
data.df.small<-subset(data.df,data.df$radius<50)

# Plot the smaller dataset
plot(data.df.small$x,data.df.small$y,cex=0.1)
```

![](README_files/figure-gfm/chris-code-3.png)<!-- -->

``` r
# Mapping the dataset with static ggplot2 maps
# Based on https://bookdown.org/yann_ryan/r-for-newspaper-data/mapping-with-r-geocode-and-map-the-british-librarys-newspaper-collection.html
library(ggplot2)
worldmap = map_data('world')
ggplot() + 
  geom_polygon(data = worldmap, aes(x = long, 
                                    y = lat, 
                                    group = group), 
               fill = 'gray90', 
               color = 'black') + 
  coord_fixed(ratio = 1.3, 
              xlim = c(-10,3), 
              ylim = c(50, 59)) + 
  theme_void() +
  geom_point(data=data.df, 
             aes(x=long, 
                 y=lat,
                 color=value)) +
  scale_color_gradient(low="blue", high="red")
```

![](README_files/figure-gfm/chris-code-4.png)<!-- -->

``` r
# devtools::install_github("ATFutures/geoplumber")
# install.packages(sf)
# data.df.sample <- data.df[sample(nrow(data.df), 5e3),]
# data.sf <- sf::st_as_sf(data.df.sample, coords=c("long", "lat"))
# geoplumber::gp_map(data.sf)
# lf <- geoplumber::gp_map(data.sf, browse_map = FALSE)
# htmltools::includeHTML(lf)


# Something a bit fancier based on Mapbox
# Based on Robin's work https://geocompr.robinlovelace.net/adv-map.html
# library(mapdeck)
#set_token(TOKEN)
# ms = mapdeck_style("light")
# mapdeck(style = ms, pitch = 45, location = c(0, 52), zoom = 4) %>%
# add_pointcloud(
#   data = data.df, lat = "lat", lon = "long",
#   radius = 5,
#   fill_colour = "value",
#   palette = "viridis",
#   na_colour = "#808080FF",
#   legend = TRUE,
#   legend_options = NULL,
#   legend_format = NULL,
#   update_view = TRUE,
#   focus_layer = FALSE,
#   digits = 6,
#   transitions = NULL,
#   brush_radius = NULL
# )
```

## hdf5r

``` r
library(rhdf5)
df = h5ls(basename(f))
class(df)
```

    ## [1] "data.frame"

``` r
head(df)
```

    ##              group     name       otype  dclass       dim
    ## 0                / dataset1   H5I_GROUP                  
    ## 1        /dataset1    data1   H5I_GROUP                  
    ## 2  /dataset1/data1     data H5I_DATASET INTEGER 425 x 360
    ## 3  /dataset1/data1     what   H5I_GROUP                  
    ## 4        /dataset1   data10   H5I_GROUP                  
    ## 5 /dataset1/data10     data H5I_DATASET INTEGER   1 x 360

``` r
d = h5read(basename(f), "dataset1/data1/data")
class(d)
```

    ## [1] "matrix" "array"

``` r
nrow(d)
```

    ## [1] 425

``` r
length(d)
```

    ## [1] 153000

## Calculating Z for each data point

from Chris and Maryna’s emails:

425 are the different distances, and I think they might be 100m \[600m\]
intervals (i.e. the furthest is 42.5km\[100m\*425\] from the radar).

1 – The z is contained in the filename (b0 = lowest elevation, b1 = next
elevation, etc). However, I don’t know the scanning angle associated
with each of the elevations. Maryna? Obviously it will be another piece
of trigonometry to calculate the heights at each distance, because the
scan is always increasing in height away from the radar. Indeed, the z
also needs to be included in the x,y calculations because the elevated
beam means that the range actually travels a shorter distance relative
to the ground:

![](README_files/z-value.png)

2 – The “PPI” scan has a conical structure and scans the volume of air
within that cone. What we get is a general scan of each region (voxel)
within that volume. The radar then reports 10 different variables for
each voxel. The radar doesn’t pick up individual objects.

![](README_files/voxel-to-shape.png) 3 - bioRad::beam\_height height of
radar voxels should be calculated applying 4/3 refraction model you can
find beam height calculation in beam\_height function
<https://github.com/adokter/bioRad/blob/master/R/beam.R>
beam\_height(range, elev, k = 4/3, lat = 51, re = 6378, rp = 6357 This
is how to call the function with our latitude The description can be
found here <http://adriaandokter.com/bioRad/reference/beam_height.html>

## bioRad

The package fails to read the Example data we despite the above reads
using the same underlying package `rhdf5` package.

``` r
library(bioRad)
# from bioRad vignette
my_pvol <- read_pvolfile(f)
# error is at rhdf5::H5Fis_hdf5  and reported upstream
# despite
rhdf5::H5Fis_hdf5(f)
#> TRUE
```
