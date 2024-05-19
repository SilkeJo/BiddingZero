*****Graph, tables and descriptives
clear
set more off

*General information on quantity regression dataset for the text
clear 
cd "$dirpath/Final"
use regressions_quant.dta
*no of firms
bysort owner: gen count=_n 
count if count==1
count if count==1 & pbid_dummy==0
*no of solar power units
bysort unit: gen count2=_n if strpos(plant_type,"Solar")==1
count if count2==1

bysort date_hour: gen uniquehour=_n 
sum solar_share if uniquehour==1

bysort year month day hour: egen solar_prod=total(q_total_sold_da_sol)
gen solar_prod_act=solar_share*load_ACT*10
gen share=solar_prod/solar_prod_act
sum share if uniquehour==1


****Figures and Tables
*Figure 2: weekly market data
clear 
cd "$dirpath/Final"
use allmarketdata.dta, replace
drop if year>2020
drop if year<2020

egen mg_price_id_max=rmean(mg_price_id2*)

collapse (mean) mg_price_da2 mg_price_id2* mg_price_id_max mg_quant* ///
(sum) coal gas biomass oil hydro pumpedhydro nuclear /// 
other other_re solar waste wind gen load_ACT, by(week)

rename coal Coal
gen Gas = Coal + gas
gen Oil = Gas + oil
gen Nuclear = Oil + nuclear
gen Biomass = Nuclear + biomass
gen Other = Biomass + other
gen Other_RE = Other + other_re
gen Hydro = Other_RE + hydro
gen Waste = Hydro + waste
gen Solar = Waste + solar
gen Wind = Solar + wind
foreach var in Coal Gas Oil Nuclear Biomass Hydro Waste Solar Wind Other Other_RE {
	replace `var'=`var'/1000
}
set scheme s1mono
twoway bar Coal week, bcolor(black) || ///
rbar Coal Gas week, bcolor(sienna) || ///
rbar Gas Oil week, bcolor(brown) || ///
rbar Oil Nuclear week, bcolor(gray) || /// 
rbar Nuclear Biomass week, bcolor(midgreen) || ///
rbar Biomass Other week, bcolor(teal) || /// 
rbar Other Other_RE week, bcolor(dkgreen) || /// 
rbar Other_RE Hydro week, bcolor(navy) || /// 
rbar Hydro Waste week, bcolor(olive_teal) || /// 
rbar Waste Solar week, bcolor(yellow) || /// 
rbar Solar Wind week, bcolor(ltblue) || /// 
line mg_price_da week, yaxis(2) lcolor(red) lpattern(dash dot) || /// 
line mg_price_id_max week, yaxis(2) lcolor(orange) lpattern(dash dot) ///
legend(rows(3) size(small) symxsize(*0.3) label(1 "Coal") label(2 "Gas") ///
label(3 "Oil") label(4 "Nuclear") label(5 "Biomass") /// 
label(6 "Other") label(7 "Other_RE") ///
label(8 "Hydro") label(9 "Waste") ///
label(10 "Solar") label(11 "Wind") ///
label(12 "Day-ahead") label(13 "Intraday (max)")) ///
ytitle("Total weekly generation (GWh)", size(medsmall)) ///
ylabel(,labsize(small)) ysc(titlegap(4) r(0 6500)) ///
ytitle("Average weekly market price (€/MWh)", size(medsmall) axis(2)) ///
ylabel(,labsize(small) axis(2)) ysc(titlegap(2) r(0 52) axis(2)) ///
xtitle("Week", size(medsmall)) tlabel(2020w1(7)2020w52,labsize(small) /// 
format(%tw)) ysc(titlegap(4)) xsc(titlegap(4)) 
*xtitle("Week", size(small)) tlabel(2017w1(26)2020w52,labsize(small) format(%tw)) 
cd "$dirpath/Final/Figures"
graph export Fig2_WeeklyMarketData.png, replace width(1328)
graph close

*Table 1: market prices
clear 
cd "$dirpath/Market-Data/Prepared"
use marketprices.dta, replace
duplicates drop year month day hour, force
drop if year<2020
drop if year>2020
egen mg_price_id_max=rmean(mg_price_id2*)
sum mg_price_da2 mg_price_id2* mg_price_id_max

*Figure 3: Scatter of Market Prices
*clear 
cd "$dirpath/Final"
label var mg_price_da2 "Day-ahead"
label var mg_price_id_max "Max of 6 intraday Sessions"
label var mg_price_id2_1 "Intraday 1"
label var mg_price_id2_2 "Intraday 2"
label var mg_price_id2_3 "Intraday 3"
label var mg_price_id2_4 "Intraday 4"
label var mg_price_id2_5 "Intraday 5"
label var mg_price_id2_6 "Intraday 6"
set scheme s1mono
twoway (scatter mg_price_da2 mg_price_id_max, leg(off) mcolor(ebblue) msize(tiny)) (function x, range(mg_price_da2) n(2), leg(off)), ytitle(Market Price (€/MWh), size(medsmall)) ///
xlabel(0(10)80,labsize(small)) graphregion(color(white))  ///
xtitle("Day-ahead market price (€/MWh)", size(medsmall)) ytitle("Maximum intraday market price (€/MWh)", size(medsmall)) ylabel(0(10)80,labsize(small)) ///
ysc(titlegap(4)) xsc(titlegap(4)) ysize(1) xsize(1)
cd "$dirpath/Final/Figures"
graph export "Fig3_MarketPrices.png", replace width(1328)
graph close


*New Figure 11: correlation with imbalance price
*clear 
cd "$dirpath/Market-Data/Prepared"
merge 1:1 year month day hour using imbalance.dta
drop if _merge!=3
drop _merge
label var mg_price_da2 "Day-ahead"
set scheme s1mono
drop if imbalance_price_pos<-10
twoway (scatter imbalance_price_pos mg_price_id_max, leg(off) mcolor(ebblue) msize(tiny)) (function x, range(mg_price_id_max) n(2), leg(off)), ytitle(Market Price (€/MWh), size(medsmall)) ///
xlabel(0(10)80,labsize(small)) graphregion(color(white))  ///
xtitle("Maximum intraday market price (€/MWh)", size(medsmall)) ytitle("Positive imbalance price (€/MWh)", size(medsmall)) ylabel(0(10)80,labsize(small)) ///
ysc(titlegap(4)) xsc(titlegap(4)) ysize(1) xsize(1)
cd "$dirpath/Final/Figures"
graph export "Fig11_Imbalance.png", replace width(1328)
graph close


*Figure 4: Histogram of solar price bids in our sample
clear 
cd "$dirpath/Final"
use regressions_quant.dta
hist pbid_max_sol, xtitle("Maximum hourly day-ahead price bids for solar (€/MWh)", size(medsmall)) ytitle("Density (%)", size(medsmall)) percent graphregion(fcolor(white)) lcolor(nsvy) fcolor(ebblue) xsize(1.3) ysize(1) width(10) lwidth(0.1) xlabel(,labsize(small)) ylabel(,labsize(small)) ///
 ysc(titlegap(*4)) xsc(titlegap(*4))
cd "$dirpath/Final/Figures"
graph export "Fig4_HistSolarPbids.png", replace width(1328)
graph close

*Figure 5: DA and ID quantities 
clear 
cd "$dirpath/Final/2019"
use regressions_quant.dta

gen pbid_dummy_nice="Max. solar price bid > 0"
replace pbid_dummy_nice="Max. solar price bid = 0" if pbid_dummy==0

gen price_dummy="{&Delta}p{&le}0"
replace price_dummy="{&Delta}p>0" if mg_price_id_max>mg_price_da2

set scheme s1mono
graph bar (mean) offer_sold id_da_sold id_da_bought, over(price_dummy, label(labsize(small))) by(pbid_dummy_nice, subtitle(,size(small))) /// 
yscale(r(0 110)) ylabel(0(20)100, labsize(small)) ytitle("%", size(small)) ///
graphregion(fcolor(white)) bar(1, color(eltblue)) bar(2, color(ebblue)) /// 
 bar(3, color(navy)) /// 
 legend(label (1 "Sales day-ahead relative to net capacity offered day-ahead") /// 
 label (2 "Net capacity sold intraday relative to net capacity sold day-ahead") ///
 label (3 "Net capacity bought intraday relative to net capacity sold day-ahead") ///
 rows(3) size(small)) bgcolor(white) blabel(bar, format(%4.1f) size(small)) ///
 ysc(titlegap(*4)) 
cd "$dirpath/Final/Graphs"
graph export "Fig6_QuantitiesByStrategy2019.png", replace width(1328)
graph close


***Figure 7: Income changes
clear 
cd "$dirpath/Final"
use regressions_quant.dta
set scheme s1mono
gen rev_dev_da=((q_total_offered_da-q_total_demand_da)-(q_total_sold_da-q_total_bought_da))*(mg_price_id_max-mg_price_da2) 
gen rev_dev_id=(q_total_sold_id)*(mg_price_id_max-mg_price_da2) 

gen pbid_dummy_nice="Max. solar price bid > 0"
replace pbid_dummy_nice="Max. solar price bid = 0" if pbid_dummy==0

graph box rev_dev_da, over(pbid_dummy_nice) nooutside ytitle("Selling withheld day-ahead offers (€)", size(medsmall)) graphregion(fcolor(white)) ylabel(,labsize(small)) ysc(titlegap(*4)) medtype(cline) medline(lwidth(thick) lcolor(navy)) box(1, color(eltblue)) box(2, color(ebblue)) name("DA")

graph box rev_dev_id, over(pbid_dummy_nice) nooutside ytitle("Actual intraday sales (€)", size(medsmall)) graphregion(fcolor(white)) ylabel(,labsize(small)) ysc(titlegap(*4)) medtype(cline) medline(lwidth(thick) lcolor(navy)) box(1, color(eltblue)) box(2, color(ebblue))  name("ID")

graph combine DA ID, title("Additional hourly revenues from selling intraday instead of day-ahead", size(small))
cd "$dirpath/Final/Figures"
graph export "Fig6_Income.png", replace width(1328)
graph close


***Table 3
replace diff_q_da2 = (diff_q_da2-0.999)/1000 
replace q_total_sold_id = (q_total_sold_id-0.999)/1000 
sum diff_q_da2 q_total_sold_id diff_p pbid_dummy load_ACT solar_share wind_share hydro_share /// 
 co2price /// 
gasprice solar_fc_error wind_fc_error load_fc_error 
*solar small big retail gas_share coal_share


***Figure 7: Maximum accepted price bid for solar and intraday market price
clear
cd "$dirpath/Final"
use regressions_quant.dta, replace
drop if pbid_dummy==0
replace owner="Firm #1" if strpos(owner,"INIPEL")
replace owner="Firm #2" if strpos(owner,"DLR")
replace owner="Firm #3" if strpos(owner,"GESTER")
replace owner="Firm #4" if strpos(owner,"SHELL") 
replace owner="Firm #5" if strpos(owner,"IGNIS")
replace owner="Firm #6" if strpos(owner,"HOLALUZ")
replace owner="Firm #7" if strpos(owner,"ALPIQ")

set scheme s1mono
twoway scatter mg_price_id_max pbid_max_a_sol if strpos(owner,"#4"), /// 
msize(small) msymbol(o) mlwidth(thin) mcolor(eltblue%50) ///
|| scatter mg_price_id_max pbid_max_a_sol if strpos(owner,"#3"), /// 
msize(small) msymbol(o) mlwidth(thin) mcolor(chocolate%60) ///
|| scatter mg_price_id_max pbid_max_a_sol if strpos(owner,"#2"), /// 
msize(small) msymbol(o) mlwidth(thin) mcolor(midblue%30) ///
|| scatter mg_price_id_max pbid_max_a_sol if strpos(owner,"#1"), /// 
msize(small) msymbol(o) mlwidth(thin) mcolor(orange_red%70) ///
ytitle(Maximum hourly intraday market price (€/MWh), size(medium)) ///
xtitle(Maximum hourly accepted day-ahead price bid (€/MWh), size(medium)) ///
ylabel(0(20)90,labsize(medsmall)) xlabel(0(20)90,labsize(medsmall)) ///
graphregion(color(white)) ///
legend(order(4 3 2 1)  rows(1) size(medsmall) label (1 "Firm #4") label (2 "Firm #3") ///
label (3 "Firm #2") label (4 "Firm #1")) ///
ysc(titlegap(*4)) xsc(titlegap(*4)) name("pbid1")
*cd "$dirpath/Final/Figures" 
*graph export "Fig7_PriceBids_IDPrice.png", replace width(1000)
graph close


twoway scatter mg_price_id_max pbid_max_a_sol if strpos(owner,"#5"), /// 
msize(small) msymbol(o) mlwidth(vthin) mcolor(dknavy) ///
|| scatter mg_price_id_max pbid_max_a_sol if strpos(owner,"#6"), /// 
msize(small) msymbol(o) mlwidth(vthin) mcolor(blue%50) ///
|| scatter mg_price_id_max pbid_max_a_sol if strpos(owner,"#7"), /// 
msize(small) msymbol(o) mlwidth(vthin) mcolor(cranberry%50) ///
ytitle(Maximum hourly intraday market price (€/MWh), size(medium)) ///
xtitle(Maximum hourly accepted day-ahead price bid (€/MWh), size(medium)) ///
ylabel(0(20)90,labsize(medsmall)) xlabel(0(20)90,labsize(medsmall)) ///
graphregion(color(white)) ///
legend(order(1 2 3) rows(1) size(medsmall) label (1 "Firm #5") label (2 "Firm #6") ///
label (3 "Firm #7")) ///
ysc(titlegap(*4)) xsc(titlegap(*4)) name("pbid2")

graph combine pbid1 pbid2, xcommon  ysize(3) 
cd "$dirpath/Final/Figures" 
graph export "Fig7_PriceBids_IDPrice.png", replace width(1328)
graph close

***Figure 8: Maximum accepted and maximum overall price bid for solar
twoway scatter pbid_max_sol pbid_max_a_sol if strpos(owner,"#4"), /// 
msize(small) msymbol(d) mlwidth(thin) mcolor(eltblue%50) ///
|| scatter pbid_max_sol pbid_max_a_sol if strpos(owner,"#3"), /// 
msize(small) msymbol(d) mlwidth(thin) mcolor(chocolate%60) ///
|| scatter pbid_max_sol pbid_max_a_sol if strpos(owner,"#2"), /// 
msize(small) msymbol(d) mlwidth(thin) mcolor(midblue%30) ///
|| scatter pbid_max_sol pbid_max_a_sol if strpos(owner,"#1"), /// 
msize(small) msymbol(d) mlwidth(thin) mcolor(orange_red%70) ///
ytitle(Maximum hourly day-ahead price bid (€/MWh), size(medium)) ///
xtitle(Maximum hourly accepted day-ahead price bid (€/MWh), size(medium)) ///
ylabel(0(20)120,labsize(medsmall)) xlabel(0(20)120,labsize(medsmall)) ///
graphregion(color(white)) ylabel(,labsize(medsmall)) xlabel(,labsize(medsmall)) ///
legend(order(4 3 2 1)  rows(1) size(medsmall) label (1 "Firm #4") label (2 "Firm #3") ///
label (3 "Firm #2") label (4 "Firm #1")) ///
ysc(titlegap(*4)) xsc(titlegap(*4)) name("pbid11")
*cd "$dirpath/Final/Figures" 
*graph export "Fig7_PriceBids_IDPrice.png", replace width(1000)
graph close

twoway scatter pbid_max_sol pbid_max_a_sol if strpos(owner,"#7"), /// 
msize(small) msymbol(d) mlwidth(vthin) mcolor(cranberry%50) ///
|| scatter pbid_max_sol pbid_max_a_sol if strpos(owner,"#6"), /// 
msize(small) msymbol(d) mlwidth(vthin) mcolor(blue%50) ///
|| scatter pbid_max_sol pbid_max_a_sol if strpos(owner,"#5"), /// 
msize(small) msymbol(d) mlwidth(vthin) mcolor(dknavy) ///
ytitle(Maximum hourly intraday market price (€/MWh), size(medium)) ///
xtitle(Maximum hourly accepted day-ahead price bid (€/MWh), size(medium)) ///
ylabel(0(20)180,labsize(medsmall)) xlabel(0(20)180,labsize(medsmall)) ///
graphregion(color(white)) ylabel(,labsize(medsmall)) xlabel(,labsize(medsmall)) ///
legend(order(3 2 1) rows(1) size(medsmall) label (1 "Firm #7") label (2 "Firm #6") ///
label (3 "Firm #5")) ///
ysc(titlegap(*4)) xsc(titlegap(*4)) name("pbid22")

graph combine pbid11 pbid22, ysize(3) 
cd "$dirpath/Final/Figures" 
graph export "Fig8_PriceBids.png", replace width(1328)
graph close

***some calculations
count if pbid_max_a==mg_price_da2
gen market_share = q_total_sold_da/mg_quantity
collapse (sum) q_total_sold_da mg_quantity, by(year month day hour)
gen market_share=q_total_sold_da/(mg_quantity/7)


*Old Figure 7 combined ID Data
clear 
cd "$dirpath/Final"
use allmarketdata.dta
drop if year>2020
gen weekd=dow( mdy( month, day, year) )
gen weekend = 1 if weekd == 6 | weekd == 0
replace weekend = 0 if weekend == .
gen weekdays = 0
replace weekdays = 1 if weekend == 1

egen q_total_mg_id=rowtotal(mg_quantity_id*)
egen mg_price_id_max=rowmax(mg_price_id2*)

drop mg_price_id_max
egen mg_price_id_max=rmax(mg_price_id2*)
gen diff_p_id_da=mg_price_id_max-mg_price_da2

gen weekend2="Weekday" 
replace weekend2="Weekend" if weekend==1

collapse (mean) diff_p_id_da mg_quant*, by(hour weekend2)

 gen mg_quantity_id2=mg_quantity_id_1+mg_quantity_id_2
 gen mg_quantity_id3=mg_quantity_id2+mg_quantity_id_3
 gen mg_quantity_id4=mg_quantity_id3+mg_quantity_id_4
 gen mg_quantity_id5=mg_quantity_id4+mg_quantity_id_5
 gen mg_quantity_id6=mg_quantity_id5+mg_quantity_id_6

set scheme s1mono
graph twoway || bar mg_quantity_id_1 hour, by(weekend2, note("")) barw(0.5) color(eltblue) ///
|| rbar mg_quantity_id_1 mg_quantity_id2 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(ebblue) ///
|| rbar mg_quantity_id2 mg_quantity_id3 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(navy) ///
|| rbar mg_quantity_id3 mg_quantity_id4 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(sienna) ///
|| rbar mg_quantity_id4 mg_quantity_id5 hour, by(weekend2, note("")) barw(0.5) barw(0.5)  color(orange) ///
|| rbar mg_quantity_id5 mg_quantity_id6 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(orange_red) ///
|| line diff_p_id_da hour, yaxis(2) lcolor(black) lwidth(medthick) ytitle("Average Price Difference (€/MWh)", /// 
size(small) axis(2)) ylabel(,labsize(small) axis(2)) ///
 ysc(titlegap(3) axis(2)) /// 
ytitle("Average Volume (MWh)", axis(1) size(medsmall)) ///
ytitle("Average Price Difference (€/MWh)", axis(2) size(medsmall)) ///
ylabel(,labsize(small)) ysc(titlegap(3) axis(1) r(0 6000)) /// 
xtitle("Hour", size(small)) xlabel(1(1)24,labsize(vsmall)) ysc(titlegap(*4)) ///
legend(rows(2) size(small) symxsize(*0.12) label(1 "Intraday Session 1") /// 
label(2 "Intraday Session 2") label(3 "Intraday Session 3") /// 
label(4 "Intraday Session 4") label(5 "Intraday Session 5") /// 
label(6 "Intraday Session 6") label(7 "{&Delta}p")) 
cd "$dirpath/Final/Figures"
graph export Fig7_IntradayMarketData.png, replace width(1328)
graph close

*Figure 9: Intraday market volume
clear 
cd "$dirpath/Final"
use allmarketdata.dta
drop if year>2020
gen weekd=dow( mdy( month, day, year) )
gen weekend = 1 if weekd == 6 | weekd == 0
replace weekend = 0 if weekend == .
gen weekdays = 0
replace weekdays = 1 if weekend == 1

egen q_total_mg_id=rowtotal(mg_quantity_id*)
egen mg_price_id_max=rowmax(mg_price_id2*)

drop mg_price_id_max
egen mg_price_id_max=rmax(mg_price_id2*)
gen diff_p_id_da=mg_price_id_max-mg_price_da2

gen weekend2="Weekday" 
replace weekend2="Weekend" if weekend==1

collapse (mean) diff_p_id_da mg_quant*, by(hour weekend2)

 gen mg_quantity_id2=mg_quantity_id_1+mg_quantity_id_2
 gen mg_quantity_id3=mg_quantity_id2+mg_quantity_id_3
 gen mg_quantity_id4=mg_quantity_id3+mg_quantity_id_4
 gen mg_quantity_id5=mg_quantity_id4+mg_quantity_id_5
 gen mg_quantity_id6=mg_quantity_id5+mg_quantity_id_6

set scheme s1mono
graph twoway || bar mg_quantity_id_1 hour, by(weekend2, note("")) barw(0.5) color(eltblue) ytitle("Average volume (MWh)",size(medsmall)) ylabel(,labsize(small)) ysc(titlegap(3) r(0 6000)) ///
|| rbar mg_quantity_id_1 mg_quantity_id2 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(ebblue) ///
|| rbar mg_quantity_id2 mg_quantity_id3 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(navy) ///
|| rbar mg_quantity_id3 mg_quantity_id4 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(sienna) ///
|| rbar mg_quantity_id4 mg_quantity_id5 hour, by(weekend2, note("")) barw(0.5) barw(0.5)  color(orange) ///
|| rbar mg_quantity_id5 mg_quantity_id6 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(orange_red) ///
xtitle("Hour", size(medsmall)) xlabel(1(1)24,labsize(vsmall)) ysc(titlegap(*4)) ///
legend(rows(2) size(small) symxsize(*0.12) label(1 "Intraday Session 1") /// 
label(2 "Intraday Session 2") label(3 "Intraday Session 3") /// 
label(4 "Intraday Session 4") label(5 "Intraday Session 5") /// 
label(6 "Intraday Session 6")) ysize(3)
cd "$dirpath/Final/Figures"
graph export Fig9_IntradayMarketData1.png, replace width(1328)
graph close
***Figure 9: Intraday market prices 

set scheme s1mono
graph twoway line diff_p_id_da hour, by(weekend2, note("")) lcolor(black) lwidth(medthick) ytitle(" {&Delta}p = Average hourly price difference (€/MWh)", /// 
size(medsmall)) ylabel(,labsize(small)) ///
 ysc(titlegap(3)) /// 
xtitle("Hour", size(medsmall)) xlabel(1(1)24,labsize(small)) /// 
ysc(titlegap(*4)) ysize(3)
cd "$dirpath/Final/Figures"
graph export Fig10_IntradayMarketData2.png, replace width(1328)
graph close


***Tables 3 and 4
clear
cd "$dirpath/Final"
use regressions_price.dta

sum diff_p_id_da q_total_mg_id load_ACT solar_share wind_share hydro_share gas_share coal_share oil_share other_share co2price gasprice solar_fc_error wind_fc_error load_fc_error $dummies
drop if pbid_max==0
sum pbid_max mg_price_id_max load_ACT solar_share wind_share hydro_share gas_share coal_share oil_share other_share co2price gasprice solar_fc_error wind_fc_error load_fc_error $dummies

***Figure 12 and 13
bysort year month day hour: egen q_total_supply_unit_a_all=total(q_total_supply_unit_a)
bysort year month day hour: egen q_total_supply_unit_id_all=total(q_total_supply_unit_id) 
set scheme s1mono
scatter q_total_supply_unit_id_all q_total_supply_unit_a_all if pbid_max_a>0, msize(vsmall)  ///
xtitle("Energy sold day ahead (MWh)", size(medium)) msymbol(oh) mcolor(ebblue%30) ytitle("Energy sold intraday (MWh)", size(medium)) graphregion(fcolor(white)) xlabel(,labsize(small)) ylabel(,labsize(small)) ysc(titlegap(*4)) xsc(titlegap(*4))  ysize(1) xsize(1) name(id1)
*cd "$dirpath/Final/Figures"
*graph export "Fig12_ID_quantities.png", replace width(1328)
graph close

egen pbid_id_min=rmin(pbid_id_1_S_max pbid_id_2_S_max pbid_id_3_S_max pbid_id_4_S_max pbid_id_5_S_max pbid_id_6_S_max)
scatter pbid_max pbid_id_min, msize(vsmall) ///
xtitle("Maximum price bid day-ahead(€/MWh)", size(medium)) msymbol(oh) mcolor(ebblue%30) ytitle("Minimum accepted price bid intraday (€/MWh)", size(medium)) graphregion(fcolor(white)) xlabel(,labsize(small)) ylabel(,labsize(small)) ysc(titlegap(*4)) xsc(titlegap(*4))  ysize(1) xsize(1) name(id2)
*cd "$dirpath/Final/Figures"
*graph export "Fig13_ID_pricebids.png", replace width(1328)
graph close

graph combine id1 id2,ysize(3) 
cd "$dirpath/Final/Figures"
graph export "Fig12_ID_bids.png", replace width(1328)

***Figure 14: More supply-curve steps
clear 
cd "$dirpath/Final"
use prepared_2020_8.dta
drop if hour<8
drop if hour>22
drop if plant_type!="Solar PV"
keep if strpos(owner,"INIPEL") | strpos(owner,"DLR") | strpos(owner,"GESTER")| strpos(owner,"SHELL") | strpos(owner,"IGNIS") | strpos(owner,"HOLALUZ") | strpos(owner,"ALPIQ")

duplicates drop year month day hour owner pbid, force

bysort year month day hour owner: gen step=_n
bysort year month day hour owner: egen step_max=max(step)

bysort owner: sum step_max

keep if owner=="SHELL ESPAÑA" | owner =="GESTERNOVA, S.A."
keep if month==8&	day==1

set scheme s1mono
sort pbid
twoway line pbid supply_unit if owner=="SHELL ESPAÑA"&hour==12, lcolor(orange_red) ///
|| line pbid supply_unit if owner=="GESTERNOVA, S.A." &hour==12, lcolor(midblue) ///
|| line pbid supply_unit if owner=="SHELL ESPAÑA"&hour==18, lpattern(dash) lcolor(orange_red)  ///
|| line pbid supply_unit if owner=="GESTERNOVA, S.A." &hour==18, lpattern(dash) lcolor(midblue) ///
legend(size(small) symxsize(*0.3) label(1 "Firm #4 12:00") label(2 "Firm #2 12:00") /// 
label(3 "Firm #4 18:00") label(4 "Firm #2 18:00")) ///
ytitle("Price bid (€/MWh)", size(medsmall)) ///
ylabel(0(20)80,labsize(medsmall)) ysc(titlegap(4)) ///
xtitle("Supply (MWh)", size(medsmall)) ///
xlabel(0(20)100,labsize(medsmall))  ysize(1) xsize(1)
cd "$dirpath/Final/Figures" 
graph export Fig13_SupplyCurves.png, replace width(1000)
graph close

 



