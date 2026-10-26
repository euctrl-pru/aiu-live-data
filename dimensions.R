source("helpers.R")

# Airport ----
dim_ap <- export_query(
  "
                            select
                            coalesce(CFMU_AP_CODE, EC_AP_CODE) as AP_CODE,
                            EC_AP_NAME as AP_NAME,
                            latitude,
                            longitude
                            from pruread.v_aiu_dim_airport
                            where valid_to >= trunc(sysdate)
                            "
)


list_ap <- export_query(
  'SELECT BK_AP_ID, EC_AP_CODE as AP_CODE FROM pruread.v_aiu_app_list_airport'
)

# AUA, ACC ----
dim_acc <- export_query(
  'SELECT aua_code as acc_code, aua_name as acc_name FROM prudev.v_pru_aua
  where aua_till >= trunc(sysdate)',
  schema = "PRU_DEV"
)

dim_aua <- export_query(
  'select distinct stat_aua_id, aua_name from ARU_SYN.STAT_AUA',
  schema = "PRU_DEV"
)


rel_aua_acc <- export_query(
  'SELECT cfmu_aua, acc_id as acc_code FROM DELAY_TRACKER.AUX_RELAT_AUA_ACC',
  schema = "PRU_DEV"
) |>
  mutate(
    short_cfmu_aua = substr(cfmu_aua, 1, 4)
  ) |>
  select(acc_code, short_cfmu_aua) |>
  unique() |>
  left_join(dim_aua, by = c("acc_code" = "stat_aua_id"))

# ACC, ANSP ----
app_folder <- '../mobile-app/'

ansp_list <- readxl::read_xlsx(
  here(app_folder, 'stakeholder_lists.xlsx'),
  sheet = 'ansp_lists'
) |>
  janitor::clean_names() |>
  mutate(
    iso_2letter = stringr::str_remove_all(ansp_code, '_ANSP'),
    iso_2letter = if_else(iso_2letter == "MERS", "RS", iso_2letter)
  )

acc_list <- readxl::read_xlsx(
  here(app_folder, 'stakeholder_lists.xlsx'),
  sheet = 'acc_lists'
) |>
  janitor::clean_names() |>
  select(-nm_name)

rel_acc_ansp <- ansp_list |>
  left_join(acc_list, by = 'iso_2letter') |>
  mutate(
    acc_icao_code = substr(icao_code, 1, 4),
    acc_name = name
  ) |>
  select(-iso_2letter, -icao_code) |>
  select(
    ansp_code,
    ansp_name,
    acc_icao_code
  ) |>
  unique()

# AO, AO Group ----
list_ao_grp_rel_ao <- export_query(
  'SELECT * FROM pruread.v_aiu_app_list_ao_grp'
) |>
  filter(
    til >= lubridate::today()
  ) |>
  select(
    ao_grp_code,
    ao_code
  ) |>
  arrange(ao_grp_code, ao_code)
