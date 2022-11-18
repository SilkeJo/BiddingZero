*******Regression analysis
clear
set more off

clear
cd "$dirpath/Final"
log using regressions_log, replace
use regressions.dta
tsset date_hour

*fixed effects
xi i.hour  i.month*i.year i.month i.year i.ymd i.yq i.quarter
global fe = "_Iyq* _Ihour*"
global fe2 = "_Iyq*"
global fe3 = "_Iyear*"
global fe4 = "_Iyear* _Imonth*"
global fe5 = "_Iyear*  _Ihour*"
global fe6 = "_Iyear* _Imonth*  _Ihour*"

*Lags Controls
sort hour year month day 
foreach var in solar_share wind_share hydro_share gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice  {
by hour: gen lag_`var'=`var'[_n-1]
by hour: gen lag2_`var'=`var'[_n-2]
by hour: gen lag3_`var'=`var'[_n-3]
by hour: gen lag4_`var'=`var'[_n-4]
by hour: gen lag5_`var'=`var'[_n-5]	
}

global lag_controls = "lag_*"
global lags_controls = "lag*"

*Lags Dependent and Explanatory Variables
sort hour year month day 
foreach var in diff_p_id_da q_total_mg_id mg_price_id_max {
by hour: gen `var'_lag=`var'[_n-1]
by hour: gen `var'_lag2=`var'[_n-2]
by hour: gen `var'_lag3=`var'[_n-3]
by hour: gen `var'_lag4=`var'[_n-4]
by hour: gen `var'_lag5=`var'[_n-5]	
}

global expl_lag = "diff_p_id_da_lag  q_total_mg_id_lag"
global expl_lags = "diff_p_id_da_lag*  q_total_mg_id_lag*"

*Lags instruments
global instr_lag="lag_load_ACT lag_solar_share lag_wind_share lag_hydro_share lag_co2price lag_gasprice"

*First differences
sort date_hour
foreach var in pbid_max mg_price_id_max solar_share wind_share hydro_share gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice {
	gen d`var'=`var'-`var'[_n-1]
}

*********1) When to submit
***(1) IV PF
ivregress 2sls pbid_dummy (diff_p_id_da q_total_mg_id = afternoon weekend) solar_share wind_share hydro_share gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe2, robust 
cd "$dirpath/Final/RegressionResults"
*outreg2 using 1st_step_results.doc, replace ctitle(IV PF) addstat("Chi2", e(chi2))

***(2) IV 1 Lag
ivregress 2sls pbid_dummy (diff_p_id_da q_total_mg_id = afternoon weekend) $lag_controls $fe2, robust
*outreg2 using 1st_step_results.doc, append ctitle(IV 1 Lag) addstat("Chi2", e(chi2))

***(3) IV Probit PF
ivprobit pbid_dummy (diff_p_id_da q_total_mg_id = afternoon weekend)  solar_share wind_share hydro_share gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe2
outreg2 using 1st_step_results.doc, append ctitle(IV Probit PF) addstat("Chi2", e(chi2))
*Average marginal effects (takes long to be executed!)
margins, dydx(diff_p_id_da q_total_mg_id) pred(pr)

***(4) IV Probit 1 Lag
ivprobit pbid_dummy (diff_p_id_da q_total_mg_id = afternoon weekend) $lag_controls $fe2
*outreg2 using 1st_step_results.doc, append ctitle(IV Probit 1 Lag)  addstat("Chi2", e(chi2))
*Average marginal effects (takes long to be executed!)
margins, dydx(diff_p_id_da q_total_mg_id) pred(pr)

***Durbin-Wu-Hausman test 
reg diff_p_id_da weekend afternoon solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error gas_share coal_share co2price gasprice $fe, robust
predict uhat, residuals

reg q_total_mg_id weekend afternoon solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error gas_share coal_share co2price gasprice $fe, robust
predict uhat2, residuals

reg pbid_dummy diff_p_id_da q_total_mg_id solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error gas_share coal_share co2price gasprice uhat uhat2 $fe, robust
*-> both uhat's betas are significant

*********Appendix
*****First stage regressions
***(1) IV PF
reg diff_p_id_da afternoon weekend solar_share wind_share hydro_share gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe2, robust 
cd "$dirpath/Final/RegressionResults"
*outreg2 using 1st_step_firststage.doc, replace ctitle(IV PF Diff) addstat("F-Test", e(F))

reg q_total_mg_id afternoon weekend solar_share wind_share hydro_share gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe2, robust 
*outreg2 using 1st_step_firststage.doc, append ctitle(IV PF Liq) addstat("F-Test", e(F))

***(2) IV Lag
reg diff_p_id_da afternoon weekend $lag_controls $fe2, robust
cd "$dirpath/Final/RegressionResults"
*outreg2 using 1st_step_firststage.doc, append ctitle(IV 1 Lag Diff) addstat("F-Test", e(F))

reg q_total_mg_id afternoon weekend $lag_controls $fe2, robust
cd "$dirpath/Final/RegressionResults"
*outreg2 using 1st_step_firststage.doc, append ctitle(IV 1 Lag Liq) addstat("F-Test", e(F))

*****Robustness Checks
***OLS (linear probability model) & Probit without instruments, additional: Logit model
***(1) OLS PF
reg pbid_dummy diff_p_id_da q_total_mg_id solar_share wind_share hydro_share gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe2, robust
cd "$dirpath/Final/RegressionResults"
*outreg2 using 1st_step_robust.doc, replace ctitle(OLS PF) addstat("F-Test", e(F))

****Probit
***(2) Probit PF
probit pbid_dummy diff_p_id_da q_total_mg_id solar_share wind_share hydro_share  gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe2 afternoon weekend
*outreg2 using 1st_step_robust.doc, append ctitle(Probit PF) addstat("Chi2", e(chi2))

****Logit
***(3) Logit PF
logit pbid_dummy diff_p_id_da q_total_mg_id solar_share wind_share hydro_share  gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe2 afternoon weekend
*outreg2 using 1st_step_robust.doc, append ctitle(Logit PF) addstat("Chi2", e(chi2))

*****IV Robustness
***More Lags
***(1) IV 5 Lags
ivregress 2sls pbid_dummy (diff_p_id_da q_total_mg_id = afternoon weekend) $lags_controls $fe2, robust
*outreg2 using 1st_step_robust2.doc, replace ctitle(IV 5 Lags) 

***Fewer Controls and FE
**(2) IV PF
ivregress 2sls pbid_dummy (diff_p_id_da q_total_mg_id = afternoon weekend) solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe3, robust 
*outreg2 using 1st_step_robust2.doc, append ctitle(IV PF small) addstat("Chi2", e(chi2))
*estat firststage
*estat overid

***More Controls and FE
**(3) IV PF
ivregress 2sls pbid_dummy (diff_p_id_da q_total_mg_id = afternoon weekend) solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice  oil_share gas_share coal_share other_share $fe4, robust 
*outreg2 using 1st_step_robust2.doc, append ctitle(IV PF large) addstat("Chi2", e(chi2))
*estat firststage
*estat overid

****Mean ID price instead of max ID price 
***(1) IV PF
ivregress 2sls pbid_dummy (diff_p_id_da_m q_total_mg_id = afternoon weekend) solar_share wind_share hydro_share gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe2, robust 


****IV Probit Robustness
***More Lags
***(1) IV 5 Lags
ivprobit pbid_dummy (diff_p_id_da q_total_mg_id = afternoon weekend) $lags_controls $fe2
*outreg2 using 1st_step_robust3.doc, replace ctitle(IV Probit 5 Lags) addstat("Chi2", e(chi2))

***Fewer Controls and FE
***(3) IV Probit PF
ivprobit pbid_dummy (diff_p_id_da q_total_mg_id = afternoon weekend) load_ACT solar_share wind_share hydro_share co2price gasprice wind_fc_error solar_fc_error load_fc_error $fe3
*outreg2 using 1st_step_robust3.doc, append ctitle(IV Probit PF small) addstat("Chi2", e(chi2))
*estat firststage
*estat overid

**More Controls and FE
***(4) IV Probit PF
ivprobit pbid_dummy (diff_p_id_da_m q_total_mg_id = afternoon weekend) load_ACT solar_share wind_share hydro_share co2price gasprice wind_fc_error solar_fc_error load_fc_error co2price gasprice oil_share gas_share coal_share other_share $fe4
*outreg2 using 1st_step_robust3.doc, append ctitle(IV Probit PF large) addstat("Chi2", e(chi2))


***********2) What to submit
drop if pbid_max==0

***OLS
***(1) OLS PF
reg pbid_max mg_price_id_max $fe, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_results.doc, replace ctitle(OLS PF) 

***(2) OLS Lags
reg pbid_max mg_price_id_max_lag* $fe, vce(cluster yq)
*outreg2 using 2ndstep_results.doc, append ctitle(OLS 5 Lags) 

**Durwin-Wu-Hausman test 
reg mg_price_id_max load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe, vce(cluster year)
predict uhat5
reg pbid_max mg_price_id_max uhat5 $fe, robust
*-> uhat5 is significant 

***(3) IV PF
ivregress 2sls pbid_max (mg_price_id_max=load_ACT solar_share wind_share hydro_share co2price gasprice) $fe, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_results.doc, append ctitle(IV PF) addstat("Chi²", e(chi2))

***(4) IV Lags
ivregress 2sls pbid_max (mg_price_id_max=$instr_lag) $fe, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_results.doc, append ctitle(IV 1 Lag) addstat("Chi²", e(chi2))

*********Appendix
*****First stage regressions
reg mg_price_id_max load_ACT solar_share wind_share hydro_share co2price gasprice $fe, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2nd_step_firststage.doc, replace ctitle(IV PF first stage) 

reg mg_price_id_max $instr_lag $fe, vce(cluster yq)
*outreg2 using 2nd_step_firststage.doc, append ctitle(IV 1 Lag first stage) 

******Robustness Checks 
***Fewer instruments
***(1) IV PF
ivregress 2sls pbid_max (mg_price_id_max=load_ACT wind_share gasprice) $fe, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_robust.doc, replace ctitle(IV PF small) addstat("Chi²", e(chi2))

***(2) IV Lags
ivregress 2sls pbid_max (mg_price_id_max=lag_load_ACT lag_wind_share lag_gasprice) $fe, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_robust.doc, append ctitle(IV 1 Lag large) addstat("Chi²", e(chi2))

***To do
**More instruments
***(3) IV PF
ivregress 2sls pbid_max (mg_price_id_max=load_ACT solar_share wind_share hydro_share co2price gasprice load_fc_error solar_fc_error wind_fc_error) $fe, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_robust.doc, append ctitle(IV PF) addstat("Chi²", e(chi2))

***(4) IV Lags
ivregress 2sls pbid_max (mg_price_id_max=lag_load_ACT lag_solar_share lag_wind_share lag_hydro_share lag_co2price lag_gasprice lag_load_fc_error lag_solar_fc_error lag_wind_fc_error) $fe, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_robust.doc, append ctitle(IV 1 Lag) addstat("Chi²", e(chi2))

***OLS with controls, different fixed effects and first difference
***(1) OLS PF
reg pbid_max mg_price_id_max  $fe5, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_robust2.doc, replace ctitle(OLS PF a) 

reg pbid_max mg_price_id_max  $fe6, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_robust2.doc, append ctitle(OLS PF b) 

reg pbid_max mg_price_id_max solar_share wind_share hydro_share gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_robust2.doc, append ctitle(OLS PF c) 

reg dpbid_max dmg_price_id_max $fe, vce(cluster yq)
*outreg2 using 2ndstep_robust2.doc, append ctitle(OLS PF d) 

***OLS Lag with controls and different fixed effects
reg pbid_max mg_price_id_max_lag*  $fe5, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_robust3.doc, replace ctitle(OLS 5 Lags a) 

reg pbid_max mg_price_id_max_lag*  $fe6, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_robust3.doc, append ctitle(OLS 5 Lags b) 

reg pbid_max mg_price_id_max_lag* solar_share wind_share hydro_share gas_share coal_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice $fe, vce(cluster yq)
cd "$dirpath/Final/RegressionResults"
*outreg2 using 2ndstep_robust3.doc, append ctitle(OLS 5 Lags c) 

log close
