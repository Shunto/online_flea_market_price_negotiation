* Edited by Chuan Yu, Sept 2, 2019

clear all
set more off

do set_globals.do

cap log close
log using "${figtab}/concession_facts.log", replace

/**************************
// The goal of the code below is to fill in the correct numbers for the following setences: 

In the data, among observations in which the seller makes at least two offers (beyond the BIN), 
we observe that only 0.77% of observations involve a seller standing firm at the Buy-it-Now price
for several periods and conceding. In contrast, in 98.8% of the observed sequences the seller’s 
first counteroffer already concedes a bit relative to the Buy-it-Now price. Examining analogous
numbers for buyers, we find that only 0.42% involve concession only suddenly after holding firm
at the previous offer for at least one period, whereas 95.9% involve a buyer conceding gradually.
***************************/ 

// Merge all data
use anon_item_id start_price_usd using "${root}/anon_bo_lists.dta", clear
tempfile lists_needed_variables		
save `lists_needed_variables'
use anon_item_id anon_byr_id offr_type_id status_id offr_price src_cre_date using "${root}/anon_bo_threads.dta", clear
merge m:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen  // Merge our standard listing sample restriction
merge m:1 anon_item_id using `lists_needed_variables', keep(3) nogen      // Merge in lists, keep only if an offer exists

// keep threads that follow 021212
sort anon_item_id anon_byr_id src_cre_date
gen seq = .
by anon_item_id anon_byr_id: replace seq = 1 if _n == 1          & offr_type_id == 0 //PB1
by anon_item_id anon_byr_id: replace seq = 2 if seq[_n - 1] == 1 & offr_type_id == 2 //PS1    
by anon_item_id anon_byr_id: replace seq = 3 if seq[_n - 1] == 2 & offr_type_id == 1 //PB2
by anon_item_id anon_byr_id: replace seq = 4 if seq[_n - 1] == 3 & offr_type_id == 2 //PS2
by anon_item_id anon_byr_id: replace seq = 5 if seq[_n - 1] == 4 & offr_type_id == 1 //PB3
by anon_item_id anon_byr_id: replace seq = 6 if seq[_n - 1] == 5 & offr_type_id == 2 //PS3
drop if seq == .  // Throwing away all offers that do not correspond to the 021212 sequence

by anon_item_id anon_byr_id: gen max_seq = _N
gen success = (status_id == 1 | status_id == 9)

tempfile concede_or_firm
save `concede_or_firm' 


// -----------------------------------------
// SELLER:
// -----------------------------------------
// We do not directly sum up observations where offr_price==start_price_usd because some sellers
// concede first and then return to the BIN price later
use `concede_or_firm', clear
keep if max_seq >= 4

gen tmp_firm1 = (offr_price == start_price_usd & seq == 2) //seller holds firm at first round
gen tmp_firm2 = (offr_price == start_price_usd & seq == 4) //seller holds firm at second round
gen tmp_firm3 = (offr_price == start_price_usd & seq == 6) //seller holds firm at third round
by anon_item_id anon_byr_id: egen slr_firm1 = max(tmp_firm1)
by anon_item_id anon_byr_id: egen slr_firm2 = max(tmp_firm2)
by anon_item_id anon_byr_id: egen slr_firm3 = max(tmp_firm3)

count if seq == 1
local N = r(N)

* 1) calculate whether seller holds FIRM or CONCEDES without considering whether concede in the end
// concede at first round
count if slr_firm1 == 0 & seq == 1
local N1 = r(N)
// firm up to first round, concede at second round
count if slr_firm1 == 1 & slr_firm2 == 0 & seq == 1
local N2 = r(N)
// firm up to second round, concede at third round
count if slr_firm1 == 1 & slr_firm2 == 1 & slr_firm3 == 0 & seq == 1 // this includes being firm at first two rounds and then concede at third round or the trade ends at the second round
local N3 = r(N)

dis `N1' /  `N' * 100
dis (`N2' + `N3') /  `N' * 100

* 2) Now focus on those that eventually concede
// concede in seq2
count if seq == 2 & slr_firm1 == 0
local N2 = r(N)
// firm up to seq2, concede in seq3
count if seq == 3 & slr_firm1 == 1 & success == 1 & offr_price ~= start_price_usd
local N3 = r(N)
// firm up to seq3, concede in seq4
count if seq == 4 & slr_firm1 == 1 & slr_firm2 == 0
local N4 = r(N)
// firm up to seq4, concede in seq5
count if seq == 5 & slr_firm1 == 1 & slr_firm2 == 1 & success == 1 & offr_price ~= start_price_usd
local N5 = r(N)
// firm up to seq5, concede in seq6
count if seq == 6 & slr_firm1 == 1 & slr_firm2 == 1 & slr_firm3 == 0
local N6 = r(N)

dis `N2' /  `N' * 100
dis (`N3' + `N4' + `N5' + `N6') /  `N' * 100
 
 
// -----------------------------------------
// BUYER:
// -----------------------------------------
use `concede_or_firm', clear
keep if max_seq >= 3

by anon_item_id anon_byr_id: gen first_offr =  offr_price[1] // first offer by buyer
gen tmp_firm1 = (offr_price == first_off & seq == 3) //firm at second round
gen tmp_firm2 = (offr_price == first_off & seq == 5) // firm at third round
by anon_item_id anon_byr_id: egen byr_firm1 = max(tmp_firm1)
by anon_item_id anon_byr_id: egen byr_firm2 = max(tmp_firm2)

count if seq == 1
local N = r(N)

* 1) calculate whether buyer holds FIRM or CONCEDES without considering whether concede in the end
// concede at first round
count if byr_firm1 == 0 & seq == 1    
local N1 = r(N)  
// firm up to first round, concede at second round
count if byr_firm1 == 1 & byr_firm2 == 0 & seq == 1 
local N2 = r(N)

dis `N1' /  `N' * 100
dis `N2' /  `N' * 100

* 2) Now focus on those that eventually concede
// concede in seq3
count if seq == 3 & byr_firm1 == 0
local N3 = r(N)
// firm up to seq3, concede in seq4
count if seq == 4 & byr_firm1 == 1 & success == 1 & offr_price != offr_price[_n - 1]
local N4 = r(N)
// firm up to seq4, concede in seq5
count if seq == 5 & byr_firm1 == 1 & byr_firm2 == 0
local N5 = r(N)
// firm up to seq5, concede in seq6
count if seq == 6 & byr_firm1 == 1 & byr_firm2 == 1 & success == 1 & offr_price != offr_price[_n - 1]
local N6 = r(N)

dis `N3' /  `N' * 100
dis (`N4' + `N5' + `N6') /  `N' * 100
 
log close 
