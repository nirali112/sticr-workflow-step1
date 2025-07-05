faasr_tidy_hobo <- function(input_file, output_file) {
  # Step 1: Tidy HOBO/STIC sensor data (STICr paper implementation)
  
  # Log start
  faasr_log(paste("Starting tidy process for:", input_file))
  
  # Download input file from Minio
  faasr_get_file(remote_folder = "stic-data", 
                 remote_file = input_file, 
                 local_file = "input_data.csv")
  
  # Read the data
  raw_data <- read.csv("input_data.csv")
  faasr_log(paste("Read", nrow(raw_data), "rows of data"))
  
  # STICr tidy_hobo_data() implementation
  # The function should output exactly 3 columns: datetime, condUncal, tempC
  
  # 1. Convert datetime to proper POSIXct format (UTC)
  tidy_data <- data.frame(
    datetime = as.POSIXct(raw_data$datetime, 
                         format = "%Y-%m-%dT%H:%M:%SZ", 
                         tz = "UTC"),
    condUncal = raw_data$condUncal,
    tempC = raw_data$tempC
  )
  
  # 2. Remove any duplicate timestamps
  tidy_data <- tidy_data[!duplicated(tidy_data$datetime), ]
  
  # 3. Sort by datetime
  tidy_data <- tidy_data[order(tidy_data$datetime), ]
  
  # 4. Remove any rows with NA datetime (invalid dates)
  tidy_data <- tidy_data[!is.na(tidy_data$datetime), ]
  
  # Log summary statistics
  faasr_log(paste("After tidying:", nrow(tidy_data), "rows"))
  faasr_log(paste("Date range:", min(tidy_data$datetime), "to", max(tidy_data$datetime)))
  faasr_log(paste("Temperature range:", round(min(tidy_data$tempC, na.rm=TRUE), 2), 
                  "to", round(max(tidy_data$tempC, na.rm=TRUE), 2), "C"))
  faasr_log(paste("Conductivity range:", round(min(tidy_data$condUncal, na.rm=TRUE), 2), 
                  "to", round(max(tidy_data$condUncal, na.rm=TRUE), 2)))
  
  # Save tidied data with only the 3 required columns
  write.csv(tidy_data, "tidy_output.csv", row.names = FALSE)
  
  # Upload to Minio
  faasr_put_file(local_file = "tidy_output.csv",
                 remote_folder = "stic-processed/tidy",
                 remote_file = output_file)
  
  faasr_log(paste("Tidy process completed. Output saved as:", output_file))
  faasr_log("Output columns: datetime, condUncal, tempC (STICr paper implementation)")
}
