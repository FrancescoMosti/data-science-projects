# Causal Inference analysis on implied volatility in the NASDAQ options market using Double Machine Learning

This repository contains the complete academic project **`volatility-smile-dml.ipynb`**, developed as part of a second-level Master's in Data Science and Statistical Learning at Università degli Studi di Firenze | IMT Lucca.

The analysis replicates a simplified, yet robust, framework for the estimation of the empirical effect of liquidity (measured by the bid-ask spread) on **Implied Volatility** in the `NASDAQ (QQQ)` option market, using the recently developed Double Machine learning technique proposed by [Chernozhukov et.al. (2018)](https://academic.oup.com/ectj/article/21/1/C1/5056401).\
The structure of the analysis follows the work by [Li, Lin, Yu, Liu (2025)](https://www.sciencedirect.com/science/article/abs/pii/S0927538X24003974?utm_source=chatgpt.com) focused instead on the newly established Chinese CSI 300 options index.

![Volatility Smile Structure](images/vsmile.png)
---

## Project Goals

- Merge and clean historical call and put options from Yahoo Finance over multiple trading days.
- Employ the Double Machine Learning framework to estimate the effect of a **treatment variable** (in our case, `liquidity`, proxied by the bid-ask spread) on an **outcome variable** (`implied volatility`), in the presence of **confounders**.
     
> 1. The key idea of Double Machine Learning is to estimate $g_0(X)$ and $m_0(X)$ using **flexible machine learning methods**, allowing for nonparametric relationships between the confounders and both the treatment and the outcome.
>   2. Once these functions are estimated, we compute the residuals: $\tilde{Y} = Y - \hat{g}(X)$ and $\tilde{D} = D - \hat{m}(X)$
>   3. Finally, we recover an estimate of the causal effect $\theta_0$ by regressing the partialled out effect on the outcome on the partialled out effect on the treatment: $\tilde{Y} = \theta_0 \tilde{D} + \varepsilon$
>      
> This procedure ensures **orthogonality** between the treatment and the nuisance components, which mitigates overfitting bias and allows for valid inference even in high-dimensional or nonlinear settings.
    
- Evaluate the results on both Call and Put options.
- Moreover, as preliminary step a brief analysis on Deterministic Volatility Functions will also be proposed.

---

## Repository Structure

```
├── data/                        # Raw data sources
├── images/                      # Collection of visual resutls
├── README.md                    # Project description and instructions
├── volatility-smile-dml.ipynb   # Main Jupyter notebook with full workflow
├── volatility-smile-dml.html    # html used to present the results
├── requirements.txt             # Python packages to be installed
```

---

## Main Dependencies

- Python 3.13+
- pandas, numpy, seaborn, matplotlib, datetime
- yfinance
- scikit-learn
- statsmodels
- xgboost

To install all dependencies:
```bash
pip install -r requirements.txt
```
Generate `requirements.txt` with:
```bash
pip freeze > requirements.txt
```

---

## Key Machine Learning Models evaluated

- Lasso
- Ridge
- Elastic Net
- Decision Trees
- Random Forests
- Gradient Boosting
- SVM
- KNN
- XGBoost

---

## Confounders

- strike
- time-to-maturity (years)
- volume
- open interest
- realized volatility
- momentum

---

## Results Highlights

- Causal effect positive and significant only for **put options** (between 3%-4% magnitude).
- Among all tested models, **Gradient Boosting** achieved the strongest results, with lower standard errors, narrower confidence intervals, and more significant p-values.
- XGBoost also detects significant effects in the put market, consistently with the original paper.
- In contrast, Random Forest, while achieving the lowest RMSE during tuning, fails to capture significant effects in the final causal regression, possibly due to overfitting in the estimation of nuisance functions.

---

## How to Use

1. Clone this repo:
   ```bash
   git clone https://github.com/FrancescoMosti/data-science-projects.git
   ```
2. Open `volatility-smile.ipynb` in Jupyter.
3. Run all cells step-by-step.
4. Alternatively, open the html for the full presentation.

---

## Credits

Developed by **Francesco Mosti** as part of the **Master in Data Science and Statistical Learning**, University of Florence and IMT Lucca.
francesco.mosti@yahoo.com

---

## License

Feel free to reuse, adapt or extend for educational and non-commercial purposes.  
Acknowledge the original author if you build upon this work.

---

## References

*Pengshi Li, Yan Lin, Xing Yu, Guifang Liu, 2025. Does bid-ask spread explains the smile? On DVF and DML. Pacific-Basin Finance Journal 90 (2025) 102645.*

*Bernard Dumas, Jeff Fleming, Robert E. Whaley, 2002. Implied Volatility Functions: Empirical Tests. The Journal of Finance 53, Issue 6 (1998).*

*Kim, (2009). The performance of traders' rules in options market. The Journal of Futures Markets 29, Issue 6 (2009).*

*Derman, Kani, (1994). The Volatility Smile and its Implied Tree. Quantitative Strategies Research Notes, Goldman Sachs.*

*Peña, Juan Ignacio and Rubio, Gonzalo A. and Serna Calvo, Gregorio, Smiles, Bid-Ask Spread and Option Pricing. Available at SSRN: https://ssrn.com/abstract=233340 .*

*Victor Chernozhukov ,  Denis Chetverikov ,  Mert Demirer ,  Esther Duflo ,  Christian Hansen , Whitney Newey ,  James Robins, (2018). The Econometrics Journal, Volume 21, Issue 1, 1 February 2018, Pages C1–C68*


