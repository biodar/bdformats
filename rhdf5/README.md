Going from hdf5 to ?
================

``` r
# library(tidyverse)
# library(bioRad)
# 
# f = "~/Documents/Research/BioDAR/Example_Met_Office_H5_Data_Share/202007170002_polar_pl_radar20b2_augzdr_lp.h5"
# f %>%
#   read_pvolfile() %>%
#   get_scan(3) %>%
#   project_as_ppi() %>%
#   plot(param = "VRADH") # VRADH = radial velocity in m/s
# 
# pvol = read_pvolfile(f)
```

## hdf5r

``` r
f = "~/Documents/Research/BioDAR/Example_Met_Office_H5_Data_Share/202007170002_polar_pl_radar20b2_augzdr_lp.h5"

library(rhdf5)
```

    ## Warning: package 'rhdf5' was built under R version 4.0.3

``` r
df = h5ls(f)
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
d = h5read(f, "dataset1/data1/data")
class(d)
```

    ## [1] "matrix" "array"

``` r
nrow(d)
```

    ## [1] 425

``` r
d[1, ]
```

    ##   [1] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    ##  [38] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    ##  [75] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    ## [112] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    ## [149] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    ## [186] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    ## [223] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    ## [260] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    ## [297] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    ## [334] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
