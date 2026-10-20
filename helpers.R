export_query <- function(query, schema = "PRU_READ") {
  withr::local_envvar(c(
    "TZ" = "UTC",
    "ORA_SDTZ" = "UTC",
    "NLS_LANG" = ".AL32UTF8"
  ))

  con <- withr::local_db_connection(
    eurocontrol::db_connection(schema = schema)
  )

  dplyr::tbl(con, dplyr::sql(query)) |>
    collect() |>
    janitor::clean_names()
}

save_json <- function(
  myfile,
  table_name,
  prod_folder = app_tables_folder
) {
  # myfile <- dim_ap
  # table_name <- "dim_ap"
  # prod_folder <- app_tables_folder

  json_table <- myfile |> toJSON(pretty = TRUE)

  write(json_table, here(prod_folder, paste0(table_name, ".json")))
}
