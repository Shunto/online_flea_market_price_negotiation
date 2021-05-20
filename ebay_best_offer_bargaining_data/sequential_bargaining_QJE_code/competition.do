// Analysis of competition and cases where same buyer interacts with multiple sellers, same seller interacts with multiple buyers,etc. 

* Carol Lu, Yuki Song, Brad Larsen, Chuan Yu

do set_globals.do

log using "${figtab}/competition.log",replace


* // Merge all data
* use anon_item_id anon_slr_id auct_start_dt auct_end_dt anon_product_id count4 ref_price4 ///
  * using "${root}/anon_bo_lists.dta" if count4 ~=. & count4 >= 20, clear
* drop count4
* tempfile lists_needed_variables
* save `lists_needed_variables'
* use anon_item_id anon_byr_id src_cre_date response_time status_id using "${root}/anon_bo_threads.dta" 
* merge m:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen  // Merge our standard listing sample restriction
* merge m:1 anon_item_id using `lists_needed_variables', keep(3) nogen      // Merge in lists, keep only if an offer exists

* // Variable Assembly
* replace response_time = . if status_id == 7
* sort anon_item_id anon_byr_id src_cre_date    
* by anon_item_id anon_byr_id: gen order = _n    
* by anon_item_id anon_byr_id: gen round = _N
* gen success = (status_id == 1 | status_id == 9)
* by anon_item_id anon_byr_id: egen sold = max(success)
* // Generate start and end time of a bargaining
* by anon_item_id anon_byr_id: gen start = src_cre_date
* by anon_item_id anon_byr_id: gen end = response_time[_N]
* format start end %tc
* keep if order == 1 // keep one observation per bargaining thread (a thread is a pair of anon_item_id X anon_byr_id)
* tempfile bargaining
* save `bargaining'


* // Prepare for regression analysis : calculate competition between buyers, sellers and items
* **********************************************************************************
* * a. count competition between buyers (time-overlapping bargains with the same seller)
* **********************************************************************************

* use `bargaining', clear
* by anon_item_id: egen win = sum(sold)
* drop if win == 0 //drop items that never sell in any bargain - these won't report any bargained outcome in price           

* // Record dates of the winner's bargain for each competing buyers
* gen win_start_tmp = start if sold == 1
* gen win_end_tmp = end if sold == 1
* by anon_item_id: egen win_start = sum(win_start_tmp)
* by anon_item_id: egen win_end = sum(win_end_tmp)
* format win_start win_end %tc

* // count number of bargains overlapping the winner's bargain
* gen overlap = (start <= win_end & end >= win_start & sold != 1) // overlap=1 means this bargain overlaps with the winning bargain 
* by anon_item_id: egen byr_overlaps = sum(overlap) // total number of other buyers whose bargains overlap with the winning bargain
* keep if sold == 1 // keep a list of winning buyers 

* keep anon_item_id anon_byr_id byr_overlaps
* save "${derived_data}/byr_overlaps.dta", replace

* * note: we are only calculating overlaps for the WINNER of the bargaining sequence, in order save time (because we are currently only using this variable in our reference price regressions -- using only listings that sold)


* **********************************************************************************
* * b. count competition between sellers (time-overlapping bargains with one buyer under the same product)
* **********************************************************************************
* use `bargaining', clear
* sort anon_byr_id anon_product_id
* by anon_byr_id anon_product_id: egen total_sold = sum(sold)
* drop if total_sold == 0 //drop buyer - product pairs that never ended in agreement - these won't report any bargained outcome in price 
* by anon_byr_id anon_product_id: gen num = _N
* drop if num == 1 //drop byr_product pairs that only appeared once - these won't have any competing sellers
 
* //cluster bargains under the same product and buyer; sort so that winning bargains are at the top 
* gsort anon_product_id anon_byr_id -sold anon_item_id
* by anon_product_id anon_byr_id: gen rank = _n if sold == 1  //generate the order of a successful bargain within a product X buyer group 
* qui sum rank
* local max_sold = r(max)

* gen slr_overlaps = .
* gen overlap = .
* //loop from 1 to the maximal "rank"
* forvalues j = 1 / `max_sold' {
    * //record the dates of winning bargain of interest for each member in the product X buyer group
    * qui gen double start`j' = start if rank == `j'
    * qui gen double end`j' = end if rank == `j'
    * qui by anon_product_id anon_byr_id: egen double group_start`j' = sum(start`j')
    * qui by anon_product_id anon_byr_id: egen double group_end`j' = sum(end`j')
    * //within each product X buyer group, mark the bargains that overlap with the winning bargain of interest
    * qui replace overlap = (start <= group_end`j' & end >= group_start`j' & rank != `j')
    * qui by anon_product_id anon_byr_id: egen overlap_`j' = sum(overlap)
    * //replace the count of overlaps only for the bargain of interest
    * qui replace slr_overlaps = overlap_`j' if rank == `j'
    * drop group_start`j' group_end`j' start`j' end`j' overlap_`j'
* }

* keep anon_item_id anon_byr_id slr_overlaps
* save "${derived_data}/slr_overlaps.dta", replace


* ***********************************************************************************
* *c. count competition between items (overlapping items that are live on the site under the same product)
* **********************************************************************************
* use `bargaining', clear
* sort anon_item_id sold anon_byr_id
* drop if anon_item_id == anon_item_id[_n + 1] & sold == 0 //keep a unique list of items
* sort anon_product_id
* by anon_product_id: gen num = _N
* drop if num == 1 //drop products that have only one listing - these won't witness item competition
* by anon_product_id: egen max_sold = max(sold)
* drop if max_sold == 0 //drop products that are never sold - these won't report bargained price

* // Convert bargaining start and end time (by seconds) into date (so as to be comparable with listing date)
* gen thread_start_dt = dofc(start)
* format thread_start_dt %td
* gen thread_end_dt = dofc(end)
* format thread_end_dt %td

* //cluster bargains under the same product; sort so that winning bargains are at the top 
* gsort anon_product_id -sold anon_byr_id anon_item_id
* by anon_product_id : gen rank = _n if sold == 1  //generate the order of a successful bargain within a product cluster
* qui sum rank
* local max_sold = r(max)

* gen item_overlaps = .
* gen overlap = .
* //loop from 1 to the maximal "rank"
* forvalues j = 1 / `max_sold' {
    * qui gen double thread_start_dt`j' = thread_start_dt if rank == `j'
    * qui gen double thread_end_dt`j' = thread_end_dt if rank == `j'
    * qui by anon_product_id: egen double group_start`j' = sum(thread_start_dt`j')
    * qui by anon_product_id: egen double group_end`j' = sum(thread_end_dt`j')
    * //within each product group, mark the bargains that overlap with the winning bargain of interest
    * qui replace overlap = (auct_start_dt <= group_end`j' & auct_end_dt >= group_start`j' & rank != `j')
    * qui by anon_product_id: egen overlap_`j' = sum(overlap)
    * //replace the count of overlaps only for the bargain of interest
    * qui replace item_overlaps = overlap_`j' if rank ==`j'
    * drop group_start`j' group_end`j' thread_start_dt`j' thread_end_dt`j' overlap_`j'
* }

* keep anon_item_id anon_byr_id item_overlaps
* save "${derived_data}/item_overlaps.dta", replace


// Regression Analysis 

// Merge all data
use anon_item_id item_cndtn_id start_price_usd ref_price4 item_price anon_product_id count4 anon_leaf_categ_id ///
  if count4 ~= . & count4 >= 20 using "${root}/anon_bo_lists.dta", clear
drop count4
tempfile lists_needed_variables
save `lists_needed_variables'
use anon_item_id anon_byr_id src_cre_date response_time status_id using "${root}/anon_bo_threads.dta" 
merge m:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen  // Merge our standard listing sample restriction
merge m:1 anon_item_id using `lists_needed_variables', keep(3) nogen      // Merge in lists, keep only if an offer exists

replace response_time = . if status_id == 7
sort anon_item_id anon_byr_id src_cre_date	
// Compute additional measure of buyer competition based solely on status_id ==8 (cases where a buyer offer was declined because of seller accepting an offer from another buyer)
by anon_item_id anon_byr_id: egen count_byrs_declined = sum(status_id == 8)
// Keeping only the winning offer
keep if status_id == 1 | status_id == 9

// Merge in the overlaps variables
merge 1:1 anon_item_id anon_byr_id using "${derived_data}/byr_overlaps.dta",nogen keep(1 3)
merge 1:1 anon_item_id anon_byr_id using "${derived_data}/slr_overlaps.dta",nogen keep(1 3)
merge 1:1 anon_item_id anon_byr_id using "${derived_data}/item_overlaps.dta",nogen keep(1 3)

// Assemble variables
gen used = item_cndtn_id >= 3000 if item_cndtn_id != . // Generating a dummy for being a used product.
gen prod_group = 10^8 * used + anon_product_id // Creating the product gorups for ref_price4. Note that anon_product_id is a 7-digit number.
gen rrat = item_price / ref_price4     

replace byr_overlaps  = 0 if byr_overlaps  == .
replace slr_overlaps  = 0 if slr_overlaps  == . 
replace item_overlaps = 0 if item_overlaps == . 
gen log_byr_overlaps  = log(byr_overlaps + 1)
gen log_slr_overlaps  = log(slr_overlaps + 1)
gen log_item_overlaps = log(item_overlaps + 1)
gen has_byr_overlaps  = byr_overlaps > 0
gen has_slr_overlaps  = slr_overlaps > 0
gen has_item_overlaps = item_overlaps > 0

label var rrat              "Norm. Price"
label var log_byr_overlaps  "Log(competing buyers + 1)"
label var log_slr_overlaps  "Log(competing sellers + 1)"
label var log_item_overlaps "Log(competing listings + 1)"
label var has_byr_overlaps  "No. competing buyers $>$ 0"
label var has_slr_overlaps  "No. competing sellers $>$ 0"
label var has_item_overlaps "No. competing listings $>$ 0"


********************************
* Competition Regressions  
********************************  
eststo clear

eststo U1: reg rrat log_byr_overlaps  if used == 1, robust                    
    estadd local condition = "USED"
eststo U2: reg rrat log_slr_overlaps  if used == 1, robust                    
    estadd local condition = "USED"
eststo U3: reg rrat log_item_overlaps  if used == 1, robust                    
    estadd local condition = "USED"
eststo U4: reg rrat log_byr_overlaps log_slr_overlaps log_item_overlaps    if used == 1, robust    
    estadd local condition = "USED"

eststo N1: reg rrat log_byr_overlaps  if used == 0, robust                
    estadd local condition = "NEW"
eststo N2: reg rrat log_slr_overlaps  if used == 0, robust                    
    estadd local condition = "NEW"
eststo N3: reg rrat log_item_overlaps  if used == 0, robust    
    estadd local condition = "NEW"
eststo N4: reg rrat log_byr_overlaps log_slr_overlaps log_item_overlaps    if used == 0, robust    
    estadd local condition = "NEW"

local options label nomtitles numbers se stats(condition r2 N, label("Condition" "$ R^2 $" "N")) nonotes
esttab N1 N2 N3 N4  U1 U2 U3 U4 using "${figtab}/competition.tex", replace `options'


eststo clear

eststo U1: areg rrat log_byr_overlaps  if used == 1, absorb(anon_leaf_categ_id) vce(robust)                            
    estadd local condition = "USED"
    estadd local leafFE "Yes"
eststo U2: areg rrat log_slr_overlaps  if used == 1, absorb(anon_leaf_categ_id) vce(robust)                            
    estadd local condition = "USED"
    estadd local leafFE "Yes"
eststo U3: areg rrat log_item_overlaps  if used == 1, absorb(anon_leaf_categ_id) vce(robust)                            
    estadd local condition = "USED"
    estadd local leafFE "Yes"
eststo U4: areg rrat log_byr_overlaps log_slr_overlaps log_item_overlaps    if used == 1, absorb(anon_leaf_categ_id) vce(robust)            
    estadd local condition = "USED"
    estadd local leafFE "Yes"

eststo N1: areg rrat log_byr_overlaps  if used == 0, absorb(anon_leaf_categ_id) vce(robust)                        
    estadd local condition = "NEW"
    estadd local leafFE "Yes"
eststo N2: areg rrat log_slr_overlaps  if used == 0, absorb(anon_leaf_categ_id) vce(robust)                            
    estadd local condition = "NEW"
    estadd local leafFE "Yes"
eststo N3: areg rrat log_item_overlaps  if used == 0, absorb(anon_leaf_categ_id) vce(robust)            
    estadd local condition = "NEW"    
    estadd local leafFE "Yes"
eststo N4: areg rrat log_byr_overlaps log_slr_overlaps log_item_overlaps    if used == 0, absorb(anon_leaf_categ_id) vce(robust)            
    estadd local condition = "NEW"
    estadd local leafFE "Yes"

local options label nomtitles numbers se stats(condition r2 df_a N, label("Condition"  "$ R^2 $" "No. Leaf FE" "N")) nonotes
esttab N1 N2 N3 N4  U1 U2 U3 U4 using "${figtab}/competition_leaf.tex", replace `options'


log close _all
