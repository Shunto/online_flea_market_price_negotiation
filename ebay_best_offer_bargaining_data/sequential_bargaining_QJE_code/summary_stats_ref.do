* This dofile generates a simple summary statistics table
* MRB Aug 2016

* Updated Sept 2016 MRB to use sample_id_list.dta for sample restrictions, also simplified threads_listtab
* Updated Sept 2016 MRB to take HHI calculations out of the table
* 
* Updated to remove N column, add photo_count, added a few more stats to threads panel. Changed how data is loaded in for speed. 
* BL Aug 2019


clear
set more off
estimates clear
do set_globals.do

cap log close 
log using "${figtab}/sumstats_ref.log",replace

local sumstats "${figtab}/sumstats_ref.tex"

local tab_settings cells("mean(fmt(%18.3gc)) sd(fmt(%18.3gc)) min(fmt(%18.3gc)) max(fmt(%18.3gc)) ") varwidth(20) modelwidth(12) nonumbers delimiter(&) end(\\) posthead("\hline")  label varlabels(_cons Constant) mlabels(none) collabels(none) eqlabels(none) substitute("$" "\\$" " .&" " -&" "(.)" "") notype level(95) style(tex)

* OUTLINE:
*
* Listings
* 	- Asking price
* 	- P Sale
*	- P BO|Sale
* 	- P Any offers
* 	- Sale Price (absolute and frac)
* 	- Bargained Price (absolute and frac)
*     - Photos
* 	- Sale price / ref price
* 	- Bargained price / ref price
* Sellers
*	- Feedback number and percentage
* 	- Number of Listings
*	- Number of Sales, any and bargained
* 	- Seller HHI (HHI Listing equivalent?)
* Buyers
* 	- Experience
* 	- Number of Purchases
* 	- Number of Offers
* 	- Number of Threads
* 	- Buyer HHI and HHI Listing Equivalent
* Threads
* 	- Length
* 	- Mean first offer
* 	- Mean first offer/BIN
* 	- P Successful
* 	- Num offers if successful
* 	- Mean first offer / ref price


*********************************
* Listings
*********************************

* 1: Data Assembly

tempfile threads_listtab				// I need to reach for the threads data to get at whether any offer was made
use anon_item_id using "${root}/anon_bo_threads.dta"
bys anon_item_id : gen dup = _n
keep if dup == 1						// Just a list of anon_item_ids that show up in the threads data
drop dup 
save `threads_listtab'

// NOTE: in all of our analysis that uses this reference price sample, we limit to cases where item_cndtn_id~=. Therefore, I will enforce the restriction here when I create the summary stats table. BL 9/11/2019

use anon_item_id anon_slr_id item_price bo_ck_yn fdbk_pstv_start start_price_usd item_cndtn_id meta_categ_id bin_rev photo_count count4 ref_price4 ship_time_fastest ship_time_slowest ship_time_chosen using "${root}/anon_bo_lists.dta" if count4 ~=. & count4 >= 20 & item_cndtn_id~=. ,clear
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen		// Imposing sample restrictions
merge 1:1 anon_item_id using `threads_listtab', keep(1 3) gen(thread_merge)		// NB: Keeping the _merge 




* 2: Variable Assembly

gen sold_any = (item_price ~=.)
gen sold_bo = (bo_ck_yn==1)
gen offr_any = (thread_merge == 3)
gen prat = item_price/start_price_usd
gen barg_price = item_price if bo_ck_yn==1
gen brat = barg_price/start_price_usd
gen used = item_cndtn_id >= 3000 if item_cndtn_id ~= .
gen sale_price_over_ref = item_price/ref_price4
gen bargain_price_over_ref = barg_price/ref_price4

// This just indicates that the buyer had a choice about shipping 
gen multiship = ship_time_fastest!=ship_time_slowest & ship_time_fastest>0 & ship_time_slowest>0 & ship_time_fastest!=. & ship_time_slowest!=.	
// This is a dummy for chosing the slowest shiping time, choice or no
gen slow_ship = ship_time_chosen == ship_time_slowest & multiship==1

* 3: Variable Labels

label var start_price_usd "Listing Price"
label var bin_rev "Revised"
label var sold_any "Sold"
label var sold_bo "Sold by Best Offer"
label var offr_any "Received an Offer"
label var item_price "Sale Price"
label var prat "Sale Price / List Price"
label var barg_price "Bargained Price"
label var brat "Bargained Price / List Price"
label var sale_price_over_ref "Sale Price / Reference"
label var bargain_price_over_ref "Bargained Price / Reference"
label var used "Used"
label var photo_count "No. Photos"
label var slow_ship "Slowest shipping"
label var multiship "Multiple shipping options"






* 4: Exporting

eststo S1: estpost tabstat start_price_usd used bin_rev sold_any sold_bo offr_any photo_count multiship slow_ship item_price prat barg_price brat sale_price_over_ref bargain_price_over_ref , statistics(mean sd min max) columns(statistics)
estout S1 using "`sumstats'", replace `tab_settings' stats(N, fmt(%18.0gc) labels(`"No. Listings"')) prehead(\begin{tabular}{l c c c c}\hline \hline & Mean & Std. Dev. & Min & Max \\ \hline \multicolumn{5}{l}{Listing-Level Data} \\)


*********************************
* Sellers
*********************************

* 1: Data Assembly


keep  anon_item_id anon_slr_id item_price bo_ck_yn  fdbk_pstv_start 
//reference sample restriction has been added in last session

* 2: Variable Assembly

gen sold_any = (item_price ~=.)
gen sold_bo = (item_price ~=. & bo_ck_yn == 1)

collapse (max) fdbk_pstv_start (sum) num_sold_any = sold_any num_sold_bo = sold_bo (count) num_lists = anon_item_id, by(anon_slr_id)

egen total_sales = sum(num_sold_any)
gen temp_hhi = (num_sold_any/total_sales)^2
egen sales_hhi = sum(temp_hhi)

// report (from log file) number of observations with missing feedback scores
count if fdbk_pstv_start==.

* 3: Variable Labels

label var fdbk_pstv_start "Feedback Positive Percent"
label var num_lists "No. Listings"
label var num_sold_any "No. Sales"
label var num_sold_bo "No. Sales by Best Offer"

* 4: Exporting

eststo S2: estpost tabstat  fdbk_pstv_start num_lists num_sold_any num_sold_bo, statistics(mean sd min max ) columns(statistics) 
estout S2 using "`sumstats'", append `tab_settings' stats(N, fmt(%18.0gc) labels("No. Sellers")) prehead(\hline \multicolumn{5}{l}{Seller-Level Data} \\)

summ sales_hhi 										// Just keeping this in for the log file; can report or not as desired.

clear

*********************************
* Buyers
*********************************

* 1: Data Assembly
tempfile threads_byrtab
use anon_byr_id offr_type_id anon_item_id using "${root}/anon_bo_threads.dta"
ren anon_byr_id anon_buyer_id

gen byr_offr = offr_type_id ~= 2
collapse (count) num_offrs = byr_offr, by(anon_item_id anon_buyer_id)
collapse (sum) num_offrs (count) num_threads = num_offrs, by(anon_buyer_id) 
save `threads_byrtab'

use anon_item_id anon_buyer_id item_price bo_ck_yn count4 item_cndtn_id if count4 ~=. & count4 >= 20 & item_cndtn_id~=.  using "${root}/anon_bo_lists.dta"
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen		// Imposing sample restrictions
merge m:1 anon_buyer_id using `threads_byrtab', keep(3) nogen 

* 2: Variable Assembly

replace num_offrs = 0 if num_offrs ==.
replace num_threads = 0 if num_threads ==.

gen purch_any = item_price ~=.
gen purch_bo = item_price ~=. & bo_ck == 1

collapse (max) num_offrs num_threads (sum) num_purch_any = purch_any num_purch_bo = purch_bo, by(anon_buyer_id)

egen total_purchases = sum(num_purch_any)
gen temp_hhi = (num_purch_any/total_purchases)^2
egen purch_hhi = sum(temp_hhi)

* 3: Variable Labels

label var num_purch_any "No. Purchases"
label var num_purch_bo "No. Bargained Purchases"
label var num_threads "No. Bargaining Threads"
label var num_offrs "No. Offers"

* 4: Exporting

eststo S3: estpost tabstat num_threads num_offrs num_purch_any num_purch_bo, statistics(mean sd min max) columns(statistics) 
estout S3 using "`sumstats'", append `tab_settings' stats(N, fmt(%18.0gc) labels("No. Buyers")) prehead(\hline \multicolumn{5}{l}{Buyer-Level Data} \\)

summ purch_hhi										// Just keeping this in for the log file; can report or not as desired.

clear

********************************
* Bargaining Threads
*********************************


* 1: Data Assembly
use anon_item_id start_price_usd ref_price4 count4 item_cndtn_id if count4 ~=. & count4 >= 20 & item_cndtn_id~=.  using "${root}/anon_bo_lists.dta"
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen		// Imposing sample restrictions
merge 1:m anon_item_id using "${root}/anon_bo_threads.dta", keep(3) nogen keepus(anon_item_id status_id anon_byr_id src_cre_date offr_price byr_hist slr_hist)


* 2: Variable Assembly

gen accepted = (status_id == 1 | status_id == 9)
sort anon_item_id anon_byr_id src_cre_date
bysort anon_item_id anon_byr_id: gen order = _n
bysort anon_item_id anon_byr_id: gen rounds = _N
bysort anon_item_id anon_byr_id: egen success = max(accepted)
gen round_success = rounds if success == 1


// Replace missing history counts with the counts of the first observation in this thread
sort anon_item_id anon_byr_id src_cre_date
by anon_item_id anon_byr_id: replace byr_hist=byr_hist[1]
by anon_item_id anon_byr_id: replace slr_hist=slr_hist[1]
// Treat other missing _hist as 1 (includes THIS obs)
replace slr_hist=1 if slr_hist==.
replace byr_hist=1 if byr_hist==.



keep if order==1
gen orat = offr_price / start_price_usd
gen first_offer_over_ref = offr_price/ref_price4
drop if orat > 1


// Merge in the overlaps variables
merge 1:1 anon_item_id anon_byr_id using "${derived_data}/byr_overlaps.dta",nogen keep(1 3)
merge 1:1 anon_item_id anon_byr_id using "${derived_data}/slr_overlaps.dta",nogen keep(1 3)
merge 1:1 anon_item_id anon_byr_id using "${derived_data}/item_overlaps.dta",nogen keep(1 3)


replace byr_overlaps  = 0 if byr_overlaps  == .
replace slr_overlaps  = 0 if slr_overlaps  == . 
replace item_overlaps = 0 if item_overlaps == . 


* 3: Variable Labels

label var rounds "No. Offers"
label var success "Agreement Reached"
label var offr_price "First Buyer Offer"
label var orat "First Buyer Offer / List Price"
label var first_offer_over_ref  "First Buyer Offer / Reference"
label var round_success "No. Offers if Sold"

label var slr_hist "Seller Experience"
label var byr_hist "Buyer Experience"
label var byr_overlaps "No. Competing Buyers"
label var slr_overlaps "No. Competing Sellers"
label var item_overlaps "No. Competing Listings"


* 4: Exporting

eststo S4: estpost tabstat rounds round_success success slr_hist  byr_hist  offr_price orat first_offer_over_ref byr_overlaps slr_overlaps item_overlaps, statistics(mean sd min max ) columns(statistics)
estout S4 using "`sumstats'", append `tab_settings' stats(N, fmt(%18.0gc) labels("No. Threads")) prehead(\hline \multicolumn{5}{l}{Thread-Level Data} \\) postfoot(\hline\hline\end{tabular}) 

clear 
log close

exit


