* Patience/experience tables

set more off
clear

do set_globals.do

cap log close
log using "${figtab}/patience_experience.log", replace

********************************
* Data Assembly
********************************

// Pulling only the BO sales with strong (20+) reference prices
use count4 anon_item_id item_cndtn_id start_price_usd ref_price4 item_price anon_product_id ship_time_fastest ship_time_slowest ship_time_chosen anon_leaf_categ_id meta_categ_id if count4~=. & count4>=20 using "${root}/anon_bo_lists.dta", clear

// Our standard listing sample restriction
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen			

// Merging in threads, keep only if an offer exists
merge 1:m anon_item_id using "${root}/anon_bo_threads", keep(3) nogen				

// Replace missing history counts with the counts of the first observation in this thread
sort anon_item_id anon_byr_id src_cre_date
by anon_item_id anon_byr_id: replace byr_hist=byr_hist[1]
by anon_item_id anon_byr_id: replace slr_hist=slr_hist[1]
// Treat other missing _hist as 1 (includes THIS obs)
replace slr_hist=1 if slr_hist==.
replace byr_hist=1 if byr_hist==.

// Keeping only the winning offer
keep if status_id==1 | status_id==9


********************************
* Variable Assembly
********************************

// Generating a dummy for being a used product.
gen used = item_cndtn_id >= 3000 if item_cndtn_id ~=.	
// Creating the product gorups for ref_price4. Note that anon_product_id is a 7-digit number.													
gen prod_group = 10^8*used + anon_product_id													
gen prat = item_price/start_price_usd
// This is the normalized (by reference) price
gen rrat = item_price/ref_price4 													
// This just indicates that the buyer had a choice about shipping 
gen multiship = ship_time_fastest!=ship_time_slowest & ship_time_fastest>0 & ship_time_slowest>0 & ship_time_fastest!=. & ship_time_slowest!=.	
// This is a dummy for chosing the slowest shiping time, choice or no
gen slow_ship = ship_time_chosen == ship_time_slowest & multiship==1

sum multiship slow_ship												

// Experience variables
gen log_slr_hist = log(slr_hist)
gen log_byr_hist = log(byr_hist)

// byr_hist and slr_hist are actually the number of previous interactions + 1; following variables are dummies we can include in the regressions
gen has_slr_hist = slr_hist>1
gen has_byr_hist = byr_hist>1


label var rrat "Norm. Price"
label var slow_ship "Slowest shipping"
label var log_slr_hist "Log(Seller experience)"
label var log_byr_hist "Log(Buyer experience)"
label var has_slr_hist  "Seller experience $>$ 0" 
label var has_byr_hist  "Buyer experience $>$ 0"
label var multiship "Multiple shipping options"

********************************
* Patience/Experience Regressions
********************************

eststo UR1: reg rrat slow_ship multiship if  used==1, robust					// Just shipping
	estadd local condition = "Used"
eststo UR2: reg rrat log_slr_hist log_byr_hist    if  used==1, robust					// Just experience
	estadd local condition = "Used"
eststo UR3: reg rrat slow_ship multiship log_slr_hist log_byr_hist    if   used==1, robust	// Both
	estadd local condition = "Used"

eststo NR1: reg rrat slow_ship multiship if    used==0, robust					// Just shipping
	estadd local condition = "New"
eststo NR2: reg rrat log_slr_hist log_byr_hist    if  used==0, robust					// Just experience
	estadd local condition = "New"
eststo NR3: reg rrat slow_ship multiship log_slr_hist log_byr_hist    if   used==0, robust	// Both
	estadd local condition = "New"


// Exporting table
local options label nomtitles numbers se stats(condition r2 N, label("Condition" "$ R^2 $" "N")) nonotes

esttab NR1 NR2 NR3 UR1 UR2 UR3 using "${figtab}/patience_experience.tex", replace `options' 
eststo clear

********************************
* Patience/Experience Regressions with Leaf FE
********************************

eststo UR1: areg rrat slow_ship multiship if  used==1, absorb(anon_leaf_categ_id) robust					// Just shipping
	estadd local condition = "Used"
	estadd local fe = "Yes"
eststo UR2: areg rrat log_slr_hist log_byr_hist    if  used==1,absorb(anon_leaf_categ_id) robust					// Just experience
	estadd local condition = "Used"
	estadd local fe = "Yes"
eststo UR3: areg rrat slow_ship multiship log_slr_hist log_byr_hist    if   used==1,absorb(anon_leaf_categ_id) robust	// Both
	estadd local condition = "Used"
	estadd local fe = "Yes"

eststo NR1: areg rrat slow_ship multiship if    used==0,absorb(anon_leaf_categ_id) robust					// Just shipping
	estadd local condition = "New"
	estadd local fe = "Yes"
eststo NR2: areg rrat log_slr_hist log_byr_hist   if  used==0,absorb(anon_leaf_categ_id) robust					// Just experience
	estadd local condition = "New"
	estadd local fe = "Yes"
eststo NR3: areg rrat slow_ship multiship log_slr_hist log_byr_hist   if   used==0,absorb(anon_leaf_categ_id) robust	// Both
	estadd local condition = "New"
	estadd local fe = "Yes"

// Exporting table
local options label nomtitles numbers se stats(condition r2 df_a N, label("Condition"  "$ R^2 $" "No. Leaf FE" "N")) nonotes
esttab NR1 NR2 NR3 UR1 UR2 UR3 using "${figtab}/patience_experience_leaf.tex", replace `options' 
eststo clear




********************************
* Patience/Experience Regressions with Meta FE
********************************

eststo UR1: areg rrat slow_ship multiship if  used==1, absorb(meta_categ_id) robust					// Just shipping
	estadd local condition = "Used"
	estadd local fe = "Yes"
eststo UR2: areg rrat log_slr_hist log_byr_hist   if  used==1,absorb(meta_categ_id) robust					// Just experience
	estadd local condition = "Used"
	estadd local fe = "Yes"
eststo UR3: areg rrat slow_ship multiship log_slr_hist log_byr_hist   if   used==1,absorb(meta_categ_id) robust	// Both
	estadd local condition = "Used"
	estadd local fe = "Yes"

eststo NR1: areg rrat slow_ship multiship if   used==0,absorb(meta_categ_id) robust					// Just shipping
	estadd local condition = "New"
	estadd local fe = "Yes"
eststo NR2: areg rrat log_slr_hist log_byr_hist   if  used==0,absorb(meta_categ_id) robust					// Just experience
	estadd local condition = "New"
	estadd local fe = "Yes"
eststo NR3: areg rrat slow_ship multiship log_slr_hist log_byr_hist   if   used==0,absorb(meta_categ_id) robust	// Both
	estadd local condition = "New"
	estadd local fe = "Yes"

// Exporting table
local options label nomtitles numbers se stats(condition r2 df_a N, label("Condition" "$ R^2 $" "No. Meta FE" "N")) nonotes
esttab NR1 NR2 NR3 UR1 UR2 UR3 using "${figtab}/patience_experience_meta.tex", replace `options' 
eststo clear





********************************
* Extra Patience Analysis: Exploring whether buyers sometimes appear patient and sometimes not
********************************
preserve 
keep if multiship==1
// classify buyer as patient vs. not
gen patient = slow_ship==1 

// count how many buyers show up multiple times in this data
bys anon_byr_id: gen n = _N

// for those who show up >1, calculate each buyer's fraction of time she is classified as patient across all sequences she participates in
bys anon_byr_id: egen frac_patient  = mean(patient) if n>1

// now compute how many of these multiple-purchase-in-the-shipping-sample buyers show up as always patient or always not
gen always_patient = frac_patient==0 if frac_patient!=.
gen never_patient = frac_patient==1 if frac_patient!=.
sum always_patient never_patient 

count if frac_patient==0
// ANS = 4,165
count if frac_patient==1
// ANS = 4,061
// NOTE: total in this sample is 17,022
restore

********************************
* Patience results with buyer fixed effects
********************************

eststo clear
bysort anon_byr_id: egen min_slow_ship = min(slow_ship)
bysort anon_byr_id: egen max_slow_ship = max(slow_ship)
eststo: areg rrat slow_ship multiship if used == 0, absorb(anon_byr_id) robust
  estadd local condition  "New"
  estadd local buyerFE "Yes"
eststo: areg rrat slow_ship multiship if used == 1, absorb(anon_byr_id) robust
  estadd local condition  "Used"
  estadd local buyerFE "Yes"
eststo: reg rrat slow_ship multiship if min_slow_ship != max_slow_ship & used == 0, robust
  estadd local condition  "New"
  estadd local buyerFE "No"
eststo: reg rrat slow_ship multiship if min_slow_ship != max_slow_ship & used == 1, robust
  estadd local condition  "Used"
  estadd local buyerFE "No"
eststo: areg rrat slow_ship multiship if min_slow_ship != max_slow_ship & used == 0, absorb(anon_byr_id) robust
  estadd local condition  "New"
  estadd local buyerFE "Yes"
eststo: areg rrat slow_ship multiship if min_slow_ship != max_slow_ship & used == 1, absorb(anon_byr_id) robust
  estadd local condition  "Used"
  estadd local buyerFE "Yes"

bysort anon_byr_id: gen total_purchase = _N
eststo: areg rrat slow_ship multiship if min_slow_ship != max_slow_ship & total_purchase == 2 & used == 0, absorb(anon_byr_id) robust
  estadd local condition  "New"
  estadd local buyerFE "Yes"
eststo: areg rrat slow_ship multiship if min_slow_ship != max_slow_ship & total_purchase == 2 & used == 1, absorb(anon_byr_id) robust
  estadd local condition  "Used"
  estadd local buyerFE "Yes"

esttab using "${figtab}/Patience_difference.tex", title("Patience")  ///
  se replace star( * 0.1 ** 0.05 *** 0.01) ///
  keep(slow_ship) order(slow_ship) ///
  coeflabels(slow_ship "Slowest Shipping")  nomtitles ///
  scalars("condition Condition" "buyerFE BuyerFE") eqlabels(none) ///
   prehead(\begin{tabular}{l*{8}{c}}\hline\hline)  ///
   postfoot(\hline\hline\end{tabular})
  
  
  
log close

