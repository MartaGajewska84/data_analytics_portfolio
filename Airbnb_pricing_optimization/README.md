# 🏨 Airbnb Florence Pricing Optimization 

## 🧭 Overview
This project analyzes **Airbnb listings in Florence** to understand how **price changes affect demand and revenue**.

Using **Airbnb open data** and a **Python-based simulation model**, the notebook:

- Estimates **price elasticity of demand**  
- Simulates how different **price change scenarios** impact bookings and revenue  
- Breaks analysis down by:
  - **District (`neighbourhood`)**
  - **Seasonality (month)** for selected districts

> **Note:** The dataset comes from Airbnb and is used solely for educational and analytical purposes.

---

## 🎯 Project Motivation
The central question:

> **What rental prices maximize revenue for Airbnb listings in Florence?**

To answer this, the project:

- Uses `number_of_reviews` as a **proxy for booking demand**
- Estimates how sensitive demand is to price (elasticity)
- Builds simulation functions to test price changes:
  - –20%, –15%, –10%, –5%, +5%, +10%, +15%, +20%
- Extends the simulation by:
  - District (`neighbourhood`)
  - Seasonality (`month`)

---

## 🗂️ Project Files

| File | Description |
|------|-------------|
| `florence_pricing_optimization.ipynb` | Main notebook: EDA, elasticity estimation, pricing simulations. |
| `listings.csv` | Airbnb listings (Florence). Used attributes: `id`, `price`, `number_of_reviews`, `neighbourhood`. |
| `reviews.csv` | Airbnb reviews. Used attributes: `listing_id`, `date` → transformed into `month`, `review_count`. |

---

## 🖼️ Analysis & Modeling Overview

### 1️⃣ Data Preparation
**Listings (`listings.csv`):**
- Loaded into `listings_df`
- Cleaned and inspected using `.head()`, `.info()`, `.describe()`
- Subset created: `df1 = listings_df[['price', 'number_of_reviews']]`
- Missing prices filled using **median** price
- District-level subset: `df2 = listings_df[['id', 'price', 'number_of_reviews', 'neighbourhood']]`

**Reviews (`reviews.csv`):**
- Dates converted to `datetime`
- New column: `month = date.dt.month`
- Aggregation:  
  `monthly_reviews = reviews_df.groupby(['listing_id', 'month']).size().reset_index(name='review_count')`

**Merging for seasonal study:**
- `merged_df = monthly_reviews.merge(df2, left_on='listing_id', right_on='id', how='left')`

---

### 2️⃣ Price Elasticity Estimation
Demand elasticity is estimated with a **log–log regression**:

\[
\log(\text{reviews} + 1) = \beta_0 + \beta_1 \log(\text{price}) + \varepsilon
\]

Steps:

- `log_price = np.log(price)`
- `log_reviews = np.log(number_of_reviews + 1)`
- OLS model via `statsmodels.api.OLS`

The slope (`β₁`) is used as the **elasticity parameter**, e.g.:

elasticity = -0.4015

This value drives the demand and revenue simulations.

---

### 3️⃣ City-Level Simulation

**Function:**

`simulate_price_changes(df, price_change_percentages, elasticity=-0.4015)`

This function calculates, for each price change:

- **New price**
- **Estimated bookings** (via elasticity formula)
- **Expected revenue**

**Outputs:**

- `simulation_results_df`

**Bar charts:**

- Estimated bookings vs. price change  
- Expected revenue vs. price change

---

### 4️⃣ District-Level Simulation

**Function:**

`simulate_price_changes_by_neighbourhood(df, price_change_percentages, elasticity=-0.4015)`

For each district, the function:

- **Computes baseline values**
- **Runs price-change scenarios**
- **Estimates new revenue**

**Outputs:**

- `simulation_results_by_neighbourhood_df`
- `summary_df` showing:
  - **Optimal % price change**
  - **Maximum revenue per district**
- **Heatmap of results**

---

### 5️⃣ Seasonal + District Simulation

**Function:**

`simulate_price_changes_by_neighbourhood_and_month(df, price_change_percentages, elasticity=-0.4015)`

For each **(neighbourhood, month)**, the function computes:

- **Baseline price & demand**
- **New price**
- **Estimated bookings**
- **Expected revenue**

**Outputs:**

- `simulation_results_by_neighbourhood_and_month_df`

**Focused visualizations for:**

- **Campo di Marte**
- **Centro Storico**

**Examples:**

- Revenue across months for **+20%** price scenario  
- Estimated bookings across months

---

## 🧠 Key Findings

| **Finding** | **Description** |
|-------------|------------------|
| **Demand is inelastic** | Price increases reduce bookings only slightly; revenue usually rises. |
| **Lower prices reduce revenue** | Demand increase is too small to compensate for price cuts. |
| **Optimal prices are higher than current levels** | +10% to +20% scenarios produce the best revenues. |
| **High-performing districts** | Campo di Marte and Centro Storico generate the strongest revenues. |
| **Seasonality matters** | Month-by-month results vary, suggesting dynamic pricing strategies. |

---

## 🛠️ Tools & Technologies

| **Tool** | **Purpose** |
|----------|-------------|
| **Python (Jupyter)** | Core analysis environment |
| **pandas** | Data cleaning, merging, grouping |
| **numpy** | Log transforms, numerical operations |
| **statsmodels** | OLS regression (elasticity estimation) |
| **matplotlib / seaborn** | Visualizations |

---

## 🚀 How to Reproduce

1. **Download Florence Airbnb data from:**  
   https://insideairbnb.com/get-the-data/

2. **Ensure the following files are in the project directory:**
   - `listings.csv`
   - `reviews.csv`

3. **Install dependencies:**
   `pip install pandas numpy matplotlib seaborn statsmodels jupyter`

4. **Open the notebook:**
   `jupyter notebook florence_pricing_optimization.ipynb`

5. **Run all cells to reproduce:**
   - Data preparation  
   - Elasticity estimation  
   - City, district, and seasonal simulations

---



