library(sf)
library(mapview)
library(leaflet)
library(mapedit)
library(here)
library(spsurvey)
library(dplyr)
library(lwgeom)

# gandy ------------------------------------------------------------------

data(tbsegdetail, package = 'tbeptools')

m <- leaflet() |> 
 addProviderTiles('Esri.WorldImagery') |> 
 addPolygons(data = tbsegdetail, weight =  0.5)

# https://www.fdotd7studies.com/projects/gandy-4th-to-westshore/final-project-documents/
# https://www.fdotd7studies.com/projects/wp-content/uploads/sites/7/pdf/441250-1-Gandy-Blvd-PDE-Preferred-Alternative-Concept-Plans.pdf

gandyline <- drawFeatures(m)

save(gandyline, file = here('data/gandyline.RData'))

load(file = here('data/gandyline.RData'))

gandypts <- st_line_sample(st_transform(gandyline, crs = 6443), n = 10, type = "regular") |>
  st_as_sf() |>
  st_cast("POINT") |>
  mutate(
    backup = FALSE
  ) |> 
  st_transform(crs = 4326)

gandyptsback <- st_line_sample(st_transform(gandyline, crs = 6443), n = 5, type = "regular") |>
  st_as_sf() |>
  st_cast("POINT") |>
  mutate(
    backup = TRUE
  ) |> 
  st_transform(crs = 4326)

gandypts <- rbind(gandypts, gandyptsback)

leaflet(gandypts) |>
  addProviderTiles('CartoDB.Positron') |>
  addPolylines(data = gandyline, weight =  0.5) |>
  addCircleMarkers(
    color = ~ifelse(backup, "red", "blue"),
    radius = 4,
    stroke = FALSE,
    fillOpacity = 0.8
  )

# hillsborough -----------------------------------------------------------

data(tbsegdetail, package = 'tbeptools')

m <- leaflet() |> 
 addProviderTiles('CartoDB.Positron') |> 
 addPolygons(data = tbsegdetail, weight =  0.5)

hillline <- drawFeatures(m)
save(hillline, file = here('data/hillline.RData'))

load(file = here('data/hillline.RData'))

hillpts <- st_line_sample(st_transform(hillline, crs = 6443), n = 10, type = "regular") |>
  st_as_sf() |>
  st_cast("POINT") |>
  mutate(
    backup = FALSE
  ) |> 
  st_transform(crs = 4326)

hillptsback <- st_line_sample(st_transform(hillline, crs = 6443), n = 5, type = "regular") |>
  st_as_sf() |>
  st_cast("POINT") |>
  mutate(
    backup = TRUE
  ) |> 
  st_transform(crs = 4326)

hillpts <- rbind(hillpts, hillptsback)

leaflet(hillpts) |>
  addProviderTiles('CartoDB.Positron') |>
  addPolylines(data = hillline, weight =  0.5) |>
  addCircleMarkers(
    color = ~ifelse(backup, "red", "blue"),
    radius = 4,
    stroke = FALSE,
    fillOpacity = 0.8
  )

# save both as csv -------------------------------------------------------

gandypts <- gandypts |>
  mutate(
    site = 'Gandy'
  )
hillpts <- hillpts |>
  mutate(
    site = 'Hillsborough'
  )

pts <- rbind(gandypts, hillpts) |> 
  mutate(
    siteID = row_number()
  )

tosv <- pts |>
  st_drop_geometry() |>
  select(site, siteID, backup) |>
  mutate(
    Y = st_coordinates(pts)[, 2],
    X = st_coordinates(pts)[, 1]
  ) |> 
  select(X, Y, backup, site, siteID)

write.csv(tosv, file = here('data/pts2026.csv'), row.names = FALSE)

# verify
pts <- read.csv(here('data/pts2026.csv')) |>
  st_as_sf(coords = c("X", "Y"), crs = 4326)

leaflet(pts) |>
  addProviderTiles('CartoDB.Positron') |>
  addCircleMarkers(
    color = ~ifelse(backup, "red", "blue"),
    radius = 4,
    stroke = FALSE,
    fillOpacity = 0.8, 
    label = ~paste0(site, " - ", siteID)
  )