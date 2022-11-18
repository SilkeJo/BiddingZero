********Master Do-File********

***Silke Johanndeiter & Valentin Bertsch***
***Bidding zero? An analysis of solar power plants' price bids
* in the electricity day-ahead market**

clear
*Set your own path
global dirpath="C:\Users\JOHANNS\EnBW AG\C-UE C-UM - Dokumente\Team\Silke\Stata\Spain\for submission"

**1) Create Datasets
* do "$dirpath/01_data_units.do"
* do "$dirpath/02_data_market.do"
**Running the following do-files rawdata requires
**(URL in ReadMe of respective folders) or requested from author
* do "$dirpath/03_data_da_solar_pbids.do"
* do "$dirpath/04_data_da_6firms.do"
* do "$dirpath/05_data_da_firm1.do"
* do "$dirpath/06_data_id_firm1.do"
* do "$dirpath/07_data_intraday_monthly_agg.do"
* do "$dirpath/08_data_regressions.do"

**2) Create Graphs and Tables
do "$dirpath/09_descriptives.do"

**3) Conduct Regression Analyses
do "$dirpath/10_regressions.do"


