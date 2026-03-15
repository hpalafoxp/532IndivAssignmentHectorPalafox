library(shiny)

ui <- fluidPage(
  titlePanel("Blank Shiny App"),
  p("Your app is live.")
)

server <- function(input, output, session) {
}

shinyApp(ui = ui, server = server)