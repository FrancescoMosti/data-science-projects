# Catastrophe Bond Risk Simulation with Hurricanes

This repository contains the complete academic project **`catbonds_1.ipynb`**, developed as part of a second-level Master's in Data Science and Statistical Learning at Università degli Studi di Firenze | IMT Lucca.  
The analysis replicates a simplified, yet robust, framework for estimating **Value at Risk (VaR)** and **Expected Shortfall (ES)** for a **CAT bond** linked to North Atlantic hurricane risk.

---

## Project Goals

- Merge and clean historical hurricane data from multiple open sources ([HURDAT2](https://www.nhc.noaa.gov/data/#hurdat), [EM-DAT](https://www.emdat.be), [Kaggle](https://www.kaggle.com/datasets/valery2042/hurricanes/data).
- Engineer meaningful predictors (`MSLP`, `ACE`, `coordinates`).
- Train a **Random Forest Classifier** to estimate the `conditional probability of catastrophic loss given storm features.
- Generate hurricane scenarios using two approaches:
  - **Bootstrapping with jitter**
  - **Monte Carlo**
- Simulate the conditional payout and compute **VaR** and **ES** for a portfolio exposed to hurricane catastrophe risk.

---

## Repository Structure

```
├── catbonds_1.ipynb     # Main Jupyter notebook with full workflow
├── presentation.html    # html used to present the results
├── data/                # (Optional) Raw data sources
├── requirements.txt     # Python packages to be installed
├── README.md            # Project description and instructions
```

---

## Main Dependencies

- Python 3.13+
- pandas, numpy, seaborn, matplotlib
- scikit-learn
- scipy
- joblib
- tropycal (for hurricane parsing)
- jupyter

To install all dependencies:
```bash
pip install -r requirements.txt
```
Generate `requirements.txt` with:
```bash
pip freeze > requirements.txt
```

---

## Key Methods

- **Random Forest tuning** (`max_depth`, `min_samples_leaf`, `min_samples_split`) to reduce overfitting.
- Scenario generation:
  - Bootstrapping: purely data-driven, limited tail exploration.
  - Monte Carlo: parametric distributions (skew-normal for MSLP, gamma for ACE, uniform for coordinates) to stress-test tail events.
- Final payout modeled as a Bernoulli trigger scaled by MSLP severity.
- VaR and ES computed for both scenario families.

---

## Results Highlights

- Bootstrapped scenarios replicate realistic historical losses.
- Monte Carlo scenarios push tail risk to test extreme payout levels.
- Clear demonstration of how parametric assumptions expand tail risk estimates.

---

## How to Use

1. Clone this repo:
   ```bash
   git clone https://github.com/FrancescoMosti/data-science-projects.git
   ```
2. Open `catbonds_1.ipynb` in Jupyter.
3. Run all cells step-by-step.
4. Explore plots, confusion matrices, scenario distributions and final VaR/ES.
5. Alternatively, open the html for the full presentation.

---

## Credits

Developed by **Francesco Mosti** as part of the **Master in Data Science and Statistical Learning**, University of Florence and IMT Lucca.

---

## License

Feel free to reuse, adapt or extend for educational and non-commercial purposes.  
Acknowledge the original author if you build upon this work.

---

## Final Note

The project is intentionally simplified for academic demonstration.  
Extensions with copulas, spatial kernels, or non-parametric fits are left as future developments.
