# load in packages
library(tidyverse)

# load in data
perf_raw <- read_csv("./web_performance.csv") %>% 
  janitor::clean_names()

# create dataframe with formatted fields
perf <- perf_raw %>% 
  mutate(date = as.Date(date, format = '%m/%d/%Y'),
         variant = as.factor(variant),
         metric = as.factor(metric))

# view data at a glance
head(perf)

summary(perf)

perf_raw %>% 
  unique() %>% 
  nrow() %>%
  print()

perf_raw %>% 
  group_by(variant, metric) %>% 
  summarize("min_date" = min(date),
            "max_date" = max(date))

# create result dataframes
results <- perf %>% 
  pivot_wider(names_from = "metric",
              values_from = "value") %>% 
  group_by(variant) %>% 
  summarize("total_visits" = sum(visits),
            "total_downloads" = sum(downloads),
            "conversion_rate" = sum(downloads) / sum(visits))

a_results <- results %>% filter(variant == "A")
b_results <- results %>% filter(variant == "B")

# calculate uplift
uplift <- (b_results$conversion_rate - a_results$conversion_rate) / a_results$conversion_rate
print(uplift)

# Website used for calculation: https://abtestguide.com/calc/
