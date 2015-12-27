## File: server.R
## Author: Dominik Langer
## Created at: 2015-12-27
## Project: TaxCompare
## Description: Server part of a Shiny app calculating and plotting taxes for different municipalities.

# Load packages:
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

# Load functions:
source("loadAndPrepareTaxMultipliers.R")
source("calculateTax.R")

# Set paths for data files:
dataDirectory <- "../data/"
taxScaleFilePath <- paste0(dataDirectory, "taxScales_cleaned.csv")
multiplierFilePath <- paste0(dataDirectory, "steuerfuesse_zh.xlsx")
gisFile <- paste0(dataDirectory, "GIS_information_CH.txt")
shapeDirectory <- paste0(dataDirectory, "PLZO_SHP_LV03")

# Load and prepare data:
taxScales <- read.csv(taxScaleFilePath)

gisData <- read.delim(gisFile, header=FALSE, fileEncoding = "UTF-8") %>%
      select(V2, V8, V3, V5, V10, V11)
names(gisData) <- c("zip", "municipality", "municipality2", "canton", "latitude", "longitude")

taxMultipliers <- loadAndPrepareTaxMultipliers(multiplierFilePath, gisData)

shapesSwitzerland <- readOGR(shapeDirectory, layer = "PLZO_PLZ")
relevantShapes <- shapesSwitzerland[shapesSwitzerland$PLZ %in% unlist(taxMultipliers$zip),]
relevantShapes <- spTransform(relevantShapes, CRS("+proj=longlat +datum=WGS84"))


# Actual shiny server functionality:
shinyServer(function(input, output) {

  output$taxMap <- renderPlot({
        # Map names of tax categories to those used in the data files:
        if (input$taxCategory == "Single")
              taxCategory <- "GT"
        else
              taxCategory <- "VT"        
        
        # Calculate tax for each zip code:
        incomeTax <- calculateTax(relevantShapes$PLZ, input$income, "income", taxCategory, taxScales, taxMultipliers, gisData)
        wealthTax <- calculateTax(relevantShapes$PLZ, input$wealth, "wealth", taxCategory, taxScales, taxMultipliers, gisData)        
        relevantShapes$tax <- incomeTax + wealthTax
        
        # To allow joining of shape data and tax data, we need row IDs in the shape data:
        relevantShapes@data$id <- rownames(relevantShapes@data)
        
        # Convert to dataframe for plotting with ggplot - takes a while
        relevantShapes.df <- fortify(relevantShapes)
        
        # Merge tax data into shape dataframe:
        relevantShapes.df <- inner_join(relevantShapes.df, relevantShapes@data, by="id")
        
        # Plot with ggplot:
        centerOfMap <- geocode("47.436734,8.6513793", source = "google")
        googleMap <- get_map(c(lon=centerOfMap$lon, lat=centerOfMap$lat), zoom = 10, maptype = "terrain", source = "google")
        
        finalMap <- ggmap(googleMap) + 
              geom_polygon(aes(x = long, y = lat, group = group, fill = tax), data = relevantShapes.df, alpha = 0.6) +
              geom_polygon(aes(x = long, y = lat, group = group), data = relevantShapes.df, colour = "black", size = 0.3, alpha = 0) +
              scale_fill_gradient2(low = "gold", mid = "grey90", high = "red", midpoint = mean(relevantShapes.df$tax))
        
        finalMap

  })

})
