# ✈️ Airline Route Profitability & Demand Forecasting

End-to-end data analytics project on **7,974 Emirates (DXB) flights across 30 routes**
in FY2024 — data cleaning, exploratory analysis, route profitability diagnostics,
K-Means route segmentation, feature-importance analysis, demand & revenue
forecasting, and an executive dashboard, all in one reproducible Python script /
Jupyter notebook.

## 📊 Highlights

- **AED 2.37B** total revenue · **AED 575.5M** total profit · **6.2%** average margin
- **8 of 30 routes** are net loss-making for the year — surfaced and quantified
- Missing values (`Ancillary_Revenue`, `Catering_Cost`, `Handling_Cost`) recovered
  **algebraically** from totals rather than imputed — no information lost
- **K-Means segmentation** of routes into Star / Cash Cow / Question Mark / Underperformer tiers
- **Random Forest** feature-importance analysis of what actually drives profit margin (R² = 0.78)
- **6-week demand & revenue forecasts**, backtested with MAE / RMSE / MAPE
- **18 saved charts** + a one-page executive dashboard, all reproducible from raw data

## 🗂️ Repository Structure

```
Airline Route Profitability/
├── Airline_Route_Profitability.csv           # raw source data
├── Description.txt                           # data dictionary
├── Airline_Route_Profitability_Analysis.py   # full analysis pipeline (this repo's main script)
├── outputs/
│   ├── figures/        # 18 saved PNG charts, 200 DPI
│   ├── reports/        # cleaned data, route summary, forecasts, executive summary
│   └── models/
├── requirements.txt
└── README.md
```
> The script auto-detects the CSV anywhere inside the project folder, so the exact
> subfolder layout above is a suggestion, not a hard requirement — see **How to Run**.

## 🚀 How to Run

```bash
pip install -r requirements.txt
```

Open `Airline_Route_Profitability_Analysis.py` in Jupyter (paste into a notebook cell,
or run directly) or execute it as a script:

```bash
python Airline_Route_Profitability_Analysis.py
```

Before running, set `BASE_DIR` near the top of the script to your project folder:

```python
BASE_DIR = Path(r"C:\Users\Administrator\Desktop\GitHub Repository\Airline Route Profitability")
```

The script then searches that folder (and subfolders) for the dataset CSV
automatically, creates `outputs/figures`, `outputs/reports`, `outputs/models` if
they don't exist, and writes every chart and table there as it runs.

## 📓 Analysis Contents

1. **Setup & Configuration**
2. **Data Loading & First Look**
3. **Data Quality Audit**:  missing values, duplicates, arithmetic consistency checks
4. **Data Cleaning & Feature Engineering**:  algebraic recovery of missing values;
   time, unit-economics (RASK/CASK), and cost-structure features
5. **Exploratory Data Analysis**
   - Revenue & cost structure
   - Route-level profitability (top/bottom routes, profitability map)
   - Seasonality effects
   - Fleet / aircraft performance
   - Load factor & demand
   - Correlation analysis
6. **Route Segmentation** : K-Means profitability matrix (BCG-style: Star / Cash Cow / Question Mark / Underperformer)
7. **Profitability Drivers** : Random Forest feature importance
8. **Demand Forecasting** : weekly passengers, Linear Regression vs. Random Forest, 6-week forecast
9. **Revenue Forecasting** : same methodology applied to weekly revenue
10. **Executive Dashboard** : one-page KPI summary + optional interactive `ipywidgets` explorer
11. **Key Insights & Recommendations** — auto-generated from the live data

## 🔑 Key Findings

| Metric | Value |
|---|---|
| Total flights | 7,974 |
| Total revenue | AED 2.37B |
| Total profit | AED 575.5M |
| Average profit margin | 6.2% |
| Loss-making flights | 33.7% |
| Net loss-making routes | 8 of 30 |
| Best route | DXB-FRA (AED 99.5M profit, 46.1% margin) |
| Weakest route | DXB-CAI (–AED 8.2M profit, –84.0% margin) |
| Best season | Peak (17.5% avg margin) |
| Weakest season | Low (–8.5% avg margin) |
| Best aircraft (margin) | Airbus A380 |
| Weakest aircraft (margin) | Boeing 737-800 |

## 🛠️ Tech Stack

`pandas` · `numpy` · `matplotlib` · `seaborn` · `scikit-learn` (RandomForest, KMeans,
LinearRegression) · `ipywidgets` (optional interactive dashboard)

## 📁 Data Dictionary

See `Description.txt` for full column definitions covering operational, revenue,
cost, and profitability features.

## 👤 Author

Mohammad Arif Ul Islam
