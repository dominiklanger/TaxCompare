## File: loadAndPrepareTaxMultipliers.R
## Author: Dominik Langer
## Created at: 2015-12-27
## Project: TaxCompare
## Description: Function that loads tax multipliers ("Steuerfüsse") for each municipality.

loadAndPrepareTaxMultipliers <- function(multiplierFilePath, gisData)  {
      
      # Read the tax multipliers from file:      
      taxMultipliers <- read.xlsx(multiplierFilePath, 
                                  sheetIndex = 4,
                                  colIndex = c(4, 18),
                                  header = FALSE,
                                  encoding = "UTF-8",
                                  startRow = 10,
                                  endRow = 178
      ) %>%
            rename(municipality = X4, multiplier = X18) %>%
            mutate(multiplier = multiplier / 100)
      
      # Enrich with additional data
      taxMultipliers$canton <- "ZH" # Currently, we have data only for canton of Zurich (ZH)
      
      # Let's provide a column with simplified/shortened municipality names that can be used for look-up purposes 
      # Example: "Affoltern a.A." will be simplified/shortened to "Affoltern a", so it can be matched against 
      # "Affoltern am Albis" in the gisData when looking up the corresponding zip code.
      taxMultipliers$searchString <- sapply(strsplit(as.character(taxMultipliers$municipality), "\\."), 
                                            function(x) {x[[1]][1]}
                                          ) 
      # Now let's look up the zip code for each municipality:
      taxMultipliers$zip <- lapply(1:nrow(taxMultipliers), 
                                   function(i) {
                                         gisSubset <- gisData[gisData$canton == taxMultipliers$canton[i], 1:3]
                                         searchString <- taxMultipliers$searchString[i]
                                         
                                         # For some municipalities we need to perform several different lookup attempts
                                         # due to differences in naming in the different tables/columns:
                                         zipCodes <- gisSubset$zip[which(grepl(searchString, gisSubset$municipality))]
                                         
                                         if (length(zipCodes) == 0) {
                                               searchString <- strsplit(taxMultipliers$searchString[i], " ")[[1]][1]                                          
                                               zipCodes <- gisSubset$zip[which(grepl(searchString, gisSubset$municipality))]
                                         }
                                         if (length(zipCodes) == 0) {
                                               zipCodes <- gisSubset$zip[which(grepl(searchString, gisSubset$municipality2))]                                          
                                         }
                                         if (length(zipCodes) == 0) {
                                               print(paste("Couldn't find zip code for", taxMultipliers$municipality[i]))
                                         }
                                         return(zipCodes)
                                   }
                              ) 
      
      return(taxMultipliers) 
}