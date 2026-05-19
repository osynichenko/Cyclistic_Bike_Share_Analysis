library (tidyverse)
library (lubridate)
library (dplyr)
library (janitor)
library (tidyr)
library (data.table)
library (readr)
library (psych)
library (hrbrthemes)
library (ggplot2)
library (lifecycle)
library (rlang)
library (vctrs)
library (languageserver)



setwd("/Documents/Cyclistic_Bike_Analysis")



Jan_2025 <- read.csv("202501-divvy-tripdata.csv")
Feb_2025 <- read.csv("202502-divvy-tripdata.csv")
Mar_2025 <- read.csv("202503-divvy-tripdata.csv")
Apr_2025 <- read.csv("202504-divvy-tripdata.csv")
May_2025 <- read.csv("202505-divvy-tripdata.csv")
Jun_2025 <- read.csv("202506-divvy-tripdata.csv")
Jul_2025 <- read.csv("202507-divvy-tripdata.csv")
Aug_2025 <- read.csv("202508-divvy-tripdata.csv")
Sep_2025 <- read.csv("202509-divvy-tripdata.csv")
Oct_2025 <- read.csv("202510-divvy-tripdata.csv")
Nov_2025 <- read.csv("202511-divvy-tripdata.csv")
Dec_2025 <- read.csv("202512-divvy-tripdata.csv")




colnames(Jan_2025)
colnames(Feb_2025)
colnames(Mar_2025)
colnames(Apr_2025)
colnames(May_2025)
colnames(Jun_2025)
colnames(Jul_2025)
colnames(Aug_2025)
colnames(Sep_2025)
colnames(Oct_2025)
colnames(Nov_2025)
colnames(Dec_2025)



sum(nrow(Jan_2025) + nrow(Feb_2025) + nrow(Mar_2025) + nrow(Apr_2025) + nrow(May_2025) + nrow(Jun_2025) + nrow(Jul_2025) + nrow(Aug_2025) + nrow(Sep_2025) + nrow(Oct_2025)+ nrow(Nov_2025) + nrow(Dec_2025))




tour_combined <- rbind(Jan_2025, Feb_2025, Mar_2025, Apr_2025, May_2025, Jun_2025, Jul_2025, Aug_2025, Sep_2025, Oct_2025, Nov_2025, Dec_2025)



write.csv(tour_combined,file = "tour_combined_raw_data.csv",row.names = FALSE)




colnames(tour_combined)

str(tour_combined)

View(head(tour_combined))

View(tail(tour_combined))

dim(tour_combined)

summary(tour_combined)

colSums(is.na(tour_combined))




min(tour_combined$started_at)

max(tour_combined$started_at)

sum(as.Date(tour_combined$started_at) < as.Date("2025-01-01"))

tour_combined <- tour_combined %>% filter(as.Date(started_at) >= as.Date("2025-01-01"))

dim(tour_combined)



colSums(is.na(tour_combined))



clean_tour <- distinct(tour_combined)

dim(clean_tour)



clean_tour <- drop_na(clean_tour)

dim(clean_tour)



clean_tour<- clean_tour %>% filter(started_at < ended_at)

dim(clean_tour)



clean_tour <- rename(clean_tour, customer_type = member_casual, bike_type = rideable_type)

colnames(clean_tour)



clean_tour$date <- as.Date(clean_tour$started_at)
clean_tour$month <- format(as.Date(clean_tour$date), "%b_%y")
clean_tour$week_day <- format(as.Date(clean_tour$date), "%A")
clean_tour$year <- format(clean_tour$date, "%Y")



clean_tour$time <- as.POSIXct(clean_tour$started_at, format = "%Y-%m-%d %H:%M:%S")
clean_tour$time <- format(clean_tour$time, format = "%H:%M")



clean_tour$tour_length <- difftime(clean_tour$ended_at, clean_tour$started_at, units = "mins")



clean_tour <- rename(clean_tour, pickup_time = time)
clean_tour <- clean_tour %>% mutate(hour = as.integer(format(as.POSIXct(pickup_time, format = "%H:%M"), "%H")))
clean_tour <- clean_tour %>% mutate(pickup_hour = as.integer(format(as.POSIXct(pickup_time, format = "%H:%M"), "%H")))
colnames(clean_tour)



clean_tour <- clean_tour %>% select(bike_type, started_at, ended_at, start_station_name, end_station_name, customer_type, date, month, week_day, year, pickup_time, tour_length, pickup_hour)



clean_tour <- clean_tour[!clean_tour$tour_length>1440,]
dim(clean_tour)
clean_tour <- clean_tour[!clean_tour$tour_length<1,]
dim(clean_tour)



colSums(is.na(clean_tour))
View(filter(clean_tour, clean_tour$tour_length > 1440 | clean_tour$tour_length < 1))



write.csv(clean_tour,file = "tour_combined_cleaned.csv",row.names = FALSE)



tour_combined_cleaned <- read_csv("tour_combined_cleaned.csv")

str(tour_combined_cleaned)



tour_combined_cleaned$month <- ordered(tour_combined_cleaned$month,levels=c("Jan_25","Feb_25","Mar_25","Apr_25","May_25","Jun_25","Jul_25","Aug_25","Sep_26","Oct_25","Nov_25","Dec_25"))

tour_combined_cleaned$week_day <- ordered(tour_combined_cleaned$week_day, levels=c("Sunday", "Monday", "Tuesday","Wednesday", "Thursday","Friday", "Saturday"))



View(describe(tour_combined_cleaned$tour_length, fast=TRUE))



tour_combined_cleaned %>% group_by(customer_type, bike_type) %>% summarise(count = n(), avg_duration = mean(tour_length)) %>% mutate(pct = count / sum(count) * 100)



tour_combined_cleaned %>% group_by(customer_type, bike_type) %>% summarise(count = n(), .groups = "drop") %>% ggplot(aes(x = bike_type, y = count, fill = customer_type)) + geom_col(position = "dodge") + scale_fill_manual(values = c("casual" = "#E8593C", "member" = "#1D9E75")) + scale_y_continuous(labels = scales::comma) + labs(title = "Tours count by bike type", x = "Bike type", y = "Tours count", fill = "Customer type") + theme_minimal()



tour_combined_cleaned %>% group_by(customer_type, bike_type) %>% summarise(count = n(), .groups = "drop") %>% group_by(customer_type) %>% mutate(pct = count / sum(count) * 100) %>% ggplot(aes(x = customer_type, y = pct, fill = bike_type)) + geom_col(position = "dodge") + scale_fill_manual(values = c("classic_bike" = "#3B8BD4", "electric_bike" = "#EF9F27")) + scale_y_continuous(labels = function(x) paste0(round(x), "%")) + labs(title = "Distribution of bicycle types by customer type", x = "Customer type", y = "Percentage of trips", fill = "Bike type") + theme_minimal()




tour_combined_cleaned %>% filter(customer_type == "casual") %>% count(start_station_name, sort = TRUE) %>% head(10)



ggplot(tour_combined_cleaned, aes(x = week_day, fill = customer_type)) + geom_bar(position = "dodge") + scale_fill_manual(values = c("casual" = "#E8593C", "member" = "#1D9E75")) + scale_y_continuous(labels = scales::comma) + labs(title = "Number of tours by day of the week", x = "Day of the week", y = "Number of tours", fill = "Client type") + theme_minimal()




tour_combined_cleaned %>% group_by(month, customer_type) %>% summarise(avg_duration = mean(as.numeric(tour_length)), .groups = "drop") %>% ggplot(aes(x = month, y = avg_duration, fill = customer_type)) + geom_col(position = "dodge") + scale_fill_manual(values = c("casual" = "#E8593C", "member" = "#1D9E75")) + labs(title = "Average tour duration by month", x = "Month", y = "Average duration (min)", fill = "Client type") + theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1))



tour_combined_cleaned %>% mutate(hour = as.integer(substr(pickup_time, 1, 2))) %>% group_by(customer_type, hour) %>% summarise(count = n(), .groups = "drop") %>% ggplot(aes(x = hour, y = count, color = customer_type)) + geom_line(linewidth = 1.2) + scale_color_manual(values = c("casual" = "#E8593C", "member" = "#1D9E75")) + scale_x_continuous(breaks = 0:23) + scale_y_continuous(labels = scales::comma) + labs(title = "Tours by hour of the day", x = "Hour", y = "Number of tours", color = "Client type") + theme_minimal()



View(table(tour_combined_cleaned$customer_type))




View(setNames(aggregate(tour_length ~ customer_type, tour_combined_cleaned, sum), c("customer_type", "total_tour_len(mins)")))



View(tour_combined_cleaned %>% group_by(customer_type) %>% summarise(min_length_mins = min(tour_length), max_length_mins = max(tour_length), median_length_mins = median(tour_length), mean_length_mins = mean(tour_length)))



View(tour_combined_cleaned %>% group_by(week_day) %>% summarise(Avg_length = mean(tour_length), number_of_ride = n()))



View(tour_combined_cleaned %>% group_by(month) %>% summarise(Avg_length = mean(tour_length), number_of_ride = n()))



View(aggregate(tour_combined_cleaned$tour_length ~ tour_combined_cleaned$customer_type + tour_combined_cleaned$week_day, FUN = mean))



View(aggregate(tour_combined_cleaned$tour_length ~ tour_combined_cleaned$customer_type + tour_combined_cleaned$month, FUN = mean))



View(tour_combined_cleaned %>% group_by(customer_type, week_day) %>% summarise(number_of_ride = n(), avgerage_duration = mean(tour_length), median_duration = median(tour_length), max_duration = max(tour_length)))



View(tour_combined_cleaned %>% group_by(customer_type, month) %>% summarise(number_of_tours = n(), average_duration = mean(tour_length), median_duration = median(tour_length), max_duration = max(tour_length)))

