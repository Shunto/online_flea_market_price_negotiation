
* Creates summary stats table comparing listings that received some offer to those that did not
* Carol Lu, Yuki Song, Brad Larsen

do set_globals.do

log using "${figtab}/sumstats_offer_not.log", replace

set more off
local tab_settings cells("mean(fmt(%18.3gc))") varwidth(20) modelwidth(12) nonumbers delimiter(&) end(\\) posthead("\hline")  label varlabels(_cons Constant) mlabels(none) collabels(none) eqlabels(none) substitute("$" "\\$" " .&" " -&" "(.)" "") notype level(95) style(tex)
local sumstats ${figtab}/sumstats_offer_not.tex

*extract the required variables in lists data, add (receive offer or not), and impose sample restriction
tempfile threads_listtab
use anon_item_id using "${root}/anon_bo_threads.dta"
bys anon_item_id : gen id_order = _n
keep if id_order ==1		
save `threads_listtab'

tempfile anon_bo_lists_temp
use anon_item_id anon_slr_id anon_buyer_id  fdbk_score_start fdbk_pstv_start start_price_usd item_cndtn_id item_price bo_ck_yn bin_rev count4 photo_count  using "${root}/anon_bo_lists.dta"
merge 1:1 anon_item_id using `threads_listtab', keep(1 3) gen(thread_merge)	// add the indicator for whether received an offer (from threads record)

replace thread_merge = 0 if thread_merge==3  						//now 1 for no receive, 0 for receive - received column appears before the other

drop if bo_ck_yn==1& thread_merge==1 								// Drops 0.63% of cases that  receive no offer in threads dataset but bo_ck_yn==1
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen		// Imposing sample restrictions
save `anon_bo_lists_temp', replace				
		

clear

*********************************
* Listings
*********************************

* 1: Data Assembly

use anon_item_id item_price bo_ck_yn start_price_usd item_cndtn_id  bin_rev photo_count thread_merge using `anon_bo_lists_temp',clear

* 2: Variable Assembly

gen sold_any = (item_price ~=.)
gen sold_bo = (bo_ck_yn==1)
gen used = item_cndtn_id >= 3000 if item_cndtn_id ~= .
//the following are not used in Table 2; these are reserved in case called upon.
gen prat = item_price/start_price_usd
gen barg_price = item_price if bo_ck_yn==1
gen brat = barg_price/start_price_usd

* 3: Variable Labels

label var start_price_usd "Listing Price"
label var bin_rev "Revised"
label var sold_any "Sold"
label var sold_bo "Sold by Best Offer"
label var item_price "Sale Price"
label var prat "Sale Price / List Price"
label var barg_price "Bargained Price"
label var brat "Bargained Price / List Price"
label var used "Used"
label var photo_count "No. Photos"

* 4: Exporting
eststo clear

// full sample 
eststo : estpost tabstat start_price_usd used bin_rev sold_any photo_count item_price prat, statistics(mean) c(s)  

// by whether or not received an offer: 
bys thread_merge : eststo : estpost tabstat start_price_usd used bin_rev sold_any photo_count item_price prat,statistics(mean) c(s) 
estout * using "`sumstats'", replace `tab_settings' stats(N, fmt(%18.0gc) labels(`"No. Listings"')) prehead(\begin{tabular}{l c c c }\hline \hline & Full sample & Received at least  & Never received  \\  & & one offer & any offer \\ \hline \multicolumn{4}{l}{Listing-Level Data} \\)

eststo clear
clear

*********************************
* Sellers
*********************************

use anon_item_id anon_slr_id item_price bo_ck_yn  fdbk_pstv_start thread_merge using `anon_bo_lists_temp'

gen sold_any = (item_price ~=.)
gen sold_bo = (item_price ~=. & bo_ck_yn == 1)

// 1. full sample -- output the means of variables for full sample 
preserve

collapse (max) fdbk_pstv_start (sum) num_sold_any = sold_any num_sold_bo = sold_bo (count) num_lists = anon_item_id, by(anon_slr_id)

label var fdbk_pstv_start "Feedback Positive Percent"
label var num_lists "No. Listings"
label var num_sold_any "No. Sales"
label var num_sold_bo "No. Sales by Best Offer"

eststo : estpost tabstat fdbk_pstv_start num_lists num_sold_any, statistics(mean) columns(statistics) 
restore

// 2. Now do separately for whether received an offer or not 
collapse (max) fdbk_pstv_start (sum) num_sold_any = sold_any num_sold_bo = sold_bo (count) num_lists = anon_item_id, by(anon_slr_id thread_merge )

label var fdbk_pstv_start "Feedpack Postitive Percent"
label var num_lists "No. Listings"
label var num_sold_any "No. Sales"
label var num_sold_bo "No. Sales by Best Offer"

bys thread_merge : eststo : estpost tabstat fdbk_pstv_start num_lists num_sold_any, statistics(mean) columns(statistics) 

estout * using "`sumstats'", append `tab_settings' stats(N, fmt(%18.0gc) labels("No. Sellers")) prehead(\hline \multicolumn{4}{l}{Seller-Level Data} \\)
eststo clear

clear

*********************************
* Buyers
*********************************

tempfile threads_byrtab
use anon_byr_id offr_type_id anon_item_id  using "${root}/anon_bo_threads.dta"
ren anon_byr_id anon_buyer_id
gen byr_offr = offr_type_id ~= 2
collapse (count) num_offrs = byr_offr, by(anon_item_id anon_buyer_id)
collapse (sum) num_offrs (count) num_threads = num_offrs, by(anon_buyer_id) 
save `threads_byrtab'

use anon_item_id anon_buyer_id item_price bo_ck_yn thread_merge using `anon_bo_lists_temp'
merge m:1 anon_buyer_id using `threads_byrtab', keep(3) nogen 

replace num_offrs = 0 if num_offrs ==.
replace num_threads = 0 if num_threads ==.

gen purch_any = item_price ~=.
gen purch_bo = item_price ~=. & bo_ck_yn == 1

// 1. full sample -- output the means of variables for full sample 
preserve
collapse (max) num_offrs num_threads (sum) num_purch_any = purch_any num_purch_bo = purch_bo, by(anon_buyer_id)

label var num_purch_any "No. Purchases"
label var num_purch_bo "No. Bargained Purchases"
label var num_threads "No. Bargaining Threads"
label var num_offrs "No. Offers"

eststo : estpost tabstat num_purch_any , statistics(mean) columns(statistics) 
restore

// 2. Now do separately for whether received an offer or not 
collapse (max) num_offrs num_threads (sum) num_purch_any = purch_any num_purch_bo = purch_bo, by(anon_buyer_id thread_merge)

label var num_purch_any "No. Purchases"
label var num_purch_bo "No. Bargained Purchases"
label var num_threads "No. Bargaining Threads"
label var num_offrs "No. Offers"

bys thread_merge: eststo : estpost tabstat num_purch_any , statistics(mean) columns(statistics) 
estout * using "`sumstats'", append `tab_settings' stats(N, fmt(%18.0gc) labels("No. Buyers")) prehead(\hline \multicolumn{4}{l}{Buyer-Level Data} \\) postfoot(\hline\hline\end{tabular}) 

clear

log close _all


