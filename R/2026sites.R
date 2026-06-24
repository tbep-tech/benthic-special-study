library(sf)
library(mapview)
library(leaflet)
library(mapedit)
library(here)
library(spsurvey)
library(dplyr)

data(tbsegdetail, package = 'tbeptools')

m <- leaflet() |> 
 addProviderTiles('Esri.WorldImagery') |> 
 addPolygons(data = tbsegdetail, weight =  0.5)

# https://www.fdotd7studies.com/projects/gandy-4th-to-westshore/final-project-documents/
# https://www.fdotd7studies.com/projects/wp-content/uploads/sites/7/pdf/441250-1-Gandy-Blvd-PDE-Preferred-Alternative-Concept-Plans.pdf

# draw extent of new span footprint
poly <- drawFeatures(m)
gandypolyfull <- poly |> st_make_valid()
save(gandypolyfull, file = here('data/gandypolyfull.RData'))

# remove portion near channel
load(file = here('data/gandypolyfull.RData'))
m <- leaflet() |> 
 addProviderTiles('Esri.WorldImagery') |> 
 addPolygons(data = gandypolyfull, weight =  0.5)

tocut <- drawFeatures(m)

gandypoly <- st_difference(gandypolyfull, tocut) |> 
  st_cast("POLYGON") |>
  st_make_valid() |>
  select(geometry)

save(gandypoly, file = here('data/gandypoly.RData'))

# create random points
load(file = here('data/gandypoly.RData'))

# get points using st_sample, randomly proportional to area

min_dist <- 400  # in CRS units (feet for EPSG:6443)

candidates <- gandypoly |> 
  st_transform(crs = 6443) |>
  st_sample(size = 500, type = "random") |>
  st_as_sf()

selected <- candidates[1, ]
for (i in 2:nrow(candidates)) {
  dists <- st_distance(candidates[i, ], selected)
  if (all(as.numeric(dists) > min_dist)) {
    selected <- rbind(selected, candidates[i, ])
  }
  if (nrow(selected) >= 15) break
}

gandypts <- selected |>
  mutate(
    siteID = row_number(),
    backup = sample(c(rep(TRUE, 5), rep(FALSE, 10)))
  ) |> 
  st_transform(crs = 4326)

leaflet(gandypts) |>
  addProviderTiles('Esri.WorldImagery') |>
  addPolygons(data = gandypoly, weight =  0.5) |>
  addCircleMarkers(
    color = ~ifelse(backup, "red", "blue"),
    radius = 4,
    stroke = FALSE,
    fillOpacity = 0.8,
    label = ~siteID
  )

tosv <- gandypts |>
  st_drop_geometry() |>
  select(siteID, backup) |>
  mutate(
    Y = st_coordinates(gandypts)[, 2],
    X = st_coordinates(gandypts)[, 1]
  ) |> 
  select(X, Y, backup, siteID)

write.csv(tosv, file = here('data/gandypts.csv'), row.names = FALSE)
