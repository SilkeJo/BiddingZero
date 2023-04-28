******Generate Data Set for Regression for Quantities
clear
set more off
global dirpath="C:/Users/JOHANNS/EnBW AG/C-UE C-UM - Dokumente/Team/Silke/Stata/Spain/Review/Data"

cd "$dirpath/Final"
gen year=0
save regressions_quant.dta, replace

***Merge day-ahead and intraday market data of firms owning solar power
clear
cd "$dirpath/Final"
use solar_da.dta
*add info on plant_types (NOTE TO ME: maybe corerct it in the DA data)
cd "$dirpath/Units"
merge m:1 unit using unitdata1.dta
drop if _merge==2
drop _merge
keep year month day hour unit owner mg_price q_total_offered_da q_total_sold_da q_total_offered_da_sol q_total_sold_da_sol q_total_bought_da q_total_demand_da pbid_max_sol pbid_max_a_sol plant_type
cd "$dirpath/Final"
save solar_da.dta, replace
*merge intraday market data
merge 1:1 year month day hour owner using solar_id.dta
drop if _merge==2
drop _merge
*generate sums over all 6 sessions
egen q_total_sold_id=rowtotal(q_total_sold_id_*) 
egen q_total_bought_id=rowtotal(q_total_bought_id_*) 
egen q_total_offered_id=rowtotal(q_total_offered_id_*) 
egen q_total_demand_id=rowtotal(q_total_demand_id_*) 
drop q_total_sold_id_* q_total_bought_id_* q_total_offered_id_* q_total_demand_id_* solar wind

***Add markt data as controls
*add market prices
cd "C:\Users\JOHANNS\EnBW AG\C-UE C-UM - Dokumente\Team\Silke\Stata\Spain\Data/Market-Data/Prepared"
merge m:1 year month day hour using prices.dta
drop if _merge!=3
drop _merge

egen mg_price_id_max = rmax(mg_price_id2*)
egen mg_price_id_mean = rmean(mg_price_id2*)
egen mg_quantity_id=rsum(mg_quantity*)

drop mean_price*
drop if missing(mg_price_id_max)

***Add controls
*ENTSO-E data
cd "C:\Users\JOHANNS\EnBW AG\C-UE C-UM - Dokumente\Team\Silke\Stata\Spain\Data/Market-Data/Prepared"
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

*ID 6 DA forecast available from 13.2.2018 on only -> replace by actual generation
replace solar_fc_ID=solar if missing(solar_fc_ID)
replace wind_fc_ID=wind if missing(wind_fc_ID)
replace solar_fc_DA=solar if missing(solar_fc_DA)
replace wind_fc_DA=wind if missing(wind_fc_DA)

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

*convert to GWh
replace load_ACT=load_ACT/1000
replace load_fc_DA=load_fc_DA/1000
replace solar_fc_DA=solar_fc_DA/1000
replace wind_fc_DA=wind_fc_DA/1000


*drop irrelevant variables
drop biomass lignite coal_gas gas hardcoal oil peat pumpedhydro geothermal runofriver reservoir hydro marine nuclear gas coal other other_re solar waste wind thermal_gen other_gen re_gen gen solar_fc_ID solar_fc_C wind_fc_ID wind_fc_C load_max 

***generate time variables and dummies
gen date=mdy(month, day, year)
format date %td
gen date_hour=dhms(date,hour,mm(0),ss(0))
format date_hour %tc

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

***Data Cleaning
*consider only hours where solar can really be produced
drop if hour<8
drop if hour>22

*create more balanced panel 
sort date_hour
bysort owner: gen count=_n
bysort owner: egen no=max(count)
drop if no<4371  
bysort owner: egen minmonth=min(month)
bysort owner: egen maxmonth=max(month)
drop if minmonth!=1
drop if maxmonth!=12

*ensure firms in sample sell sufficient solar energy
gen q_total_solar_da=q_total_sold_da_sol/q_total_sold_da
bysort owner: egen minsol=min(q_total_solar_da)
bysort owner: egen maxsol=max(q_total_solar_da)
gen help=1
bysort owner: egen nosol=total(help) if missing(q_total_solar_da)
drop if maxsol<0.1
gen diff=no-nosol
drop if diff<171
drop diff

bysort year month day hour: egen solar_prod=total(q_total_sold_da_sol)
gen solar_prod_act=solar_share*load_ACT*10
gen share=solar_prod/solar_prod_act
drop if share>1

*drop firms that are retailers rather than suppliers (demand_share_min>1)
gen demand_share=q_total_bought_da/q_total_sold_da
*note: if missing -> no sales
drop if missing(demand_share)
bysort owner: egen demand_share_min=min(demand_share)
drop if demand_share_min>1

*clean extreme values
gen offer_sold=(q_total_sold_da-q_total_bought_da)/(q_total_offered_da-q_total_demand_da)*100
gen offer_sold2=(q_total_sold_da)/(q_total_offered_da)*100

gen id_da=(q_total_sold_id-q_total_bought_id)/q_total_offered_da*100
gen id_da_bought=q_total_bought_id/q_total_offered_da*100
gen id_da_sold=q_total_sold_id/q_total_offered_da*100

*clean extreme values
sum offer_sold, det
sum id_da_*, det

drop if id_da_sold>999
drop if id_da_bought>999
drop if offer_sold<-510| offer_sold>170


*graphical check: 
*sort date_hour
*twoway line q_total_sold_da date_hour, by(owner)

***Generate dependent variables
gen diff_q_da=q_total_offered_da-q_total_sold_da
gen diff_q_da2=(q_total_offered_da-q_total_demand_da)-(q_total_sold_da-q_total_bought_da)

*to deal with 0 for logs
foreach var in diff_q_da2 diff_q_da q_total_sold_id q_total_bought_id{
	replace `var'=`var'+1
}

gen lnqda=ln(diff_q_da)
gen lnqda2=ln(diff_q_da2)
gen lnqids=ln(q_total_sold_id)
gen lnqidb=ln(q_total_bought_id)

*sum lnq*

***Generate explanatory variables
*Dummy, if firms ever submit price bid > 10 for solar power plants
bysort owner: egen pbid_max_a=max(pbid_max_a_sol)
bysort owner: egen pbid_max=max(pbid_max_sol)
*drop if missing(pbid_max_a)
gen pbid_dummy=0
replace pbid_dummy=1 if pbid_max_a>10
*note: no difference if dummy defined by pbid_max_a or pbid_max
*gen pbid_dummy2=0
*replace pbid_dummy2=1 if pbid_max>10
*gen diff=pbid_dummy-pbid_dummy2

*Dummy, if Max ID price > DA price
gen diff_dummy=0
replace diff_dummy=1 if mg_price_da2<mg_price_id_max

*Difference in Max Id price and DA price
gen diff_p=mg_price_id_max-mg_price_da2
gen diff_p2=mg_price_id_mean-mg_price_da2
*clean extreme values (P5 and P95)
sum diff_p, det
drop if diff_p>5.95
drop if diff_p<-1

*Dummies characterizing firms
gen solar=0
replace solar=1 if minsol==1

bysort owner: egen q_total_sold_da_max=max(q_total_sold_da)
gen small=0
replace small=1 if q_total_sold_da_max<5
gen big=0
replace big=1 if q_total_sold_da_max>2000
gen retail=0
replace retail=1 if demand_share_min>0

***Keep only relevant variables 
drop count no minmonth maxmonth q_total_solar_da minsol maxsol help nosol solar_prod solar_prod_act share demand_share demand_share_min q_total_sold_da_max

cd "$dirpath/Final"
save regressions_quant.dta, replace