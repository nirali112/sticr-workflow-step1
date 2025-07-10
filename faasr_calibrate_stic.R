
faasr_calibrate_stic <- function(input_file, output_file, calibration_slope, calibration_intercept) {
  # Step 2: Apply calibration to STIC data (STICr paper implementation)
  
  # Log start
  faasr_log(paste("Starting calibration process for:", input_file))
  
  # Download tidy data from previous step
  faasr_get_file(remote_folder = "stic-processed/tidy", 
                 remote_file = input_file, 
                 local_file = "tidy_data.csv")
  
  # Read the tidy data (should have: datetime, condUncal, tempC)
  tidy_data <- read.csv("tidy_data.csv")
  faasr_log(paste("Read", nrow(tidy_data), "rows of tidy data"))
  
  # Log input columns
  faasr_log(paste("Input columns:", paste(colnames(tidy_data), collapse = ", ")))
  
  # Apply calibration: SpC = slope * condUncal + intercept
  calibrated_data <- tidy_data
  calibrated_data$SpC <- calibration_slope * tidy_data$condUncal + calibration_intercept
  
  # Add outside_std_range column (empty for now, as per STICr paper)
  calibrated_data$outside_std_range <- ""
  
  # Log calibration results
  faasr_log(paste("Applied calibration: SpC = ", calibration_slope, " * condUncal + ", calibration_intercept))
  faasr_log(paste("SpC range:", round(min(calibrated_data$SpC, na.rm=TRUE), 2), 
                  "to", round(max(calibrated_data$SpC, na.rm=TRUE), 2)))
  
  # STICr paper output: datetime, condUncal, tempC, SpC, outside_std_range
  output_columns <- c("datetime", "condUncal", "tempC", "SpC", "outside_std_range")
  final_data <- calibrated_data[, output_columns]
  
  faasr_log(paste("After calibration:", nrow(final_data), "rows"))
  faasr_log(paste("Output columns:", paste(colnames(final_data), collapse = ", ")))
  
  # Save calibrated data
  write.csv(final_data, "calibrated_output.csv", row.names = FALSE)
  
  # Upload to Minio
  faasr_put_file(local_file = "calibrated_output.csv",
                 remote_folder = "stic-processed/calibrated",
                 remote_file = output_file)
  
  faasr_log(paste("Calibration completed. Output saved as:", output_file))
  faasr_log("Output columns: datetime, condUncal, tempC, SpC, outside_std_range (STICr paper implementation)")
}
