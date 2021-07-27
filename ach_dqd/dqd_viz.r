#!/usr/bin/Rscript

# WARNING: this script relies on defaults set by entrypoint.sh

message("Initiating DQD Visualizations...")

valid_display_mode <- list(
  "normal",
  "auto",
  "showcase"
)

# Default values are defined in the entrypoint
env <- list()
env[names(Sys.getenv())] <- Sys.getenv()

env$DQD_VIZ_PORT <- as.numeric(env$DQD_VIZ_PORT)

as_bool <- function(x) as.logical(as.numeric(x))
env$DQD_VIZ_LAUNCH_BROWSER <- as_bool(env$DQD_VIZ_LAUNCH_BROWSER)

if (!(env$DQD_VIZ_DISPLAY_MODE %in% valid_display_mode)) {
  stop("Cannot proceed with invalid display mode: ", env$DQD_VIZ_DISPLAY_MODE)
}

if (env$DQD_RUN == "1" && env$DQD_VIZ_JSON_PATH == "0") {
  json_dir <- paste(
    env$DQD_OUTPUT_BASE,
    env$ACH_DQD_SOURCE_NAME,
    env$TIMESTAMP_RUN,
    sep = "/"
  )
  json_path <- file.path(json_dir, env$DQD_JSON_FILE_NAME)
} else if (env$DQD_RUN == "0" && env$DQD_VIZ_JSON_PATH != "0") {
  json_dir <- env$DQD_VIZ_JSON_PATH
  json_path <- file.path(json_dir, env$DQD_JSON_FILE_NAME)
} else {
  stop("Json path not specified properly: DQD results cannot be visualized")
}

Sys.setenv(jsonPath = json_path)
message("Displaying results contained in: ", json_path)

if (env$DQD_VIZ_HOST == "localhost") {
  env$DQD_VIZ_HOST <- "0.0.0.0"
}

app_dir <- system.file(
  "shinyApps",
  package = "DataQualityDashboard"
)

shiny::runApp(
  appDir = app_dir,
  host = env$DQD_VIZ_HOST,
  port = env$DQD_VIZ_PORT,
  display.mode = env$DQD_VIZ_DISPLAY_MODE,
  launch.browser = env$DQD_VIZ_LAUNCH_BROWSER
)
