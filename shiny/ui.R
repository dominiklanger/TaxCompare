
library(shiny)

shinyUI(
      fluidPage(            
            # Application title
            titlePanel("Tax comparison of municipalities in the Canton of Zurich, Switzerland"),
            
            # Sidebar with a slider input for number of bins
            sidebarLayout(                  
                  sidebarPanel(
                        helpText("Please enter your taxable income and wealth in Swiss Francs (CHF) and select your tax category."),
                        numericInput("income", "Taxable income in CHF:", 
                              value = 100000,
                              min = 0, 
                              max = 10000000
                        ),
                        numericInput("wealth", "Taxable wealth in CHF:", 
                              value = 300000,
                              min = 0, 
                              max = 100000000
                        ),
                        selectInput("taxCategory", 
                              label = "Tax category",
                              choices = c("Single", "Married or single parent"),
                              selected = "Single"
                        )
                  ),
                  # Show a plot of the tax height for each municipality:
                  mainPanel(
                        plotOutput("taxMap")
                  )
            )
      )
)
