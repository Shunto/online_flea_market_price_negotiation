// Creates summary stats (means only) by category for the listing-level and thread-level panels 

clear
set more off
estimates clear

do set_globals.do

log using "${figtab}/sumstats_cat.log",replace

local sumstats "${figtab}/sumstats_cat.tex"

local tab_settings cells("mean(fmt(%18.3gc))") varwidth(20) modelwidth(12) nonumbers delimiter(&) end(\\) posthead("\hline")  label varlabels(_cons Constant) mlabels(none) collabels(none) eqlabels(none) substitute("$" "\\$" " .&" " -&" "(.)" "") notype level(95) style(tex)


//add variable new_cat to list level data, which facilitates description by category

use "${root}/anon_bo_lists.dta"

// Define categories, grouping together similar meta categories
tempfile anon_bo_lists_cat
gen new_cat = 7
replace new_cat = 1 if meta_categ_id==1 | meta_categ_id==260  | meta_categ_id==550 | meta_categ_id==870 | meta_categ_id==11116 | meta_categ_id==14339 | meta_categ_id==20081 | meta_categ_id==45100 | meta_categ_id==64482 | meta_categ_id==172008
replace new_cat = 2 if meta_categ_id==293 | meta_categ_id==619 | meta_categ_id==625 | meta_categ_id==1249 | meta_categ_id==15032 | meta_categ_id==58058
replace new_cat = 3 if meta_categ_id==281 | meta_categ_id==11450 | meta_categ_id==26395 
replace new_cat = 4 if meta_categ_id==267 | meta_categ_id==11232 | meta_categ_id==11233
replace new_cat = 5 if meta_categ_id==220 | meta_categ_id==237 | meta_categ_id==888
replace new_cat = 6 if meta_categ_id==12576

label define new_cat 7	"Other	" 1	"	Collectibles	" 	2	"	Electronics	" 	3	"	Fashion	" 	4	"	Media	" 	5	"	Toys	" 	6	"	Business	"
label values new_cat new_cat
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen		// Imposing sample restrictions

save `anon_bo_lists_cat'

*********************************
* Listings
*********************************

* 1: Data Assembly

// A list of anon_item_ids that show up in the threads data
tempfile threads_listtab				
use anon_item_id using "${root}/anon_bo_threads.dta"
bys anon_item_id: gen id_order = _n
keep if id_order==1
save `threads_listtab'

// generate indicator for whether the listing ever received an offer
use anon_item_id item_price bo_ck_yn start_price_usd item_cndtn_id meta_categ_id bin_rev photo_count new_cat using `anon_bo_lists_cat', clear
merge 1:1 anon_item_id using `threads_listtab', keep(1 3) gen(thread_merge)		


* 2: Variable Assembly

gen sold_any = (item_price ~=.)
gen sold_bo = (bo_ck_yn==1)
gen offr_any = (thread_merge == 3)
gen prat = item_price/start_price_usd
gen barg_price = item_price if bo_ck_yn==1
gen brat = barg_price/start_price_usd
gen used = item_cndtn_id >= 3000 if item_cndtn_id ~= .


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
label var used "Used"
label var photo_count "No. Photos"

* 4: Exporting

// Export full sample 
eststo : estpost tabstat start_price_usd used bin_rev sold_any sold_bo offr_any photo_count item_price prat barg_price brat, statistics(mean) c(s)  

// Export results by category
bys new_cat : eststo : estpost tabstat start_price_usd used bin_rev sold_any sold_bo offr_any photo_count item_price prat barg_price brat ,statistics(mean) c(s) 
estout * using "`sumstats'", replace `tab_settings' stats(N, fmt(%18.0gc) labels(`"No. Listings"')) prehead(\begin{tabular}{l c c c c c c c c }\hline \hline & Full sample  & Collectibles &  Electronics & Fashion& Media& Toys& Business & Others \\ \hline \multicolumn{9}{l}{Listing-Level Data} \\)

eststo clear
clear


********************************
* Bargaining Threads
*********************************

* 1: Data Assembly

use anon_item_id status_id anon_byr_id src_cre_date offr_price byr_hist slr_hist using "${root}/anon_bo_threads.dta"   
merge m:1 anon_item_id using `anon_bo_lists_cat'  , keepus(anon_item_id start_price_usd new_cat )
merge m:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen		// Imposing sample restrictions

* 2: Variable Assembly

gen accepted = (status_id == 1 | status_id == 9)
sort anon_item_id anon_byr_id src_cre_date
bysort anon_item_id anon_byr_id: gen order = _n
bysort anon_item_id anon_byr_id: gen rounds = _N
bysort anon_item_id anon_byr_id: egen success = max(accepted)


// Replace missing history counts with the counts of the first observation in this thread
sort anon_item_id anon_byr_id src_cre_date
by anon_item_id anon_byr_id: replace byr_hist=byr_hist[1]
by anon_item_id anon_byr_id: replace slr_hist=slr_hist[1]
// Treat other missing _hist as 1 (includes THIS obs)
replace slr_hist=1 if slr_hist==.
replace byr_hist=1 if byr_hist==.

keep if order==1								 
gen orat = offr_price / start_price_usd
gen round_success = rounds if success == 1

drop if orat > 1



* 3: Variable Labels

label var rounds "No. Offers"
label var success "Agreement Reached"
label var offr_price "First Buyer Offer"
label var orat "First Buyer Offer / List Price"
label var round_success "No. Offers if Sold"
label var slr_hist "Seller Experience"
label var byr_hist "Buyer Experience"

* 4: Exporting

// Export full sample
eststo : estpost tabstat rounds round_success success slr_hist  byr_hist  offr_price orat, statistics(mean) columns(statistics) 

// Export by category
bys new_cat : eststo : estpost tabstat rounds round_success success slr_hist  byr_hist  offr_price orat, statistics(mean) columns(statistics) 
estout * using "`sumstats'", append `tab_settings' stats(N, fmt(%18.0gc) labels("No. Threads")) prehead(\hline \multicolumn{9}{l}{Thread-Level Data} \\) postfoot(\hline\hline\end{tabular}) 
clear
log close 
exit


