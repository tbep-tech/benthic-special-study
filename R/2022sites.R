
library(tidyverse)
library(sf)

# tire reef
tirdat <- st_read('T:/05_GIS/EPCHC/AllSpecialProjects/SpecialStudy2020.shp') %>% 
  filter(grepl('^Tire', Station)) %>% 
  mutate(
    Location = 'Tire Reef'
  ) %>% 
  select(Location, Station, Lat_dd = Latitude, Lon_dd = Longitude)

# piney point
pipdat <- read_sheet('1eJ64uMX7WOrt2XrjxKV67W5Y_EiXDh_9gBFpaBXuQWo') %>% 
  mutate(
    Location = 'Piney Point'
  ) %>% 
  rename(Lat_dd = lat, Lon_dd = lng, Station = station) %>% 
  st_as_sf(coords = c('Lon_dd', 'Lat_dd'), crs = st_crs(pipdat), remove = F)

ss2022 <- bind_rows(tirdat, pipdat)

st_write(ss2022, 'T:/05_GIS/EPCHC/AllSpecialProjects/SpecialStudy2022.shp')
