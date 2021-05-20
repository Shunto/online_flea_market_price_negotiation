// Concession Regressions

do set_globals.do

cap log close
log using "${figtab}/concession_regression.log", replace

use anon_item_id  item_cndtn_id start_price_usd anon_leaf_categ_id using "${root}/anon_bo_lists.dta"
tempfile lists_needed_variables
save `lists_needed_variables'

use "${root}/anon_bo_threads.dta", clear
merge m:1 anon_item_id using "${derived_data}/sample_id_list.dta", nogen keep(3)
merge m:1 anon_item_id using `lists_needed_variables', nogen keep(3)			



* CONDITION
gen used = item_cndtn_id >= 3000 & item_cndtn_id ~=.


// drop offers that are auto-accepted/declined (these might mechanically look like concession)
gen auto=(status_id==6|status_id==9)
bysort anon_item_id anon_byr_id: egen auto_y=max(auto)
drop if auto_y==1 
drop auto auto_y

// drop offers that include any message (dropped 20% threads) (we don't want to capture any concessions that are due to communication in the messages)
bysort anon_item_id anon_byr_id: egen mess_y=max(any_mssg)
drop if mess_y==1 
drop mess_y

// define sequence
sort anon_item_id anon_byr_id src_cre_date
by anon_item_id anon_byr_id: gen order = _n

gen seq = 1 if offr_type_id == 0 & order==1							// PB1
by anon_item_id anon_byr_id: replace seq=2 if seq[_n-1]== 1 & offr_type_id == 2	//PS1	
by anon_item_id anon_byr_id: replace seq=3 if seq[_n-1]== 2 & offr_type_id == 1 //PB2
by anon_item_id anon_byr_id: replace seq=4 if seq[_n-1]== 3 & offr_type_id == 2 //PS2
by anon_item_id anon_byr_id: replace seq=5 if seq[_n-1]== 4 & offr_type_id == 1 //PB3
by anon_item_id anon_byr_id: replace seq=6 if seq[_n-1]== 5 & offr_type_id == 2 //PS3

drop if seq==.											// Throwing away all offers that do not correspond to the 021212 sequence


****************************************
* Constructing Gammas
****************************************

gen prior_price = start_price_usd if seq == 1											// Think of prior_price as the standing price when you make your offer
by anon_item_id anon_byr_id: replace prior_price = offr_price[_n-1] if seq >= 2							// This defines it by looking one step up the chain

gen gamma = offr_price/prior_price if seq == 1											// Remember our  defintion of gamma for the first offer
by anon_item_id anon_byr_id: replace gamma = (offr_price - prior_price[_n-1])/(prior_price - prior_price[_n-1]) if seq >= 2	// Solve the formula for gamma, you get this expression (I promise)

by anon_item_id anon_byr_id: egen min_gam = min(gamma)
by anon_item_id anon_byr_id: egen max_gam = max(gamma)
drop if min_gam < 0
drop if max_gam > 1														// Dropping all threads that don't conform to gamma in [0,1] at any point



by anon_item_id anon_byr_id: gen order_all = _N	
drop if order_all==1


* OFFER SEQUENCE
replace status_id = 2 if status_id==0| status_id==8 // expired offer treated as declined
gen PS0=start_price_usd 
gen PB1_tmp=offr_price if seq==1
by anon_item_id anon_byr_id: egen PB1=max(PB1_tmp)

gen PS2_tmp=offr_price if seq==2
by anon_item_id anon_byr_id: egen PS2=max(PS2_tmp)

gen PB3_tmp=offr_price if seq==3
by anon_item_id anon_byr_id: egen PB3=max(PB3_tmp)

gen PS4_tmp=offr_price if seq==4
by anon_item_id anon_byr_id: egen PS4=max(PS4_tmp)

gen PB5_tmp=offr_price if seq==5
by anon_item_id anon_byr_id: egen PB5=max(PB5_tmp)

gen PS6_tmp=offr_price if seq==6
by anon_item_id anon_byr_id: egen PS6=max(PS6_tmp)



* only keep one obs for one sequence
keep if order==1
drop PB1_tmp PS2_tmp  PB3_tmp PS4_tmp  PB5_tmp PS6_tmp

* gamma: weight on the opponent's offer

gen gamma2=(PS2-PS0)/(PB1-PS0)
gen gamma3=(PB3-PB1)/(PS2-PB1)
gen gamma4=(PS4-PS2)/(PB3-PS2)
gen gamma5=(PB5-PB3)/(PS4-PB3)
gen gamma6=(PS6-PS4)/(PB5-PS4)

gen gamma2_0dummy = gamma2==0
gen gamma3_0dummy = gamma3==0
gen gamma4_0dummy = gamma4==0
gen gamma5_0dummy = gamma5==0

label var gamma2 "$ \gamma_2 $"
label var gamma3 "$ \gamma_3 $"
label var gamma4 "$ \gamma_4 $"
label var gamma5 "$ \gamma_5 $"
label var gamma6 "$ \gamma_6 $"



****************************************
* Regressions
****************************************

eststo clear 

forvalues j = 3/6 {

local k = `j'-1

rename gamma`k' gammat1
rename gamma`k'_0dummy gammat1_0dummy

* label var gammat1 "$\gamma_{t-1}$"
* label var gammat1_0dummy "$1\{\gamma_{t-1}==0\}$"
* gammat1_0dummy

eststo : reg gamma`j' gammat1  if used==1, vce(robust)					
	estadd local condition = "USED"

eststo : reg gamma`j' gammat1  if   used==0, vce(robust)					
	estadd local condition = "NEW"
	
rename gammat1 gamma`k' 
rename gammat1_0dummy gamma`k'_0dummy	

}


local options label numbers se stats(condition r2 N, label("Condition" "$ R^2 $" "N")) nonotes

esttab * using "${figtab}/concession_regression.tex", replace `options' 

eststo clear 


// Same regressions as above but with Leaf Fixed Effects

forvalues j = 3/6 {

local k = `j'-1

rename gamma`k' gammat1
rename gamma`k'_0dummy gammat1_0dummy

* label var gammat1 "$\gamma_{t-1}$"
* label var gammat1_0dummy "$1\{\gamma_{t-1}==0\}$"
* gammat1_0dummy

eststo : areg gamma`j' gammat1  if used==1, absorb(anon_leaf_categ_id)  vce(robust)					
	estadd local condition = "USED"
	estadd local fe = "Yes"

eststo : areg gamma`j' gammat1  if   used==0, absorb(anon_leaf_categ_id)   vce(robust)					
	estadd local condition = "NEW"
	estadd local fe = "Yes"
	
rename gammat1 gamma`k' 
rename gammat1_0dummy gamma`k'_0dummy	

}


local options label numbers se stats(condition r2 df_a N, label("Condition"  "$ R^2 $" "No. Leaf FE" "N")) nonotes

esttab * using "${figtab}/concession_regression_leaf.tex", replace `options' 

// Modified version of regressions for appendix (where instead of gamma we use percent change relative to previous offer)

eststo clear 

drop gamma2 gamma3 gamma4 gamma5 gamma6

gen gamma2=(PS0-PS2)/(PS0)
gen gamma3=(PB3-PB1)/(PB1)
gen gamma4=(PS2-PS4)/(PS2)
gen gamma5=(PB5-PB3)/(PB3)
gen gamma6=(PS4-PS6)/(PS4)



forvalues j = 3/6 {

local k = `j'-1

rename gamma`k' gammat1
rename gamma`k'_0dummy gammat1_0dummy

* label var gammat1 "$\gamma_{t-1}$"
* label var gammat1_0dummy "$1\{\gamma_{t-1}==0\}$"

eststo : areg gamma`j' gammat1 gammat1_0dummy if used==1, absorb(anon_leaf_categ_id)  vce(robust)					
	estadd local condition = "USED"
	estadd local fe = "Yes"

eststo : areg gamma`j' gammat1 gammat1_0dummy if   used==0, absorb(anon_leaf_categ_id)   vce(robust)					
	estadd local condition = "NEW"
	estadd local fe = "Yes"
	
rename gammat1 gamma`k' 
rename gammat1_0dummy gamma`k'_0dummy	

}

local options label numbers se stats(condition r2 df_a N, label("Condition"  "$ R^2 $" "No. Leaf FE" "N")) nonotes

esttab * using "${figtab}/concession_regression_percent_leaf.tex", replace `options' 




cap log close
