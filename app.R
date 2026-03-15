library(shiny)
library(ggplot2)
library(dplyr)

df <- read.csv("data/data.csv", stringsAsFactors = FALSE)


df <- df |>
   mutate(
      Degree_Level = as.character(Degree_Level),
      Region = as.character(Region),
      Top_Industry = as.character(Top_Industry),
      Field_of_Study = as.character(Field_of_Study),
   )

degree_choices <- df |>
   filter(!is.na(Degree_Level), Degree_Level != "") |>
   distinct(Degree_Level) |>
   arrange(Degree_Level) |>
   pull(Degree_Level)

region_choices <- df |>
   filter(!is.na(Region), Region != "") |>
   distinct(Region) |>
   arrange(Region) |>
   pull(Region)


ui <- fluidPage(
   titlePanel("Graduate Skills Employability Dashboard"),
   
   sidebarLayout(
      sidebarPanel(
         checkboxGroupInput(
            inputId = "degree",
            label = "Degree",
            choices = degree_choices,
            selected = degree_choices
         ),
         
         checkboxGroupInput(
            inputId = "region",
            label = "Region",
            choices = region_choices,
            selected = region_choices
         )
      ),
      
      mainPanel(
         
         h3("Top Industries"),
         plotOutput("industries_plot", height = "400px"),
         
         br(),
         
         h3("Yearly Salary by Field of Study"),
         plotOutput("salary_plot", height = "450px")
      )
   )
)


server <- function(input, output, session) {
   
   filtered_data <- reactive({
      data <- df
      
      if (
         is.null(input$degree) || length(input$degree) == 0 ||
         is.null(input$region) || length(input$region) == 0
      ) {
         return(slice(data, 0))
      }
      
      data |>
         filter(
            Degree_Level %in% input$degree,
            Region %in% input$region
         )
   })
   
   output$industries_plot <- renderPlot({
      plot_data <- filtered_data() |> 
         filter(
            !is.na(Top_Industry),
            Top_Industry != "",
            !is.na(Average_Starting_Salary_USD)
         ) |> 
         group_by(Top_Industry) |> 
         summarise(
            avg_salary = mean(Average_Starting_Salary_USD, na.rm = TRUE),
         ) |> 
         ungroup() |> 
         arrange(desc(avg_salary)) |> 
         slice_head(n = 10)
      
      plot_data |> 
         ggplot() +
         aes(
            x = reorder(Top_Industry, avg_salary),
            y = avg_salary) +
         geom_col() +
         coord_flip() +
         labs(
            x = "Industry",
            y = "Average Yearly Starting Salary (USD)"
         ) +
         scale_y_continuous(labels = scales::label_dollar()) +
         theme_minimal()
   })
   
   output$salary_plot <- renderPlot({
      plot_data <- filtered_data() |> 
         filter(
            !is.na(Graduation_Year),
            !is.na(Field_of_Study),
            Field_of_Study != "",
            !is.na(Average_Starting_Salary_USD)
         ) |> 
         group_by(Graduation_Year, Field_of_Study) |> 
         summarise(
            avg_salary = mean(Average_Starting_Salary_USD, na.rm = TRUE),
         ) |> 
         ungroup() |> 
         arrange(Graduation_Year)
      
      
      plot_data |>
         ggplot() +
         aes(
            x = Graduation_Year,
            y = avg_salary,
            color = Field_of_Study,
            group = Field_of_Study
         ) +
         geom_line() +
         geom_point() +
         labs(
            x = "Graduation Year",
            y = "Average Yearly Starting Salary (USD)",
            color = "Field of Study"
         ) +
         scale_x_continuous(labels = scales::label_number(accuracy = 1)) + 
         scale_y_continuous(labels = scales::label_dollar()) + 
         theme_minimal()
   })
}

shinyApp(ui = ui, server = server)