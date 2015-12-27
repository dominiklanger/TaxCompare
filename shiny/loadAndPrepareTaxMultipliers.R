

loadAndPrepareTaxMultipliers <- function(multiplierFilePath, gisData)  {
            
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
      
      taxMultipliers$canton <- "ZH"
      
      taxMultipliers$searchString <- sapply(strsplit(as.character(taxMultipliers$municipality), "\\."), function(x) {x[[1]][1]}) 
      
      taxMultipliers$zip <- lapply(1:nrow(taxMultipliers), 
                                   function(i) {
                                         gisSubset <- gisData[gisData$canton == taxMultipliers$canton[i], 1:3]
                                         searchString <- taxMultipliers$searchString[i]
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