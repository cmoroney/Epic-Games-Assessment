# Import libraries
library(tidyverse)

# Import data and clean column names
merged_df <- read_csv("./output/merged_data.csv") %>% 
  janitor::clean_names()


# Monthly installs - (100 ID's per month)
merged_df %>% 
  group_by(install_month) %>% 
  summarize(total_installs = n_distinct(user_id)) %>% 
  ggplot(aes(x = install_month, y = total_installs)) +
  geom_line() +
  theme_light()

# ------------------------------------------------------------------------
# DAU / WAU / MAU
# ------------------------------------------------------------------------

# Creating truncated dataset to omit dates without install data
trunc_df <- merged_df %>%
  filter(play_date > '2021-01-01',
         play_date <= '2023-12-31')

# MAU time series
# *** User Engagement chart in presentation
trunc_df %>% 
  group_by(play_month) %>%
  summarize(mau = n_distinct(user_id[matches_started>0])) %>% 
  ggplot(aes(x = play_month, y = mau)) +
  geom_line(col = "blue") +
  labs(x = "Play Month", y = "MAU", title = "Total Monthly Active Users (MAU)") +
  scale_x_date(limits = c(as.Date("2021-01-01"), as.Date("2023-12-01"))) +
  theme_light()

# Completion rate by month - dips in 10/22 and 11/22
# *** Match Completion Rate by Month in presentation
trunc_df %>%
  group_by(play_month) %>%
  summarize("total_match_starts" = sum(matches_started),
            "total_match_completions" = sum(matches_completed),
            "completion_rate" = sum(matches_completed) / sum(matches_started)) %>% 
  arrange(desc(play_month)) %>%
  ggplot(aes(x = play_month, y = completion_rate)) + 
  geom_line(col="blue") + 
  theme_light() +
  labs(x = "Play Month", y = "Completion Rate", title = "Match Completion Rate by Month") + 
  scale_y_continuous(limits = c(0.65, 1), labels = scales::percent)


# Top 5 countries by active users
top_countries_by_mau <- trunc_df %>% 
  group_by(country_code) %>% 
  summarize("active_users" = n_distinct(user_id[matches_started>0]),
            "perc_of_total_users" = sum(active_users),
            "total_match_starts" = sum(matches_started),
            "total_match_completions" = sum(matches_completed),
            "completion_rate" = sum(matches_completed) / sum(matches_started),
            "total_matches_won" = sum(matches_won),
            "win_rate" = sum(matches_won) / sum(matches_completed),
            "wins_per_mau" = sum(matches_won) / n_distinct(user_id[matches_started>0]),
            "matches_per_user" = sum(matches_completed) /  n_distinct(user_id[matches_started>0])
  ) %>%
  mutate("percent_of_actives" = active_users / sum(active_users)) %>%
  top_n(5, wt=active_users) %>%
  arrange(desc(active_users))

print(top_countries_by_mau)

# *** Monthly Active Users by Country graph in presentation
trunc_df %>%
  filter(country_code %in% top_countries_by_mau$country_code) %>%
  group_by(play_month, country_code) %>%
  summarize("active_users" = n_distinct(user_id[matches_started>0])) %>%
  ggplot(aes(x = play_month, y = active_users, col = country_code)) + 
  geom_line() +
  theme_light() +
  labs(x = "Play Month", y = "MAU", col = "Country Code", title = "Monthly Active Users by Country (top 5 countries)")

# Create a table with top countries by active users
unique_active = trunc_df %>% 
  filter(matches_started>0) %>% 
  summarize(total_users = n_distinct(user_id))

trunc_df %>% 
  group_by(country_code) %>% 
  summarize("active_users" = n_distinct(user_id[matches_started>0]),
            "total_users" = unique_active,
            "perc_of_total" = n_distinct(user_id[matches_started>0]) / unique_active) %>% 
  arrange(desc(active_users))


# ----------------------------------------
# Appendix - Additional code 
# ----------------------------------------
# Create calendar data frame spanning min and max of both data sets
min_date <- min(c(merged_df$play_date, merged_df$install_date))
max_date <- max(c(merged_df$play_date, merged_df$install_date))

cal_df <- seq.Date(from = min_date,
                   to = max_date,
                   by = "day")  %>%
  data.frame(cal_date = .)


# Daily installs
daily_installs <- merged_df %>% 
  group_by(install_date) %>% 
  summarize(total_installs = n_distinct(user_id)) 

daily_users <- merged_df %>%
  group_by(play_date) %>%
  summarize(total_users = n_distinct(user_id))

df <- cal_df %>% 
  left_join(daily_installs, by = c("cal_date" = "install_date")) %>%
  left_join(daily_users, by = c("cal_date" = "play_date"))

# Show gaps in data
df %>%
  pivot_longer(cols = c("total_users", "total_installs")) %>% 
  ggplot(aes(x = cal_date, y = value, col = name)) + 
  geom_line() + 
  ggtitle("Total User ID's by Date") + 
  labs(x = "Date", y = "", col = "Metric Name") +
  theme_light() + 
  labs("Users and Installs by Date - May/June 2022")

# Zoom in on missing data / spike - Users spike 6/22/22, installs spike 6/21/22
df %>% 
  filter(cal_date > '2022-05-25', cal_date < '2022-07-01') %>% 
  pivot_longer(cols=c("total_installs", "total_users")) %>%
  ggplot(aes(x = cal_date, y = value, col = name)) +
  geom_line() +
  theme_light() + 
  labs(x = "Date", 
       y = "", 
       title = "Users and Installs by Date - May/June 2022",
       col = "")

# Check user activity - users vs active users 
trunc_df %>% 
  group_by(play_month) %>%
  summarise(
    "Users" = n_distinct(user_id),
    "Active Users" = n_distinct(user_id[matches_started>0]),
    "Active Completion Users" = n_distinct(user_id[matches_started>0 & matches_completed>0])
  ) %>% 
  pivot_longer(cols=c("Users", "Active Users", "Active Completion Users")) %>% 
  ggplot(aes(x=play_month, y = value, col = name)) + 
  geom_line() +
  labs(x = "Play Month", 
       y = "", 
       title = "Unique User Count by Month",
       col = "") +
  theme_light()
