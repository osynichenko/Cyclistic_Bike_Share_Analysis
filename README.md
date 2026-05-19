## Cyclistic Bike-Share Analysis
### Google Data Analytics Capstone Project

![R](https://img.shields.io/badge/R-4.x-276DC3?style=flat&logo=r&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-Public-E97627?style=flat&logo=tableau&logoColor=white)
![Data](https://img.shields.io/badge/Dataset-5.4M%20rows-2E86AB?style=flat)
![Status](https://img.shields.io/badge/Status-Completed-1D9E75?style=flat)

---

## Project Overview

This project is a capstone case study completed as part of the **Google Data Analytics Professional Certificate** on Coursera. The analysis explores how **casual riders** and **annual members** use Cyclistic bike-share services differently — with the goal of informing a marketing strategy to convert casual riders into annual members.

**Business Question:**
> *How do annual members and casual riders use Cyclistic bikes differently?*

---

## Company Background

**Cyclistic** is a fictional bike-share company based in Chicago operating a fleet of **5,800+ bicycles** across **600+ docking stations**. The company offers three pricing tiers:
- Single-ride passes
- Full-day passes
- Annual memberships

Cyclistic's finance team has determined that **annual members are significantly more profitable** than casual riders. The Director of Marketing, Lily Moreno, wants to maximize annual memberships by converting existing casual riders rather than acquiring new customers from scratch.

---

##  Dataset

| Parameter | Details |
|-----------|---------|
| **Source** | [Divvy Trip Data](https://divvy-tripdata.s3.amazonaws.com/index.html) by Motivate International Inc. |
| **License** | [Divvy Data License Agreement](https://divvybikes.com/data-license-agreement) |
| **Period** | January 2025 – December 2025 (12 months) |
| **Raw size** | 1.12 GB / 5,552,994 rows |
| **After cleaning** | 5,399,796 rows |
| **Columns** | 13 original → 13 selected for analysis |

>  **Privacy Note:** All personally identifiable information has been removed from the dataset. It is not possible to connect rides to individual users or credit card data.

---

## Tools & Technologies

| Tool | Purpose |
|------|---------|
| **RStudio Desktop (macOS)** | Data import, cleaning, transformation, analysis, visualization |
| **R packages** | `tidyverse`, `lubridate`, `dplyr`, `ggplot2`, `janitor`, `psych`, `readr` |
| **GitHub** | Version control and portfolio hosting |

> Excel and Google Sheets were not viable due to the 1.12 GB dataset size.

---

##  Data Processing Pipeline

```
Raw CSV files (12 months)
        ↓
   [1] Import & Validate column names
        ↓
   [2] Combine into single dataframe (rbind)
        ↓
   [3] Remove out-of-range dates (53 rows Dec 2024)
        ↓
   [4] Remove duplicates (distinct)
        ↓
   [5] Remove NA values (drop_na) → removed 5,535 rows
        ↓
   [6] Remove invalid rides: started_at > ended_at → removed 29 rows
        ↓
   [7] Rename columns for clarity
        ↓
   [8] Additional columns were created (date, month, day of week, hour, tour duration)
        ↓
   [9] Filter outliers: rides < 1 min (147,372) and > 1440 min (209)
        ↓
   [10] Save clean CSV → Analysis & Visualization
```

---

## Feature Engineering

New columns created during processing:

| Column | Type | Description |
|--------|------|-------------|
| `date` | Date | Extracted from `started_at` |
| `month` | chr | Format `%b_%y` (e.g. `Jan_25`) |
| `week_day` | chr | Day name (Monday–Sunday) |
| `year` | chr | 4-digit year |
| `pickup_time` | chr | Time of ride start in `HH:MM` format |
| `pickup_hour` | int | Hour extracted for hourly analysis |
| `tour_length` | difftime | Ride duration in minutes |

---

## Analysis & Key Findings

### 1. Customer Split
| Customer Type | Rides | Share |
|--------------|-------|-------|
| Member | 3,484,147 | **64.5%** |
| Casual | 1,915,649 | **35.5%** |

---

### 2. Ride Duration — Casual vs Member

| Metric | Casual | Member |
|--------|--------|--------|
| Mean duration | **19.87 min** | 12.18 min |
| Median duration | 11.89 min | 8.74 min |
| Max duration | 1,439.98 min | 1,439.83 min |

>  Casual riders take rides **~63% longer** on average — consistent with leisure and sightseeing behavior.

---

### 3. Usage by Day of Week

| Day | Casual rides | Member rides |
|-----|-------------|-------------|
| Sunday | 316,929 | 374,532 |
| Monday | 219,224 | 493,317 |
| Tuesday | 216,885 | 552,511 |
| Wednesday | 212,732 | 540,206 |
| Thursday | 247,875 | 565,172 |
| Friday | 306,453 | 518,541 |
| **Saturday** | **395,551** | 439,868 |

>  **Members peak mid-week** (commuters). **Casual riders peak on weekends** (leisure/tourism).

---

### 4. Seasonal Trends

| Month | Casual rides | Member rides |
|-------|-------------|-------------|
| Jan_25 | 23,405 | 112,331 |
| Apr_25 | 105,256 | 257,919 |
| Jun_25 | 278,675 | 379,517 |
| **Aug_25** | **323,523** | **443,125** |
| Oct_25 | 214,373 | 414,088 |
| Dec_25 | 27,074 | 109,364 |

>  Casual ridership fluctuates **14x** between January and August. Member ridership fluctuates only **4x** — confirming year-round commuting behavior.

---

### 5. Bike Type Preference

| Customer | Classic bike | Electric bike | Electric preference |
|----------|-------------|---------------|-------------------|
| Casual | 33.7% | **66.3%** | **1.87x more likely** |
| Member | 36.6% | **63.4%** | 1.73x more likely |

>  Both groups prefer electric bikes, but casual riders show even stronger preference — likely for longer, more comfortable leisure rides.

---

### 6. Top Start Stations — Casual Riders

| Station | Rides |
|---------|-------|
| Streeter Dr & Grand Ave | 23,870 |
| DuSable Lake Shore Dr & Monroe St | 14,248 |
| Michigan Ave & Oak St | 12,108 |
| DuSable Lake Shore Dr & North Blvd | 11,991 |
| Millennium Park | 11,652 |

>  All top casual rider stations are **tourist locations** (Navy Pier area, Millennium Park, Lake Shore). This is strong evidence that a significant portion of casual riders are **tourists or leisure visitors**, not local commuters.

---

### 7. Rides by Hour of Day

Members show two clear peaks: **8:00 AM** and **5:00 PM** — classic commute pattern.  
Casual riders show a single broad afternoon peak: **12:00 PM – 5:00 PM** — leisure pattern.

---

## Visualizations

All charts produced in **ggplot2 (R)**:

1. Tours count by bike type (bar chart, dodge)
2. Distribution of bike types by customer type (% bar chart)
3. Number of tours by day of the week (bar chart, dodge)
4. Average tour duration by month (bar chart, dodge)
5. Tours by hour of the day (line chart)

---

##  Recommendations

Based on the data analysis, three targeted marketing strategies are recommended:

###  Recommendation 1 — Seasonal Conversion Campaign (May–June)

Launch membership conversion campaigns in **May**, just as casual ridership begins ramping up (+175K rides), rather than at the summer peak when riders are already committed to pay-per-ride. Target the top 10 casual start stations with digital and physical advertising. Offer a **first-month discount** as a conversion incentive.

###  Recommendation 2 — Electric Bike as the Membership Hook

Casual riders choose electric bikes **1.87x more often** than classic bikes. Electric rides are significantly more expensive on a per-ride basis. Campaign angle: *"Unlimited electric rides for the price of a membership."* This is a direct, quantifiable financial argument for the rider's existing behavior.

###  Recommendation 3 — Weekend Membership Tier

The data shows casual riders are heavily concentrated on weekends. A full annual membership may not make financial sense for someone who never rides on weekdays. Introducing a lower-cost **"Weekend Pass"** tier would lower the conversion barrier, build the habit of riding, and serve as a pipeline to full annual membership.

---

##  Repository Structure

```
cyclistic-bike-share-analysis/
│
├── README.md                          # This file
│
├── data/
│   ├── raw/                           # Original monthly CSV files (not uploaded — 1.12 GB)
│   └── processed/
│       ├── tour_combined_raw_data.csv     # Combined 12-month raw data (not uploaded — 1.12 GB)
│       └── tour_combined_cleaned.csv      # Cleaned data for analysis (not uploaded — 971.1 MB)
│
├── analysis/
│   └── Cyclistic_BS_Analysis_in_R.docx   # Full analysis documentation
│
├── scripts/
│   └── Cyclistic_Bike_Analysis.R               # Complete R script
│
└── visualizations/
    └── tableau_dashboard/                 # Tableau workbook (coming soon)
```

---

## How to Reproduce

1. Download 12 months of trip data from [Divvy Trip Data](https://divvy-tripdata.s3.amazonaws.com/index.html)
2. Clone this repository
3. Set your working directory in `cyclistic_analysis.R`
4. Run the script — it will handle combining, cleaning, analysis, and chart generation
5. Export `tour_combined_cleaned_for_tableau.csv` to Tableau for dashboard creation

**Required R packages:**
```r
install.packages(c("tidyverse", "lubridate", "dplyr", "janitor",
                   "tidyr", "data.table", "readr", "psych",
                   "hrbrthemes", "ggplot2"))
```

---

##   Author

**Oleksandr Synichenko**  
IT Professional | Data Analytics Enthusiast
https://www.linkedin.com/in/itspecotonopts/
Dubai, UAE  
Google Data Analytics Professional Certificate — Coursera, 2025

---

##  License

The Cyclistic dataset is made available by **Motivate International Inc.** under the [Divvy Data License Agreement](https://divvybikes.com/data-license-agreement). This project is for educational purposes only.
