source("helpers.R")

# Airport ----
dim_ap <- export_query(
  "
                            select
                            coalesce(CFMU_AP_CODE, EC_AP_CODE) as AP_CODE,
                            EC_AP_NAME as AP_NAME
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
