# Need rgdal, which recent Mac update (Big Sur) might have broken - check online
install.packages("rgdal")
library(rgdal)
install.packages("hdf5R")
library(rhdf5)

# Load in example dataset
testData<-h5read("202007170002_polar_pl_radar20b2_augzdr_lp.h5","/dataset1/data1/data")
str(testData)

# Turn matrix into long format, add angles and distances from radar to build polar coordinates
data.df<-data.frame(value=as.vector(testData),theta=rep(c(1:360),425),radius=rep(c(1:425),each=360))

# Trigonometry to calculate x and y (note that the scan is a single elevation, so treating it as flat for now)
data.df$x = data.df$radius*cos(data.df$theta)
data.df$y = data.df$radius*sin(data.df$theta)

# Where value is zero, assuming NoData
data.df$value[data.df$value==0]<-NA

# Quick plot - big dataset!
plot(data.df$x,data.df$y,cex=0.1)

# Make dataset smaller by removing points further than 50 units (about 5km, I think) from the radar
data.df.small<-subset(data.df,data.df$radius<50)

# Plot the smaller dataset
plot(data.df.small$x,data.df.small$y,cex=0.1)

# Apply the value offest to convert the integer values stored in the h5 dataset back to the radar variable
# The gain and offset are in the "what" part of the h5 data1 dataset
#   :gain = 0.1; // double
#   :offset = -32.0; // double
# I am not sure if I have applied them correctly here...
data.df.small$value<-data.df.small$value*0.1-32

# Visualising the new, smaller data with the values.
library(ggplot2)
sp<-ggplot(data.df.small, aes(x=x, y=y,color=value)) + geom_point() 
sp + scale_color_gradient(low="blue", high="red")
