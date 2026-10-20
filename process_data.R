# libraries ----
library(jsonlite)
library(here)
library(dplyr)

# params ----
data_folder <- 'G:/HQ/dgof-pru/Project/DDP/AIU app/phase_ii/real-time-example-data'
ap_data_file <- 'airports.json'
nw_data_file <- 'network.json'
ao_data_file <- 'aircraft_operators.json'
ct_data_file <- 'countries.json'
sp_data_file <- 'ansp.json'
reg_data_file <- 'regulations.json'

app_production_folder <- '//ihx-vdm05/LIVE_var_www_performance$/briefing/data'
app_tables_folder <- here(app_production_folder, "support_tables")


# dimensions ----
source("dimensions.R")

# save dimensions to production ----
save_json(dim_ap, "dim_ap")
save_json(list_ap, "list_ap_app")
save_json(rel_aua_acc, "rel_aua_acc")
save_json(rel_acc_ansp, 'rel_acc_ansp')

# ingest data ----
network_data <- fromJSON(here(data_folder, nw_data_file)) |>
  as_tibble()

airports_data <- fromJSON(here(data_folder, ap_data_file)) |>
  as_tibble()

airlines_data <- fromJSON(here(data_folder, ao_data_file)) |>
  as_tibble()

countries_data <- fromJSON(here(data_folder, ct_data_file)) |>
  as_tibble()

ansps_data <- fromJSON(here(data_folder, sp_data_file)) |>
  as_tibble()

regulations_data <- fromJSON(here(data_folder, reg_data_file)) |>
  as_tibble()

# process data ----
## regulations ----
regulations_calc <- regulations_data |>
  mutate(
    reference_location_mod = if_else(
      reference_location == "UNKNOWN",
      most_penalising_regulation,
      reference_location
    ),
    location_code = substr(reference_location_mod, 1, 4),
    regulation_type = if_else(
      location_code %in% unique(dim_ap$ap_code),
      "airport",
      "en route"
    ),
    delay_category = case_when(
      cause %in% c("ATC_CAPACITY", "ATC_STAFFING") ~ "Capacity/Staffing (ATC)",
      cause %in% c("ATC_EQUIPMENT", "ATC_STRIKE") ~ "Disruptions (ATC)",
      cause %in% c("WEATHER") ~ "Weather",
      cause %in% c("AERODROME_CAPACITY") ~ "Aerodrome capacity",
      .default = "Other"
    )
  ) |>
  left_join(
    dim_ap,
    by = c("location_code" = "ap_code")
  ) |>
  left_join(
    rel_aua_acc,
    by = c("location_code" = "short_cfmu_aua")
  ) |>
  mutate(
    location_name = case_when(
      regulation_type == "airport" ~ ap_name,
      .default = aua_name
    )
  ) |>
  select(
    -cause,
    -reference_location
  )

# regulations_calc |> filter(location_code == "EGPH")
