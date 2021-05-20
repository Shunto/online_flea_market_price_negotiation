
// Analysis of how outcomes vary with number of photos

set more off
clear

do set_globals.do

********************************
* Data Assembly
********************************

// Pulling only the BO sales with strong (20+) reference prices
use count4 anon_item_id item_cndtn_id start_price_usd ref_price4 item_price anon_product_id  anon_leaf_categ_id photo_count  if count4~=. & count4>=20 using "${root}/anon_bo_lists.dta", clear

// Our standard listing sample restriction
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen			

// Merging in threads, keep only if an offer exists
merge 1:m anon_item_id using "${root}/anon_bo_threads", keep(3) nogen				

// Keeping only the winning offer
keep if status_id == 1 | status_id==9								


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

gen log_photo_count=log(photo_count+1)
gen has_photo = photo_count>0

sum has_photo

// Photo variables

label var log_photo_count "Log(Photos + 1)"
label var rrat "Norm. Price"
label var has_photo "No. Photos $>$ 0"

********************************
* Photos regression analysis  
********************************  
eststo clear

eststo photo_used: reg rrat log_photo_count  if used==1, robust	
	estadd local condition "USED"
eststo photo_new: reg rrat log_photo_count  if used==0, robust				
	estadd local condition "NEW"
	
* // Exporting table	
* local options label nomtitles numbers se stats(condition r2 N, label("Condition" "$ R^2 $" "N")) nonotes
* esttab photo_used photo_new using "${figtab}/photos.tex", replace `options'

********************************
* Photos regression analysis  with leaf fixed effects
********************************  

eststo photo_used_leaf: areg rrat log_photo_count  if used==1, absorb(anon_leaf_categ_id) robust	
	estadd local condition "USED"
	estadd local fe "Yes"
eststo photo_new_leaf: reg rrat log_photo_count  if used==0, absorb(anon_leaf_categ_id)robust				
	estadd local condition "NEW"
	estadd local fe "Yes"
	
* // Exporting table	
* local options label nomtitles numbers se stats(condition fe r2 N, label("Condition"  "Leaf FE"  "$ R^2 $" "N")) nonotes
* esttab photo_used photo_new using "${figtab}/photos_leaf.tex", replace `options'



********************************
* "Received offer" and "sold through BO" analysis
********************************  
clear

* 1: Data Assembly

tempfile threads_listtab				// I need to reach for the threads data to get at whether any offer was made
use anon_item_id using "${root}/anon_bo_threads.dta"
bys anon_item_id : gen dup = _n
keep if dup == 1						// Just a list of anon_item_ids that show up in the threads data
drop dup 
save `threads_listtab'

// NOTE: in all of our analysis that uses this reference price sample, we limit to cases where item_cndtn_id~=. Therefore, I will enforce the restriction here when I create the summary stats table. BL 9/11/2019

use anon_item_id anon_slr_id item_price bo_ck_yn   item_cndtn_id  photo_count count4 ref_price4 anon_leaf_categ_id using "${root}/anon_bo_lists.dta" if count4 ~=. & count4 >= 20 & item_cndtn_id~=. ,clear
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen		// Imposing sample restrictions
merge 1:1 anon_item_id using `threads_listtab', keep(1 3) gen(thread_merge)		// NB: Keeping the _merge 




* 2: Variable Assembly

gen sold_any = (item_price ~=.)
gen sold_bo = (bo_ck_yn==1)
gen offr_any = (thread_merge == 3)
gen used = item_cndtn_id >= 3000 if item_cndtn_id ~= .
gen log_photo_count=log(photo_count+1)


* 3: Variable Labels


label var sold_any "Sold"
label var sold_bo "Sold by Best Offer"
label var offr_any "Received Offer"
label var used "Used"
label var log_photo_count "Log(Photos + 1)"

 * 4. Regressions 
 
// ------------
// with no leaf FE: 

eststo POU: reg offr_any log_photo_count  if used==1, robust	
	estadd local condition "USED"
eststo PON: reg offr_any log_photo_count  if used==0, robust				
	estadd local condition "NEW"

eststo PSU: reg sold_bo log_photo_count  if used==1, robust	
	estadd local condition "USED"
eststo PSN: reg sold_bo log_photo_count  if used==0, robust				
	estadd local condition "NEW"	
	
	
// Exporting table	
local options label  numbers se stats(condition r2 N, label("Condition" "$ R^2 $" "N")) nonotes
esttab  POU PON PSU PSN photo_used photo_new using "${figtab}/photos.tex", replace `options'

// ------------
// with leaf FE: 

eststo POU_leaf: areg offr_any log_photo_count  if used==1, absorb(anon_leaf_categ_id) robust	
	estadd local condition "USED"
	estadd local fe "Yes"
eststo PON_leaf: reg offr_any log_photo_count  if used==0, absorb(anon_leaf_categ_id)robust				
	estadd local condition "NEW"
	estadd local fe "Yes"
	
eststo PSU_leaf: areg sold_bo log_photo_count  if used==1, absorb(anon_leaf_categ_id) robust	
	estadd local condition "USED"
	estadd local fe "Yes"
eststo PSN_leaf: reg sold_bo log_photo_count  if used==0, absorb(anon_leaf_categ_id)robust				
	estadd local condition "NEW"
	estadd local fe "Yes"	
	
// Exporting table	
local options label  numbers se stats(condition  r2 df_a N, label("Condition"   "$ R^2 $" "No. Leaf FE"  "N")) nonotes
esttab    POU_leaf PON_leaf PSU_leaf PSN_leaf photo_used_leaf photo_new_leaf using "${figtab}/photos_leaf.tex", replace `options'


********************************
* Time to first offer plots
********************************  

use anon_item_id anon_byr_id src_cre_date src_cre_dt using "${root}/anon_bo_threads.dta",clear
sort anon_item_id anon_byr_id src_cre_date
by anon_item_id anon_byr_id: gen order = _n
keep if order==1
drop order
tempfile thread_variables_needed
save `thread_variables_needed'

use  anon_item_id auct_start_dt photo_count start_price_usd using "${root}/anon_bo_lists.dta", clear
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen
merge 1:m anon_item_id using `thread_variables_needed', keep(3) nogen

// Drop cases where number of photos = 0; we believe eBay rules  are supposed to prevent listings with no photos
keep if photo_count>0 
gen time_on_site = src_cre_dt - auct_start_dt

collapse (mean) time_on_site, by(photo_count)
twoway scatter time_on_site photo_count, ///
  ytitle("Days to First Offer") xtitle("Number of Photos") ///
  xlabel(1(4)12) ylabel(20(5)40) graphregion(color(white)) plotregion(style(none))
graph export "${figtab}/first_offer_photo.png", replace



