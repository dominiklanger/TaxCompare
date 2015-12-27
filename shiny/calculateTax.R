## File: calculateTax.R
## Author: Dominik Langer
## Created at: 2015-12-27
## Project: TaxCompare
## Description: Function that calculates the tax applicable in different municipalities (specified by
## zip code) for a given income, property and tax category

calculateTax <- function(zipCodes, amount, taxType, taxCategory, scales, multipliers, zipsCantons) {
      selectedYear = 2014 # For the moment, let's stick with data for 2014
      
      # Calculate and return applicable tax for each provided zip code:
      sapply(zipCodes, 
             function(zipCode) {
                   # Look-up canton from GIS file for filtering below
                   canton <- zipsCantons$canton[zipsCantons$zip == zipCode]
                   canton <- canton[!duplicated(canton)]
                   if (length(canton) > 1)
                         canton <- canton[1]
                   
                   # Scales relevant for this canton:
                   relevantScales <- filter(scales, year == selectedYear & 
                                                  type == taxType & 
                                                  canton == canton & 
                                                  category == taxCategory
                   )
                   
                   # Determine the base tax
                   baseTax <- 0
                   for(i in 1:nrow(relevantScales)) {
                         if (amount >= relevantScales$threshold[i]) {
                               baseTax <- relevantScales$baseTax[i] + 
                                     (amount - relevantScales$threshold[i]) * relevantScales$slope[i]
                         }
                   }
                   
                   # Find the multiplier to be applied:
                   multiplier <- 0
                   for(i in 1:nrow(multipliers)) {
                         if (zipCode %in% multipliers$zip[[i]]) {
                               multiplier <- multipliers$multiplier[i]
                               break
                         } 
                   } 
                   
                   # Calculate the municipality tax:
                   return ((multiplier) * baseTax)
             }
      )
}