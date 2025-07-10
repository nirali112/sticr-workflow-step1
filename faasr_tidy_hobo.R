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
  
  # Log column names for debugging
  faasr_log(paste("Column names in raw data:", paste(colnames(raw_data), collapse = ", ")))
  
  # Handle different possible column names
  datetime_col <- NA
  temp_col <- NA
  cond_col <- NA
  
  # Find datetime column
  datetime_candidates <- c("datetime", "DateTime", "Date.Time", "date_time", "DATETIME")
  for (col in datetime_candidates) {
    if (col %in% colnames(raw_data)) {
      datetime_col <- col
      break
    }
  }
  
  # Find temperature column
  temp_candidates <- c("tempC", "temp", "temperature", "Temperature", "Temp", "temp_c", "TEMP")
  for (col in temp_candidates) {
    if (col %in% colnames(raw_data)) {
      temp_col <- col
      break
    }
  }
  
  # Find conductivity column
  cond_candidates <- c("condUncal", "conductivity", "Conductivity", "cond", "COND", "conduct")
  for (col in cond_candidates) {
    if (col %in% colnames(raw_data)) {
      cond_col <- col
      break
    }
  }
  
  # Check if we found all required columns
  if (is.na(datetime_col)) {
    stop("Could not find datetime column. Available columns: ", paste(colnames(raw_data), collapse = ", "))
  }
  if (is.na(temp_col)) {
    stop("Could not find temperature column. Available columns: ", paste(colnames(raw_data), collapse = ", "))
  }
  if (is.na(cond_col)) {
    stop("Could not find conductivity column. Available columns: ", paste(colnames(raw_data), collapse = ", "))
  }
  
  faasr_log(paste("Using columns - datetime:", datetime_col, ", temperature:", temp_col, ", conductivity:", cond_col))
  
  # STICr tidy_hobo_data() implementation
  # The function should output 3 columns: datetime, condUncal, tempC
  
  # Convert datetime to proper POSIXct format (UTC)
  # Try different datetime formats
  datetime_formats <- c(
    "%Y-%m-%d %H:%M:%S",
    "%Y-%m-%dT%H:%M:%SZ", 
    "%m/%d/%Y %H:%M:%S",
    "%d/%m/%Y %H:%M:%S",
    "%Y-%m-%d %H:%M",
    "%m/%d/%Y %H:%M"
  )
  
  datetime_converted <- NULL
  for (fmt in datetime_formats) {
    datetime_converted <- as.POSIXct(raw_data[[datetime_col]], format = fmt, tz = "UTC")
    if (!all(is.na(datetime_converted))) {
      faasr_log(paste("Successfully parsed datetime using format:", fmt))
      break
    }
  }
  
  if (all(is.na(datetime_converted))) {
    stop("Could not parse datetime column with any known format")
  }
  
  # Create tidy data frame
  tidy_data <- data.frame(
    datetime = datetime_converted,
    condUncal = as.numeric(raw_data[[cond_col]]),
    tempC = as.numeric(raw_data[[temp_col]])
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