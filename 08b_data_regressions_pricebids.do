******Generate Regression Data Set
clear
set more off
cd "$dirpath/Final"
gen year=0
save regressions_price.dta, replace

****Merge monthly datasets for firm 1
forvalues y = 2017(1)2020 {
forvalues m = 1(1)12 {
clear
cd "$dirpath/Day-Ahead/Monthly"
use firm1_`y'_`m'.dta
drop if missing("name")
*add relevant intraday market data variables
cd "$dirpath/Intraday/Monthly"
merge 1:1 year month day hour unit using firm1_id_`y'_`m'.dta
drop if _merge==2
drop _merge
*drop this line later after cleaning intraday data
drop mg_quantity* mg_price*
drop if plant_type!="Solar PV"
*add market prices
cd "$dirpath/Market-Data/Prepared"
merge m:1 year month day hour using prices.dta
drop if _merge==2
keep year month day hour unit owner name plant_type pbid_max pbid_max_a mg_price_da2 /// 
q_total_supply_unit_a supply_unit_max q_total_supply_unit_id_* q_total_demand_unit_id_* ///
pbid_id_1_a_max_D pbid_id_2_a_max_D pbid_id_3_a_max_D pbid_id_4_a_max_D pbid_id_5_a_max_D ///
 pbid_id_6_a_max_D pbid_id_1_a_max_S pbid_id_2_a_max_S pbid_id_3_a_max_S pbid_id_4_a_max_S /// 
 pbid_id_5_a_max_S pbid_id_6_a_max_S pbid_id_1_S_max pbid_id_2_S_max pbid_id_3_S_max ///
 pbid_id_4_S_max  pbid_id_5_S_max pbid_id_6_S_max supply_unit_id_1_max supply_unit_id_2_max /// 
 supply_unit_id_3_max supply_unit_id_4_max supply_unit_id_5_max supply_unit_id_6_max /// 
 mg_price_id2_*  mg_quant* gasprice co2price
 
*generate hourly revenues / costs per unit
replace q_total_supply_unit_a=0 if missing(q_total_supply_unit_a)
gen da_rev_unit=q_total_supply_unit_a*mg_price_da
forvalues i=1(1)6{
	replace q_total_supply_unit_id_`i'=0 if missing(q_total_supply_unit_id_`i')
	replace q_total_demand_unit_id_`i'=0 if missing(q_total_demand_unit_id_`i')
	replace mg_price_id2_`i'=0 if missing(mg_price_id2_`i')
} 
gen id_rev_unit=q_total_supply_unit_id_1*mg_price_id2_1 + ///
q_total_supply_unit_id_2*mg_price_id2_2 + ///
 q_total_supply_unit_id_3*mg_price_id2_3 + ///
q_total_supply_unit_id_4*mg_price_id2_4 + /// 
q_total_supply_unit_id_5*mg_price_id2_5 + ///
q_total_supply_unit_id_6*mg_price_id2_6
gen id_costs_unit=q_total_demand_unit_id_1*mg_price_id2_1 + ///
q_total_demand_unit_id_2*mg_price_id2_2 + /// 
q_total_demand_unit_id_3*mg_price_id2_3 + ///
q_total_demand_unit_id_4*mg_price_id2_4 + /// 
q_total_demand_unit_id_5*mg_price_id2_5 + ///
q_total_demand_unit_id_6*mg_price_id2_6

egen q_total_supply_unit_id=rowtotal(q_total_supply_unit_id_*) 
egen q_total_demand_unit_id=rowtotal(q_total_demand_unit_id_*) 
egen q_total_mg_id=rowtotal(mg_quantity_id*) 

*generate maximum price bids and prices ID
egen pbid_id_a_max_D = rmax(pbid_id_1_a_max_D pbid_id_2_a_max_D ///
pbid_id_3_a_max_D pbid_id_4_a_max_D pbid_id_5_a_max_D pbid_id_6_a_max_D)
egen pbid_id_a_max_S = rmax(pbid_id_1_a_max_S pbid_id_2_a_max_S ///
pbid_id_3_a_max_S pbid_id_4_a_max_S pbid_id_5_a_max_S pbid_id_6_a_max_S)
egen pbid_id_max_S = rmax(pbid_id_1_S_max pbid_id_2_S_max pbid_id_3_S_max ///
 pbid_id_4_S_max  pbid_id_5_S_max pbid_id_6_S_max)
egen mg_price_id_max = rmax(mg_price_id*)
 
cd "$dirpath/Final"
append using regressions_price.dta, force
save regressions_price.dta, replace
sleep 10000
}
}

****Add controls
clear 
cd "$dirpath/Final"
use regressions_price.dta

gen date=mdy(month, day, year)
format date %td
gen date_hour=dhms(date,hour,mm(0),ss(0))
format date_hour %tc

*ENTSO-E data
cd "$dirpath/Market-Data/Prepared"
merge m:1 year month day hour using actual_gen.dta 
drop if _merge==1
drop if _merge==2
drop _merge

merge m:1 year month day hour using load.dta 
drop if _merge==2
drop _merge

merge m:1  year month day hour using regen_forecast.dta 
drop if _merge==2
drop _merge

merge m:1 year month day hour using imbalance.dta 
drop if _merge==2
drop _merge

*ID forecast available from 13.2.2018 on only -> replace by actual generation
replace solar_fc_ID=solar if missing(solar_fc_ID)
replace wind_fc_ID=wind if missing(wind_fc_ID)

*generate relative forecast errors in %
gen solar_fc_error=(solar_fc_DA - solar_fc_ID) / solar_fc_ID
gen wind_fc_error=(wind_fc_DA - wind_fc_ID)  / wind_fc_ID
gen load_fc_error=(load_fc_DA-load_ACT)  / load_ACT

*generate DA forecast of solar and wind share in %
gen solar_share_fc=solar_fc_DA/load_fc_DA *100
gen wind_share_fc=wind_fc_DA/load_fc_DA *100

*generate share of hourly load of yearly maximum load in %
bysort year: egen load_max=max(load_ACT) 
gen load_share=load_ACT/load_max*100
gen load_share_fc=load_fc_DA/load_max*100

*generate hourly shares of production 
gen hydro=runofriver+reservoir
gen coal=hardcoal+lignite+coal_gas
replace other=other_re+other+biomass+waste
foreach var in solar wind oil coal gas nuclear hydro other {
	gen `var'_share=`var'/load_ACT *100
}
forvalues i=1(1)6{
	replace mg_price_id2_`i'=. if mg_price_id2_`i'==0
}

*drop irrelevant variables
drop biomass lignite coal_gas gas hardcoal oil peat pumpedhydro geothermal runofriver reservoir hydro marine nuclear gas coal other other_re solar waste wind thermal_gen other_gen re_gen gen solar_fc_DA solar_fc_ID solar_fc_C wind_fc_DA wind_fc_ID wind_fc_C imbalance_price_pos imbalance_price_neg load_max

cd "$dirpath/Final"
save regressions.dta, replace

*time dummies
gen quarter = 1 if month < 4
replace quarter = 2 if month < 7 & month > 3
replace quarter = 3 if month < 10 & month > 6
replace quarter = 4 if month > 9

egen ym = group(year month)
egen ymd = group(year month day)
egen yq = group(year quarter)

gen week=wofd(date)
format week %tw

gen summer = 0
gen spring = 0	
gen winter = 0
replace summer = 1 if month == 7 | month == 8 | month == 9
replace spring = 1 if month == 4 | month == 5 | month == 6
replace winter = 1 if month == 1 | month == 2 | month == 3

gen weekd=dow( mdy( month, day, year) )
gen weekend = 1 if weekd == 6 | weekd == 0
replace weekend = 0 if weekend == .
gen weekdays = 0
replace weekdays = 1 if weekend == 1

gen afternoon=0
replace afternoon=1 if hour>12

gen pbid_dummy=0
replace pbid_dummy=1 if pbid_max>0

gen diff_dummy=0
replace diff_dummy=1 if mg_price_da<mg_price_id_max

drop mg_price_id_max
egen mg_price_id_max=rmax(mg_price_id2_*)
egen mg_price_id_mean=rmean(mg_price_id2*)
gen diff_p_id_da=mg_price_id_max-mg_price_da2
gen diff_p_id_da_m=mg_price_id_mean-mg_price_da2


*clean data
replace q_total_mg_id=q_total_mg_id/1000
replace load_ACT=load_ACT/1000
replace load_fc_DA=load_fc_DA/1000

drop if q_total_mg_id==0
drop if missing(mg_price_id_max)

drop if missing(mg_price_id_max)
keep unit date_hour hour year month day name pbid_max pbid_max_a diff_p_id_da q_total_mg_id mg_price_id_max diff_p_id_da_m mg_price_id_mean co2price gasprice load_fc_DA load_ACT solar_fc_error wind_fc_error load_fc_error solar_share_fc wind_share_fc load_share load_share_fc solar_share wind_share oil_share coal_share gas_share nuclear_share hydro_share other_share quarter ym ymd yq week summer spring winter weekd weekend weekdays afternoon pbid_dummy diff_dummy q_total_supply_unit_id q_total_supply_unit_a pbid_id_1_S_max pbid_id_2_S_max pbid_id_3_S_max pbid_id_4_S_max pbid_id_5_S_max pbid_id_6_S_max

order unit date_hour hour year month day name pbid_max pbid_max_a diff_p_id_da q_total_mg_id mg_price_id_max diff_p_id_da_m mg_price_id_mean co2price gasprice load_fc_DA load_ACT solar_fc_error wind_fc_error load_fc_error solar_share_fc wind_share_fc load_share load_share_fc solar_share wind_share oil_share coal_share gas_share nuclear_share hydro_share other_share quarter ym ymd yq week summer spring winter weekd weekend weekdays afternoon pbid_dummy diff_dummy q_total_supply_unit_id q_total_supply_unit_a pbid_id_1_S_max pbid_id_2_S_max pbid_id_3_S_max pbid_id_4_S_max pbid_id_5_S_max pbid_id_6_S_maxcd "$dirpath/Final"
save regressions_price.dta, replace
