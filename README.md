# R-Based Forecasting Project Using TÜİK Data

Student: Hüseyin Berat Özen  
Student number: 138722005

## Project Overview

This project forecasts the next monthly observation for a TÜİK time series using R. The selected series is the monthly rate of change in the Agricultural Products Producer Price Index.

## TÜİK Data Source

| Field | Value |
|---|---|
| TÜİK Data Set Name | Agricultural Products Producer Price Index |
| TÜİK Theme / Category | Price Statistics |
| TÜİK Table Name | Producer Price Index of Agricultural Products and Rates of Change [2020=100] |
| tuikr Dataflow ID | `TR,DF_TARIM_URUNLERI_UFE_DEGISIM_V1,1.0` |
| Selected Variable | Change compared to the previous month (%) |
| Data Frequency | Monthly |
| Time Coverage | 2010-02 / 2026-04 |
| Latest Available Observation | 2026-04 |
| Forecast Target Period | 2026-05 |

The dataflow is verified through `tuikr::statistical_tables(theme = 6)`. In this environment, `tuikr::statistical_data()` returned HTTP 401 for SDMX downloads, so the notebook retrieves the same verified dataflow through the TÜİK Data Browser JSON endpoint in R. No manually downloaded or manually edited data file is used.

## Forecasting Methods

The notebook applies the required forecasting methods where applicable:

- Naïve Forecasting
- Moving Average
- Weighted Moving Average
- Exponential Smoothing
- Trend-Adjusted Exponential Smoothing
- Linear Trend Projection
- Seasonal Indices
- Additive Decomposition
- Regression with Trend and Seasonal Dummy Variables

Multiplicative decomposition is documented as not applicable because the monthly rate-of-change series contains negative values.

## Outputs

The project writes:

- `outputs/tables/accuracy_comparison.csv`
- `outputs/tables/final_forecast.csv`
- actual and forecast plots under `outputs/figures/`

## Reproducibility

Install the required R packages, then render the notebook from the project root:

```r
rmarkdown::render("forecasting_project.Rmd")
```

If Pandoc is installed but not visible on PATH, set the Pandoc directory before rendering:

```r
Sys.setenv(RSTUDIO_PANDOC = "C:/Users/ozenh/AppData/Local/Pandoc")
rmarkdown::render("forecasting_project.Rmd")
```

To regenerate only the CSV tables and PNG figures without rendering HTML:

```r
source("run_analysis.R")
```

Required packages:

```r
c("tuikr", "curl", "jsonlite", "tibble", "dplyr", "tidyr", "ggplot2", "zoo", "forecast", "knitr", "rmarkdown")
```

The main analysis file is `forecasting_project.Rmd`. Supporting functions are in the `R/` folder.
