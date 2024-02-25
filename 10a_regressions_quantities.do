*******Regression analysis
clear
set more off
global dirpath="C:/Users/JOHANNS/EnBW AG/C-UE C-UM - Dokumente/Team/Silke/Stata/Spain/Review/Data"

clear
cd "$dirpath/Final"
log using regressions_quantitites_log, replace
use regressions_quant.dta
*Note: due to its large file size, I split this dataset in this repo
*to get it from the repo you need to: merge 1:1 year month day hour regressions_quant_1.dta using regressions_quant_2.dta 
encode owner, gen(firm)
xtset firm date_hour 
encode unit, gen(unitcode)

*fixed effects
xi i.month i.quarter i.hour i.date 
global fe ="_Imonth*"
global fe2 ="_Imonth* _Ihour*"

bysort date_hour: gen unique=_n

*labels
label var solar_share_fc "Day-ahead forecast solar market share" 
label var wind_share_fc "Day-ahead forecast wind market share" 
label var afternoon "Afternoon Dummy" 
label var weekend "Weekend Dummy" 
label var diff_p "Price Difference (Diff)"
label var pbid_dummy "Firm dummy (FD)"
gen diff_p_x_dummy=diff_p*pbid_dummy
label var diff_p_x_dummy "Diff x FD"


******0) Prediction of delta_p (difference in day-ahead and intraday market price) 
qui reg diff_p solar_share_fc wind_share_fc load_fc_DA _Idate* afternoon /// 
if unique==1, robust cluster(date)
predict diff_p_hat

gen diff_p_hat_x_dummy=diff_p_hat*pbid_dummy
label var diff_p_hat_x_dummy "Diff_Hat x FD"

cd "$dirpath/Final/RegressionResults"
qui asdoc reg diff_p solar_share_fc wind_share_fc load_fc_DA i.date afternoon if unique==1, robust cluster(date), add(Daily FE, Yes) drop(i.date) dec(3) title(Diff_P_Hat) label nest replace save(Pbid_hat.doc)


******1) Difference in capacity offered and sold day-ahead 
*Short regression table
cd "$dirpath/Final/RegressionResults"
qui asdoc reg lnqda2 diff_p pbid_dummy diff_p_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust, add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm) dec(3) title(q_da) label nest replace save(capacities.doc)

*Complete regression table
qui asdoc reg lnqda2 diff_p pbid_dummy diff_p_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust, add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(i.month i.hour i.firm) dec(3) title(q_da) label nest replace save(capacities_all.doc)

qui reg lnqda2 c.diff_p_hat##pbid_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust

*Short regression table
qui asdoc reg lnqda2 diff_p_hat pbid_dummy diff_p_hat_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm) dec(3) title(q_da) label nest save(capacities.doc)

*Complete regression table
qui asdoc reg lnqda2 diff_p_hat pbid_dummy diff_p_hat_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust, add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(i.month i.hour i.firm) dec(3) title(q_da) label nest save(capacities_all.doc)


******2) Capacity sold intraday
qui reg lnqids c.diff_p##pbid_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust

*Short regression table
qui asdoc reg lnqids diff_p pbid_dummy diff_p_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust, add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm) dec(3) title(q_ids) label nest  save(capacities.doc)

*Complete regression table
qui asdoc reg lnqids diff_p pbid_dummy diff_p_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust, add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(i.month i.hour i.firm) dec(3) title(q_da) label nest save(capacities_all.doc)

qui reg lnqids c.diff_p_hat##pbid_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust

*Short regression table
qui asdoc reg lnqids diff_p_hat pbid_dummy diff_p_hat_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust, add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm) dec(3) title(q_da) label nest save(capacities.doc)

*Complete regression table
qui asdoc reg lnqids diff_p_hat pbid_dummy diff_p_hat_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust, add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(i.month i.hour i.firm) dec(3) title(q_da) label nest save(capacities_all.doc)


******3) Robustness Checks
******Capacity bought intraday
qui reg lnqidb c.diff_p##pbid_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust

qui reg lnqidb c.diff_p_hat##pbid_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust

qui asdoc reg lnqidb diff_p pbid_dummy diff_p_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust, add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(i.month i.hour i.firm) dec(3) title(q_da) label replace nest save(robustness_idb.doc)

qui asdoc reg lnqidb diff_p_hat pbid_dummy diff_p_hat_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.month i.hour i.firm, robust, add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(i.month i.hour i.firm) dec(3) title(q_da) label nest save(robustness_idb.doc)


*More controls
qui asdoc reg lnqda2 diff_p pbid_dummy diff_p_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice oil_share gas_share coal_share other_share i.month i.hour i.firm, robust, add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(i.month i.hour i.firm) dec(3) title(q_da) label nest replace nest save(robustness_mc.doc)

qui asdoc reg lnqda2 diff_p_hat pbid_dummy diff_p_hat_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice oil_share gas_share coal_share other_share i.month i.hour i.firm, robust, add(MonthlyFE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(i.month i.hour i.firm) dec(3) title(q_da) label save(robustness_mc.doc)

qui asdoc reg lnqids diff_p pbid_dummy diff_p_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice oil_share gas_share coal_share other_share i.month i.hour i.firm, robust, add(Monthly FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(i.month i.hour i.firm) dec(3) title(q_da) label save(robustness_mc.doc)

qui asdoc reg lnqids diff_p_hat pbid_dummy diff_p_hat_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice oil_share gas_share coal_share other_share i.month i.hour i.firm, robust, add(Monthly, FE, Yes, Hourly FE, Yes, Firm FE, Yes) drop(i.month i.hour i.firm) dec(3) title(q_da) label save(robustness_mc.doc)


*Different fixed effects 
qui asdoc reg lnqda2 diff_p pbid_dummy diff_p_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.quarter i.date  i.firm, robust, add(Quarterly FE, Yes, Daily FE, Yes, Firm FE, Yes) drop(i.quarter i.date i.firm) dec(3) title(q_da) label nest replace save(robustness_fe.doc)

qui asdoc reg lnqda2 diff_p_hat pbid_dummy diff_p_hat_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.quarter i.date  i.firm, robust, add(Quarterly FE, Yes, Daily FE, Yes, Firm FE, Yes) drop(i.quarter i.date i.firm) dec(3) title(q_da) label nest save(robustness_fe.doc)

qui asdoc reg lnqids diff_p pbid_dummy diff_p_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.quarter i.date  i.firm, robust, add(Quarterly FE, Yes, Daily FE, Yes, Firm FE, Yes) drop(i.quarter i.date i.firm) dec(3) title(q_da) label nest save(robustness_fe.doc)

qui asdoc reg lnqids diff_p_hat pbid_dummy diff_p_hat_x_dummy solar_share wind_share hydro_share load_ACT solar_fc_error wind_fc_error load_fc_error co2price gasprice i.quarter i.date  i.firm, robust, add(Quarterly FE, Yes, Daily FE, Yes, Firm FE, Yes) drop(i.quarter i.date i.firm) dec(3) title(q_da) label nest save(robustness_fe.doc)
log close

