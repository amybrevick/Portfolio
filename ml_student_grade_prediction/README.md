# Student Grade Prediction using Machine Learning

This project builds and evaluates a predictive model to estimate final student grades based on demographic, behavioral, and academic features. Using a Portuguese high school dataset, it compares model performance with and without midterm grades to explore early-stage prediction feasibility.

---

## Dataset Overview

- **Source**: UCI Machine Learning Repository – Student Performance Data Set  
- **Observations**: 395 students  
- **Target Variable**: `G3` – Final grade (0 to 20 scale)

### Key Features Used:
- First and second term grades (`G1`, `G2`)
- Parental education level
- Study time, absences
- Participation in additional classes, internet access, and more

---

## Modeling Approach

- Data split: 80% training / 20% testing
- Preprocessing with pipelines:
  - Missing value imputation
  - Standard scaling
  - One-hot encoding
  - Ordinal encoding
  - Custom transformer for absence aggregation
- Feature sets compared:
  - ✅ With `G1` and `G2`
  - ❌ Without `G1` and `G2` (early prediction scenario)

---

## Models Evaluated

- Linear Regression
- Support Vector Regression (SVR)
- Lasso Regression
- GridSearchCV used for SVR hyperparameter tuning

---

## Results

| Model         | Features Used      | RMSE | R²   |
|---------------|--------------------|------|------|
| SVR (best)    | G1, G2 included    | ~1.86 | High |
| SVR (best)    | G1, G2 excluded    | ~4.45 | Lower |

- G1 and G2 are highly predictive of G3
- Without midterm grades, SVR generalizes better than linear models
- Residual plots show reasonably accurate predictions with few outliers

---

## Files
```
  student_grade_prediction/ 
  ├── ml_student_grade_prediction.ipynb 
  ├── student-mat.csv 
  └── README.md
```

---

## How to Run

1. Install requirements: `pandas`, `numpy`, `matplotlib`, `seaborn`, `scikit-learn`
2. Place `student-mat.csv` in the same folder as the notebook
3. Run `ml_student_grade_prediction.ipynb` cell-by-cell
4. Toggle `drop_grades=True` or `False` in the transformer to switch feature sets

---

## Future Enhancements

- Test with ensemble models (e.g., Random Forest, Gradient Boosting)
- Add explainability with SHAP values
- Deploy as a web app using Streamlit

---


