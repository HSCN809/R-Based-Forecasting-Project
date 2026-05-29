# TÜİK Forecasting Project

Student: Hüseyin Berat Özen  
Student number: 138722005  
Course: R-Based Forecasting Project

## 1. Project Overview

This project develops a reproducible R-based forecasting analysis for a monthly TÜİK time series. The selected variable is the monthly rate of change in the Agricultural Products Producer Price Index. The objective is to compare the required quantitative forecasting methods, select the superior method using accuracy results and data suitability, and forecast the next monthly period after the latest available TÜİK observation.

## 2. Data Source and TÜİK Connection

The selected TÜİK dataflow is verified in R through the `tuikr` package. The same verified TÜİK dataflow is then retrieved through reproducible R code from the TÜİK Data Browser JSON endpoint because `tuikr::statistical_data()` returned an HTTP 401 response for the SDMX download in the local test environment. This R-based fallback was approved for the course after the SDMX 401 issue was documented. No manually downloaded, manually edited, copied-and-pasted, or separately created data file is used.

| Field | Value |
|---|---|
| TÜİK data set name | Agricultural Products Producer Price Index |
| TÜİK theme/category | Price Statistics |
| TÜİK table name | Producer Price Index of Agricultural Products and Rates of Change [2020=100] |
| `tuikr` dataflow ID | `TR,DF_TARIM_URUNLERI_UFE_DEGISIM_V1,1.0` |
| Selected variable | Change compared to the previous month (%) |
| Data frequency | Monthly |
| Time coverage | 2010-02 / 2026-04 |
| Latest available observation | 2026-04 |
| Forecast target period | 2026-05 |
| Date of data access | Generated at runtime with `Sys.Date()` |
| R package used for dataflow verification | `tuikr` |
| Package source | <https://github.com/emraher/tuikr> |

## 3. Research Objective

The project forecasts the next monthly percentage change in the Agricultural Products Producer Price Index. This variable is meaningful because it measures short-term producer price movement in agricultural products and is observed regularly over ordered monthly periods.

## 4. Use of TÜİK Data in R

The data are accessed and processed inside R. The notebook filters the TÜİK output to the total Agricultural Products Producer Price Index series for Türkiye, monthly frequency, base year 2020, and the rate-of-change variable. The period variable is converted to a monthly date, observations are sorted chronologically, and missing values, duplicate periods, and missing monthly periods are checked in the notebook.

## 5. Exploratory Time Series Analysis

The notebook includes an actual time series plot, descriptive statistics, trend assessment, monthly average comparison, and data-quality checks. The selected series is volatile because it measures monthly percentage change. The monthly structure supports seasonal comparison, while the small linear trend estimate means trend-only methods should not be selected without accuracy evidence.

## 6. Forecasting Methods Applied

The project applies or explicitly evaluates the required methods:

- Naïve Forecasting
- Moving Average
- Weighted Moving Average
- Exponential Smoothing
- Trend-Adjusted Exponential Smoothing
- Linear Trend Projection
- Seasonal Indices
- Additive Decomposition
- Multiplicative Decomposition
- Regression with Trend and Seasonal Dummy Variables

Multiplicative decomposition is marked as not applicable because the selected monthly rate-of-change series contains negative values, while multiplicative decomposition requires strictly positive observations.

## 7. Forecast Accuracy Comparison

The model comparison table is written to `outputs/tables/accuracy_comparison.csv`. It includes Bias / Mean Error, MAD, MSE, MAPE, RSFE, Tracking Signal, applicability status, notes, and the next-period forecast. Period-by-period forecast errors are also written to `outputs/tables/forecast_errors.csv`. Multiplicative decomposition remains in the comparison table as not applicable, with the technical reason documented in the note column.

## 8. Selection of the Superior Method

The superior method is selected from applicable methods using holdout MAPE, MAD, tracking signal, and suitability to the monthly data structure. Seasonal Indices is selected because it has the lowest holdout MAPE among the applicable methods and directly represents recurring monthly effects in the selected TÜİK series.

## 9. Final Next-Period Forecast

| Field | Value |
|---|---|
| Selected superior method | Seasonal Indices |
| Latest available TÜİK observation | 2026-04 |
| Forecast target period | 2026-05 |
| Forecasted value | -0.6638 |

The final forecast table is written to `outputs/tables/final_forecast.csv`. The data access date is generated during execution, so rerunning the notebook updates that field to the current run date.

## 10. Interpretation of Results

The final forecast means that the selected method expects a small negative monthly change in the Agricultural Products Producer Price Index for 2026-05. Seasonal Indices performs best in the holdout comparison because the monthly pattern is important for this series. Trend-only and smoothing-based alternatives have larger aggregate errors or stronger tracking-signal imbalance.

## 11. Limitations

The series is a monthly percentage-change series, so it can be volatile and negative. This makes multiplicative decomposition unsuitable. The comparison uses a 24-month holdout period, and future TÜİK revisions, economic shocks, or structural breaks could change the relative performance of the methods.

## 12. Reproducibility

Run the project from the repository root. The main entry point is `main.R`. It calls `R/dependencies.R`, installs missing CRAN packages automatically, installs `tuikr` from GitHub if it is not already available, checks that Pandoc is available, and renders the notebook to HTML. The script prints short step-by-step logs while it runs.

```r
source("main.R")
```

Render the full notebook manually after the required packages are available:

```r
rmarkdown::render("forecasting_project.Rmd")
```

Regenerate only the CSV tables and PNG figures:

```r
source("run_analysis.R")
```

As an alternative reproducibility path, install `renv` and restore the package environment from `renv.lock`:

```r
install.packages("renv")
renv::restore()
```

## 13. Repository Structure

```text
tuik-forecasting-project/
├── README.md
├── forecasting_project.Rmd
├── forecasting_project.html
├── main.R
├── run_analysis.R
├── outputs/
│   ├── tables/
│   │   ├── accuracy_comparison.csv
│   │   ├── forecast_errors.csv
│   │   └── final_forecast.csv
│   └── figures/
│       ├── actual_series_plot.png
│       ├── naive_forecast_plot.png
│       ├── moving_average_plot.png
│       ├── weighted_moving_average_plot.png
│       ├── exponential_smoothing_plot.png
│       ├── trend_adjusted_smoothing_plot.png
│       ├── trend_projection_plot.png
│       ├── seasonal_indices_plot.png
│       ├── additive_decomposition_plot.png
│       ├── regression_seasonal_dummy_plot.png
│       └── superior_method_plot.png
├── R/
│   ├── data_import.R
│   ├── dependencies.R
│   ├── forecasting_methods.R
│   ├── accuracy_measures.R
│   └── plots.R
├── renv.lock
└── .gitignore
```

## 14. Author

Hüseyin Berat Özen  
Student number: 138722005  
Course: R-Based Forecasting Project
