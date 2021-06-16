# Need rgdal, which recent Mac update (Big Sur) might have broken - check online
#install.packages("rgdal")
library(rgdal)
#install.packages("hdf5R")
library(rhdf5)
#install.packages("googledrive")
library(googledrive)
#install.packages("bioRad")
library(bioRad)

# Find radar data shared by Maryna
RadarFiles<-drive_find(q = "name contains '20200717'")

# Just find the lowest elevation scans (b0)
RadarFilesb0<-RadarFiles[grep("20b0",RadarFiles$name),]
# Download the 101 b0 (zero elevation) files (commented to avoid a 120MB download if you don't need it)
  # for(x in 1:nrow(RadarFilesb0)){drive_download(RadarFilesb0[x,],overwrite = TRUE)}
# Find the names
LocalRadarFiles<-list.files(pattern="polar_pl")

# Load in example dataset (number 37 gives a midday scan)
testData<-h5read(LocalRadarFiles[37],"/dataset1/data1/data")
str(testData)

# Turn matrix into long format, add angles and distances from radar to build polar coordinates
data.df<-data.frame(value=as.vector(testData),theta=rep(c(1:360),425),radius=rep(c(1:425)*600,each=360))

# Extract lat and long of the radar from the /where data in the h5 file
RadarLoc<-h5readAttributes(LocalRadarFiles[37],"/where")

# Extract beam height from meta-data
BeamElevation<-mean(h5read(LocalRadarFiles[37],"/dataset1/how/elangles"))

# Trigonometry to convert x and y coordinates of each point in the scan, then use the beam_heigh() function
# from bioRad to calculate the beam height accounting for refraction
# Source for x,y: https://keisan.casio.com/exec/system/1359534351
data.df$x = data.df$radius*sin(90-BeamElevation)*cos(data.df$theta)
data.df$y = data.df$radius*sin(90-BeamElevation)*sin(data.df$theta)
data.df$z = beam_height(data.df$radius, BeamElevation, k = 4/3, lat = RadarLoc$lat, re = 6378, rp = 6357)+RadarLoc$height

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
#par(mfrow=c(1,2))
#plot(data.df$x,data.df$y,cex=0.1)
#plot(data.df$long,data.df$lat,cex=0.1)

# Apply the value offset to convert the integer values stored in the h5 dataset back to the radar variable
# The gain and offset are in the "what" part of the h5 data1 dataset
data1GainOffset<-h5readAttributes(LocalRadarFiles[37],"dataset1/data1/what")
data.df$value<-(data.df$value*data1GainOffset$gain)+data1GainOffset$offset

# Make dataset smaller by removing points further than 5km from the radar
data.df.small<-subset(data.df,data.df$radius<50000)

# Plot the smaller dataset
par(mfrow=c(1,2))
plot(data.df.small$x,data.df.small$y,cex=0.1)
plot(data.df.small$long,data.df.small$lat,cex=0.1)



# Mapping the dataset with static ggplot2 maps
# Based on https://bookdown.org/yann_ryan/r-for-newspaper-data/mapping-with-r-geocode-and-map-the-british-librarys-newspaper-collection.html
library(ggplot2)
par(mfrow=c(1,2))
worldmap = map_data('world')
ggplot() + 
  geom_polygon(data = worldmap, aes(x = long,y = lat,group = group),fill = 'gray90',color = 'black') + 
  coord_fixed(ratio = 1.3,xlim = c(-10,3),ylim = c(50, 59)) + 
  theme_void() +
  geom_point(data=data.df.small,aes(x=long,y=lat,color=value)) +
  scale_color_gradient(low="blue", high="red")

ggplot() + 
  geom_polygon(data = worldmap, aes(x = long,y = lat,group = group),fill = 'gray90',color = 'black') + 
  coord_fixed(ratio = 1.3,xlim = c(-1,2),ylim = c(50, 52)) + 
  theme_void() +
  geom_point(data=data.df.small,aes(x=long,y=lat,color=value)) +
  scale_color_gradient(low="blue", high="red")


# Something a bit fancier based on Mapbox, which just shows the density of scanned points (not the value)
# Based on Robin's work https://geocompr.robinlovelace.net/adv-map.html
library(mapdeck)
set_token(TOKEN)
ms = mapdeck_style("light")
mapdeck(style = ms, pitch = 45, location = c(0, 52), zoom = 4) %>%
  add_grid(data = data.df.small, lat = "lat", lon = "long", cell_size = 1000,
           elevation_scale = 50, layer_id = "grid_layer",
           colour_range = viridisLite::plasma(6))

# And trying point clouds with point value
ms = mapdeck_style("light")
mapdeck(style = ms, pitch = 45, location = c(0, 52), zoom = 4) %>%
add_pointcloud(
  data = data.df.small, lat = "lat", lon = "long",elevation = "z",
  radius = 2,
  fill_colour = "value",
  palette = "viridis",
  na_colour = "#808080FF",
  legend = TRUE,
  legend_options = NULL,
  legend_format = NULL,
  update_view = TRUE,
  focus_layer = FALSE,
  digits = 6,
  transitions = NULL,
  brush_radius = NULL
)
