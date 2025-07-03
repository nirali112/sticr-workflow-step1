
faasr_tidy_hobo <- function(input_file, output_file) {
  # Step 1: Tidy HOBO/STIC sensor data
  
  # Log start
  faasr_log(paste("Starting tidy process for:", input_file))
  
  # Download input file from Minio
  faasr_get_file(remote_folder = "stic-data", 
                 remote_file = input_file, 
                 local_file = "input_data.csv")
  
  # Read the data
  raw_data <- read.csv("input_data.csv")
  faasr_log(paste("Read", nrow(raw_data), "rows of data"))
  
  # Tidy operations based on STICr workflow
  tidy_data <- raw_data
  
  # 1. Convert datetime to proper POSIXct format
  tidy_data$datetime <- as.POSIXct(tidy_data$datetime, 
                                   format = "%Y-%m-%dT%H:%M:%SZ", 
                                   tz = "UTC")
  
  # 2. Remove any duplicate timestamps
  tidy_data <- tidy_data[!duplicated(tidy_data$datetime), ]
  
  # 3. Sort by datetime
  tidy_data <- tidy_data[order(tidy_data$datetime), ]
  
  # 4. Add derived columns for analysis
  tidy_data$year <- format(tidy_data$datetime, "%Y")
  tidy_data$month <- format(tidy_data$datetime, "%m")
  tidy_data$day <- format(tidy_data$datetime, "%d")
  tidy_data$hour <- format(tidy_data$datetime, "%H")
  
  # 5. Create unique record ID
  tidy_data$record_id <- paste(tidy_data$siteId, 
                               tidy_data$sublocation,
                               format(tidy_data$datetime, "%Y%m%d%H%M%S"),
                               sep = "_")
  
  # 6. Add processing metadata
  tidy_data$tidy_date <- Sys.Date()
  tidy_data$tidy_version <- "1.0"
  
  # Log summary statistics
  faasr_log(paste("After tidying:", nrow(tidy_data), "rows"))
  faasr_log(paste("Date range:", min(tidy_data$datetime), "to", max(tidy_data$datetime)))
  faasr_log(paste("Temperature range:", round(min(tidy_data$tempC, na.rm=TRUE), 2), 
                  "to", round(max(tidy_data$tempC, na.rm=TRUE), 2), "C"))
  
  # Save tidied data
  write.csv(tidy_data, "tidy_output.csv", row.names = FALSE)
  
  # Upload to Minio
  faasr_put_file(local_file = "tidy_output.csv",
                 remote_folder = "stic-processed/tidy",
                 remote_file = output_file)
  
  faasr_log(paste("Tidy process completed. Output saved as:", output_file))
}
