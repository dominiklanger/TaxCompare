


calculateTax <- function(zipCodes, amount, taxType, taxCategory, scales, multipliers, zipsCantons) {
      selectedYear = 2014
      
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
                   baseTax <- 0
                   for(i in 1:nrow(relevantScales)) {
                         if (amount >= relevantScales$threshold[i]) {
                               baseTax <- relevantScales$baseTax[i] + 
                                     (amount - relevantScales$threshold[i]) * relevantScales$slope[i]
                         }
                   }
                   
                   multiplier <- 0
                   for(i in 1:nrow(multipliers)) {
                         if (zipCode %in% multipliers$zip[[i]]) {
                               multiplier <- multipliers$multiplier[i]
                               break
                         } 
                   } 
                   
                   (multiplier) * baseTax
             }
      )
}