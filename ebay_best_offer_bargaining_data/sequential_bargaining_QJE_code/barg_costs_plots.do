set more off
clear
clear matrix
estimates clear
graph drop _all

set seed 90210

do set_globals.do


*************************
* Grabbing Offer Data
*************************

use "${root}/anon_bo_threads.dta"								// Grabbing Threads
sort anon_item_id anon_byr_id src_cre_date							// Sorting so we can order offers
bysort anon_item_id anon_byr_id: gen order = _n							// order is the temporal sequence of offers within a thread
bysort anon_item_id anon_byr_id: gen rounds = _N						// rounds is the total number of offers in a thread
keep if order == 1										// Keeping just the first one in a thread (it always exists, so we're not losing any threads)
gen first_accepted = (status_id == 1 | status_id == 9)						// Dummy for whether the first offer in the thread was accepted
ren offr_price first_offer									// renaming it because the sample structure changed the meaning
keep anon_item_id first_accepted first_offer rounds						// shrinking to save
gen threads = 1											// This is just a dummy for summing over in the collapse
collapse (max) first_accepted (mean) first_offer rounds (count) threads, by(anon_item_id)	// Note: now first offer is the mean of the first offer within thread; same for rounds
tempfile first_offers
save `first_offers'										// Remember that the unit of observation now is anon_item_id
clear

*************************
* Merging with Listing Data
*************************

use start_price_usd item_price bo_ck_yn anon_item_id using "${root}/anon_bo_lists.dta"	
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen

gen price_bin = ceil(start_price_usd / 50)
bysort price_bin: sample 10000, count

merge 1:1 anon_item_id using `first_offers', keep(1 3)

gen sold_any = item_price ~=.
gen sold_bo = item_price ~=. & bo_ck_yn == 1
gen prat = item_price / start_price_usd
gen brat = item_price / start_price_usd if bo_ck == 1
gen orat = first_offer / start_price_usd 
gen any_offer = orat ~=.
gen log_start_price_usd = log(start_price_usd)

drop if prat > 1 & prat ~=.
drop if brat > 1 & brat ~=.
drop if orat > 1 & orat ~=.

tempfile pictures_subsample
save `pictures_subsample'


*************************
* Do main plots for bargaining cost section
*************************

use start_price_usd anon_item_id using "${root}/anon_bo_lists.dta", clear
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen

tw (histogram start_price_usd, bin(100)), xtitle("Listing Price",size(large)) ylab(#10, angle(0) grid labsize(large)) xlab(,labsize(large)) /*
*/plotregion(fcolor(white) lcolor(white)) graphregion(fcolor(white) lcolor(white)) ytitle(Fraction of Listings,size(large))
graph export "${figtab}/hist_list_prices_sample.png", replace

clear
graph drop _all

use `pictures_subsample'

keep any_offer sold_any sold_bo first_accepted bo_ck threads rounds orat brat prat start_price_usd

tw (histogram start_price_usd, bin(20)), xtitle("Listing Price") ylab(#10, angle(0) grid labsize(large)) plotregion(fcolor(white) lcolor(white)) /*
*/xlab(,labsize(large)) graphregion(fcolor(white) lcolor(white)) ytitle(Fraction of Listings)

graph export "${figtab}/hist_list_prices_subsample20.png", replace

tw (histogram start_price_usd, bin(100)), xtitle("Listing Price") ylab(#10, angle(0) grid labsize(large)) plotregion(fcolor(white) lcolor(white)) /*
*/xlab(,labsize(large)) graphregion(fcolor(white) lcolor(white)) ytitle(Fraction of Listings)
graph export "${figtab}/hist_list_prices_subsample100.png", replace

local bin_graph_opts legend(off) xtitle("Listing Price",size(large)) ylab(#10, angle(0) grid labsize(large)) xlab(,labsize(large)) /*
*/plotregion(fcolor(white) lcolor(white)) graphregion(fcolor(white) lcolor(white))


foreach prob_depvar in any_offer sold_any sold_bo first_accepted bo_ck{

tw (lowess `prob_depvar' start_price_usd), `bin_graph_opts' ytitle("Probability",size(large)) 
graph export "${figtab}/lowess_`prob_depvar'.png", replace
graph drop _all
}

foreach num_depvar in threads rounds{
tw (lowess `num_depvar' start_price_usd), `bin_graph_opts' ytitle("Number",size(large))
graph export "${figtab}/lowess_`num_depvar'.png", replace
graph drop _all
}

foreach frac_depvar in orat brat prat{
tw (lowess `frac_depvar' start_price_usd), `bin_graph_opts' ytitle("Fraction of Listing Price",size(large))
graph export "${figtab}/lowess_`frac_depvar'.png", replace
graph drop _all
}

