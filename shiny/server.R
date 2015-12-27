
library(shiny)

library(knitr) # for Knitr

library(xlsx) # for loading Excel files

library(dplyr) # for data manipulations

# For plotting
library(ggplot2) 
library(ggmap)

# For map manipulations:
library(RgoogleMaps)
library(rgdal)
library(rgeos)

source("loadAndPrepareTaxMultipliers.R")
source("calculateTax.R")

dataDirectory <- "../data/"
taxScaleFilePath <- paste0(dataDirectory, "taxScales_cleaned.csv")
multiplierFilePath <- paste0(dataDirectory, "steuerfuesse_zh.xlsx")
gisFile <- paste0(dataDirectory, "GIS_information_CH.txt")
shapeDirectory <- paste0(dataDirectory, "PLZO_SHP_LV03")

taxScales <- read.csv(taxScaleFilePath)

gisData <- read.delim(gisFile, header=FALSE, fileEncoding = "UTF-8") %>%
      select(V2, V8, V3, V5, V10, V11)
names(gisData) <- c("zip", "municipality", "municipality2", "canton", "latitude", "longitude")

taxMultipliers <- loadAndPrepareTaxMultipliers(multiplierFilePath, gisData)

shapesSwitzerland <- readOGR(shapeDirectory, layer = "PLZO_PLZ")
relevantShapes <- shapesSwitzerland[shapesSwitzerland$PLZ %in% unlist(taxMultipliers$zip),]
relevantShapes <- spTransform(relevantShapes, CRS("+proj=longlat +datum=WGS84"))


shinyServer(function(input, output) {

  output$taxMap <- renderPlot({
        if (input$taxCategory == "Single")
              taxCategory <- "GT"
        else
              taxCategory <- "VT"        
        
        incomeTax <- calculateTax(relevantShapes$PLZ, input$income, "income", taxCategory, taxScales, taxMultipliers, gisData)
        wealthTax <- calculateTax(relevantShapes$PLZ, input$wealth, "wealth", taxCategory, taxScales, taxMultipliers, gisData)
        relevantShapes$tax <- incomeTax + wealthTax
        relevantShapes@data$id <- rownames(relevantShapes@data)
        
        # Convert to dataframe for plotting with ggplot - takes a while
        relevantShapes.df <- fortify(relevantShapes)
        
        # Merge tax data into shape dataframe. Hint: http://stackoverflow.com/questions/19791210/r-ggplot2-merge-with-shapefile-and-csv-data-to-fill-polygons
        relevantShapes.df <- inner_join(relevantShapes.df, relevantShapes@data, by="id")
        
        # Plot with ggplot
        centerOfMap <- geocode("47.436734,8.6513793", source = "google")
        googleMap <- get_map(c(lon=centerOfMap$lon, lat=centerOfMap$lat), zoom = 10, maptype = "terrain", source = "google")
        
        ggmap(googleMap) + 
              geom_polygon(aes(x = long, y = lat, group = group, fill = tax), data = relevantShapes.df, alpha = 0.6) +
              geom_polygon(aes(x = long, y = lat, group = group), data = relevantShapes.df, colour = "black", size = 0.3, alpha = 0) +
              scale_fill_gradient2(low = "gold", mid = "grey90", high = "red", midpoint = mean(relevantShapes.df$tax))

  })

})
