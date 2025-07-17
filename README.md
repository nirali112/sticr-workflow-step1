# STICr  Workflow

## Overview
Automated STIC (Stream Temperature, Intermittency, and Conductivity) data processing pipeline using FaaSr and GitHub Actions.

## Repository Structure
- **Functions**: [nirali112/sticr-functions](https://github.com/nirali112/sticr-functions) - Contains 4 R processing functions
- **Workflows**: [nirali112/sticr-workflow-step1](https://github.com/nirali112/sticr-workflow-step1) - Contains GitHub Actions YML files

## Data Source
HydroShare South Fork Kings Creek STIC dataset: https://www.hydroshare.org/resource/77d68de62d6942ceab6859fc5541fd61/

## How It Works

### 1. Upload Data
- Upload STIC CSV files to MinIO bucket: `faasr/stic-data`
- Supports any CSV file from the HydroShare dataset

### 2. Processing Pipeline
Automatic 4-step workflow:
```
Raw Data → Step 1 (Tidy) → Step 2 (Calibrate) → Step 3 (Classify) → Step 4 (Final)
```

#### Functions:
1. **`faasr_tidy_hobo_sticr()`** - Cleans and formats raw STIC data
2. **`faasr_calibrate_stic()`** - Applies conductivity calibration 
3. **`faasr_classify_wetdry()`** - Classifies wet/dry conditions
4. **`faasr_final_stic()`** - Generates analysis-ready datasets with QAQC

### 3. Output Structure
Results saved to MinIO bucket: `faasr/sticr-workflow/`
- `step1-tidy/` - Cleaned data
- `step2-calibrated/` - Calibrated data  
- `step3-classified/` - Wet/dry classified data
- `step4-final/` - Final analysis-ready datasets

## Usage
Upload CSV files to `faasr/stic-data` and trigger the workflow to process STIC data end-to-end.
