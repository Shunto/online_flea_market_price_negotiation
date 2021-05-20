* This dofile generates sample_id_list.dta, the sample of listings that we will use for the paper.
*
* The basic premise here is that all of our sample restrictions should be imposed on the dataset of *listings*
* Therefore, if we want to eliminate certain wacky offers, we will eliminate the entire listing on which those wacky offers were made.
* This makes it easier to have a single sample across the multiple dimensions of our dataset.
*
* MRB Sept 2016
* 
* Updated to add T5. Also made minor changes to improve speed
* BL Aug 2019

clear
set more off

do set_globals.do

local tab_settings cells("sum(fmt(a3)) mean(fmt(a3))") varwidth(20) modelwidth(12) nonumbers delimiter(&) end(\\) posthead("\hline")  label varlabels(_cons Constant) mlabels(none) collabels(none) eqlabels(none) substitute("$" "\\$" " .&" " -&" "(.)" "") notype level(95) style(tex)

// Save a temporary version of threads file with only the variables we need to merge in later
tempfile threads_needed_variables			
use anon_item_id anon_byr_id src_cre_date offr_price offr_type_id status_id using "${root}/anon_bo_threads.dta"
save `threads_needed_variables'
clear


*********************************************
* Restrictions on Listing Attributes
*********************************************

* (L1) listing price must be under 1k
* (L2) sale price must be at or under the listing price

*** LOADING DATA
use anon_item_id start_price_usd item_price using "${root}/anon_bo_lists.dta"

*** RESTRICTION (L1)
gen crit_1k = (start_price_usd > 1000)						

*** RESTRICTION (L2)
gen crit_price = (item_price > start_price_usd & item_price ~= .)		// NB: we need the second term because item_price is set to infinity if item_price==.

*********************************************
* Restrictions on Thread Attributes
*********************************************


* (T1) all offers must be at or under the listing price
* (T2) no more than three buyer or seller offers
* (T3) countered offers have a counter in the dataset
* (T4) accepted offers end a thread
* (T5) drop any duplicates at the anon_item_id anon_byr_id src_cre_date level

*** LOADING DATA
merge 1:m anon_item_id using `threads_needed_variables', keep(1 3) nogen
sort anon_item_id anon_byr_id src_cre_date
by anon_item_id anon_byr_id: gen order = _n

*** RESTRICTION (T1)
gen high_offr = offr_price > start_price_usd & offr_price ~= .				// Offer too high (and nonnull!)
by anon_item_id: egen crit_offr = max(high_offr==1)					// Converting to listing level
drop high_offr

*** RESTRICTION (T2)
by anon_item_id anon_byr_id: egen byr_offrs = sum(offr_type_id==0 | offr_type_id==1) 	// Number of buyer offers
by anon_item_id: egen crit_numoff_byr = max(byr_offrs > 3)				// Implementing at listing level
drop byr_offrs
by anon_item_id anon_byr_id: egen slr_offrs = sum(offr_type_id==2)			// Number of seller offers
by anon_item_id: egen crit_numoff_slr = max(slr_offrs > 3)				// Implementing at listing level
drop slr_offrs

*** RESTRICTION (T3)
by anon_item_id anon_byr_id: gen b2s = ((offr_type_id == 0 | offr_type_id == 1) & offr_type_id[_n+1] ~= 2) if status_id == 7	// b2s violation: buyer was countered, but no observed seller counter
by anon_item_id anon_byr_id: gen s2b = (offr_type_id == 2 & offr_type_id[_n+1] ~= 1) if status_id == 7				// s2b violation: seller was countered, but no observed buyer counter
gen missing_counter = (b2s == 1 | s2b == 1)											// Dummy for either violation
by anon_item_id: egen crit_counter = max(missing_counter==1)									// Converting to listing level
drop missing_counter b2s s2b 

*** RESTRICTION (T4)
by anon_item_id anon_byr_id: gen accept_notlast = order ~= _N if status_id == 1 | status_id == 9				// An offer was accepted but not last in the sequence
by anon_item_id: egen crit_accept = max(accept_notlast == 1)									// converting to listing level
drop accept_notlast

*** RESTRICTION (T5)
// flag duplicates at the item buyer timing-of-offer level
duplicates tag anon_item_id anon_byr_id src_cre_date, gen(dup)
by anon_item_id: egen crit_duplicate_time = max(dup > 0)
drop dup


********************************************
* The Sample
********************************************

gen sample = (crit_1k + crit_price + crit_offr + crit_numoff_byr + crit_numoff_slr + crit_counter + crit_accept + crit_duplicate_time == 0)

*********************************************
* Tabulating for the log file (we should include in an appendix)
*********************************************

collapse (max) sample crit_*, by(anon_item_id)


label var crit_1k "L1"
label var crit_price "L2"
label var crit_offr "T1"
label var crit_numoff_byr "T2 - buyer"
label var crit_numoff_slr "T2 - seller"
label var crit_counter "T3"
label var crit_accept "T4"
label var crit_duplicate_time "T5"

eststo T1: estpost tabstat crit_*, statistics(sum mean) columns(statistics)
qui sum sample if sample==1
estadd scalar npost = r(N)
estout T1 using "${figtab}/sample_drops_summary.tex", replace `tab_settings' stats(N npost, fmt(%18.0g %18.0g) labels("No. Listings Before" "No. Listings After")) prehead(\begin{tabular}{l c c}\hline \hline & No. Violations & Fraction of Listings \\ \hline\\) postfoot(\hline\hline\end{tabular})

*********************************************
* Exporting Listing IDs
*********************************************

keep if sample == 1
keep anon_item_id

save "${derived_data}/sample_id_list.dta", replace

