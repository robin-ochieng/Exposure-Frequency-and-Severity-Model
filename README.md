# Exposure-Frequency-and-Severity-Model

**Author:** Robin Ochieng Otieno    
**Version:** 1.4.1

## Overview

The **Exposure-Frequency-and-Severity-Model** is an actuarial and insurance analytics tool designed to model and visualize risk components. It focuses on breaking down the expected cost of claims into three fundamental elements:

1. **Exposure:** How much of a particular risk is exposed to potential claims.
2. **Frequency:** How often claims are expected to occur.
3. **Severity:** How large each claim is expected to be, on average.

By integrating these three components, the model aims to estimate the overall risk premium, which can guide pricing, underwriting decisions, and strategic risk management.

## Key Features

- **Modular Architecture:** Built using R’s Shiny framework, enabling easy maintenance, extension, and customization.
- **Interactive Visualizations:** Explore frequency and severity distributions through dynamically generated plots.
- **Scenario Testing:** Adjust parameters for exposure, frequency, and severity to see how changes affect the risk premium.
- **Data-Driven:** Load your own datasets and fit frequency and severity distributions to real-world data.

## Directory Structure

- **modules/**  
  Contains Shiny modules that encapsulate different parts of the application logic (e.g., frequency module, severity module, risk premium module).

- **www/**  
  Holds static resources such as CSS, JavaScript, and images for the front-end.

- **app.R**  
  The primary Shiny application file that launches the user interface and server logic.

- **app copy.R / app1.R**  
  Additional or legacy versions of the application code. These might be experimental, backup, or reference versions.

- **README.md**  
  This file, providing an overview and instructions for usage and setup.

- **.Rhistory**  
  Contains command history for development convenience (not essential for deployment).

## Getting Started

### Prerequisites

- **R (version 4.0+ recommended)**
- **R Packages:**  
  - `shiny`  
  - `ggplot2`  
  - `dplyr`, `tidyr`  
  - Other packages as required by the modules.

Install any missing packages by running in R:

```r
install.packages(c("shiny", "ggplot2", "dplyr", "tidyr"))


