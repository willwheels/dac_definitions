library(rvest)
library(tidyverse)
#library(lubridate)



asdwa_dac_page <- read_html("https://www.asdwa.org/environmental-justice/")

## I tried to remember how to do this looking at css, but couldn't choose the right selector
## html_nodes(asdwa_dac_page, "table") shows two tables but I couldn't grab them
## I found the xpath this way: https://www.r-bloggers.com/2015/01/using-rvest-to-scrape-an-html-table/
##


## pull the big table that I'm looking for
main_table <- asdwa_dac_page %>%
  html_nodes(xpath = '//*[@id="table_1"]') %>%
  html_table()

main_table <- main_table[[1]]


## get the underlying hrefs to the data downloads
hrefs <- asdwa_dac_page %>%
  html_nodes(xpath = '//*[@id="table_1"]') %>%
  html_nodes("tr") %>%   ## returns 56 rows = column names + 55 rows
  html_nodes("a") %>%  ## returns 129???
  html_attr("href")  ## returns 129??? state may have IUP, SRF, and EJ links

all_rows <- asdwa_dac_page %>%
  html_nodes(xpath = '//*[@id="table_1"]') %>%
  html_nodes("tr")

all_rows_and_columns <- map(all_rows, ~ .x %>% html_nodes("td"))

all_rows_and_columns <- all_rows_and_columns[2:length(all_rows_and_columns)] ## drop header row

all_rows_and_columns_a_nodes <- map(all_rows_and_columns, ~ .x %>% html_node("a"))

all_rows_and_columns_hrefs <- map_dfc(all_rows_and_columns_a_nodes, ~ as.vector(.x %>% html_attr("href")))

colnames(all_rows_and_columns_hrefs) <- c("state2", "text_def", "def_source_link",
                                          "srf_link", "ej_link", "last_date")

all_rows_and_columns_hrefs <- as_tibble(t(all_rows_and_columns_hrefs))

## IDK why as_tibble drops the names
colnames(all_rows_and_columns_hrefs) <- c("state2", "text_def", "def_source_link",
                                          "srf_link", "ej_link", "last_date")

all_rows_and_columns_hrefs <- all_rows_and_columns_hrefs %>%
  select(-state2, -text_def, -last_date)

all_dac_web_data <- cbind(main_table, all_rows_and_columns_hrefs)

openxlsx::write.xlsx(all_dac_web_data, file = here::here("scraped_asdwa_data.xlsx"))
