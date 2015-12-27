## File: ui.R
## Author: Dominik Langer
## Created at: 2015-12-27
## Project: TaxCompare
## Description: UI part of a Shiny app calculating and plotting taxes for different municipalities.

library(shiny)

shinyUI(
      fluidPage(            
            # Application title
            titlePanel("Comparison of municipality tax in the Canton of Zurich, Switzerland"),
            
            p(HTML("This app plots the height of municipality tax for the different municipalities in the canton of Zurich.")),            
            
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
                        ),
                        helpText("Calculating the plot may take a couple of seconds. Please be patient.")
                  ),
                  # Show a plot of the tax height for each municipality:
                  mainPanel(
                        plotOutput("taxMap")
                  )
            )
      )
)
