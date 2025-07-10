
faasr_tidy_hobo_sticr <- function(input_file, output_file) {
  # Load STICr package (following neon4cast pattern)
  library(STICr)
  library(tidyverse)
  library(lubridate)
  
  # Log start
  faasr_log(paste("Starting STICr tidy_hobo_data process for:", input_file))
  
  # Download input file from Minio
  faasr_get_file(remote_folder = "stic-data", 
                 remote_file = input_file, 
                 local_file = "input_data.csv")
  
  faasr_log(paste("Downloaded", input_file, "from Minio"))
  
  # Use STICr package tidy_hobo_data function
  faasr_log("Running STICr::tidy_hobo_data...")
  
  # STICr tidy_hobo_data expects infile path and outfile (FALSE for return data)
  tidy_data <- tidy_hobo_data(infile = "input_data.csv", outfile = FALSE)
  
  faasr_log(paste("STICr processing completed:", nrow(tidy_data), "rows processed"))
  faasr_log(paste("STICr version:", packageVersion("STICr")))
  faasr_log(paste("Output columns:", paste(colnames(tidy_data), collapse = ", ")))
  
  # Log summary statistics
  if ("datetime" %in% colnames(tidy_data)) {
    faasr_log(paste("Date range:", min(tidy_data$datetime), "to", max(tidy_data$datetime)))
  }
  if ("tempC" %in% colnames(tidy_data)) {
    faasr_log(paste("Temperature range:", round(min(tidy_data$tempC, na.rm=TRUE), 2), 
                    "to", round(max(tidy_data$tempC, na.rm=TRUE), 2), "C"))
  }
  if ("condUncal" %in% colnames(tidy_data)) {
    faasr_log(paste("Conductivity range:", round(min(tidy_data$condUncal, na.rm=TRUE), 2), 
                    "to", round(max(tidy_data$condUncal, na.rm=TRUE), 2)))
  }
  
  # Save tidied data
  write.csv(tidy_data, "tidy_output.csv", row.names = FALSE)
  
  # Upload to Minio
  faasr_put_file(local_file = "tidy_output.csv",
                 remote_folder = "stic-processed/tidy",
                 remote_file = output_file)
  
  faasr_log(paste("STICr tidy process completed. Output saved as:", output_file))
  faasr_log("STICr package used for professional-grade data processing")
}
