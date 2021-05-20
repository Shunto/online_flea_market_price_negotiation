// Analysis of competition and cases where same buyer interacts with multiple sellers, same seller interacts with multiple buyers,etc. 

* Within the thread data, compute
*a. How often are buyers bargaining with two different sellers at the same time (or in an overlapping time frame)? How about sellers with two different buyers?
*b. How often does a bargaining session end in disagreement and then the buyer turns to another seller? When that does happen, what is the average time between when the buyer finished bargaining with one seller and starts with another? 
*c. How often are there repeat interactions between the same buyer and same seller? 

* Carol Lu, Yuki Song, Brad Larsen, Chuan Yu

clear all
set more off
do set_globals.do

cap log close
log using "${figtab}/competition_facts.log",replace

/**************************
The goal of this code is to generate the correct numbers for these sentences in the paper: 

In our data we see 14.2% of bargaining threads in which the seller has offers from multiple buyers
that overlap in time; that is, the window of time in which the seller bargained with one buyer
overlaps the window in which she bargains with another distinct buyer. One the buyer side, we see
24.3% of threads in which the buyer is bargaining with more than one seller of the same cataloged
product at the same time. When a buyer fails to reach agreement with a seller, in 2.0% of threads
the buyer trades with another seller of the same product within a day’s time.

A related interesting statistic is the fraction of repeat interactions by the same buyer and seller
pair. We find that 9% of buyer-seller pairs meet in at least two separate bargaining threads. Together,
these repeat buyer-seller pairs constitute 23.5% of the interactions in the data. This feature is another
interesting aspect that could be exploited in future research with our public dataset to study, for example,
reputation-building and learning in bargaining.

NOTE: This file uses a similar approach as competition.do, but that file is concerned only with the reference price sample, 
which is the sample we use in our regressions with normalized price as the LHS variable. This file computes facts using 
the FULL SAMPLE where possible (such as for the number of competing buyers), and for facts requiring product_ids I don't 
limit to product_ids where count4>=20 as we do in the reference price sample.
***************************/ 


// Merge all data
use anon_item_id anon_slr_id anon_product_id using "${root}/anon_bo_lists.dta", clear
tempfile lists_needed_variables		
save `lists_needed_variables'
use anon_item_id anon_byr_id offr_type_id status_id offr_price src_cre_date response_time status_id using "${root}/anon_bo_threads.dta" 
merge m:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen  // Merge our standard listing sample restriction
merge m:1 anon_item_id using `lists_needed_variables', keep(3) nogen      // Merge in lists, keep only if an offer exists

// Assemble variables
replace response_time = . if status_id == 7
sort anon_item_id anon_byr_id src_cre_date	
by anon_item_id anon_byr_id: gen order = _n	
by anon_item_id anon_byr_id: gen round = _N
gen success = (status_id == 1 | status_id == 9)
by anon_item_id anon_byr_id: egen sold = max(success)
by anon_item_id anon_byr_id: egen count_byr_declined = sum(status_id == 8)
// Generate start and end time of a bargaining
by anon_item_id anon_byr_id: gen start = src_cre_date[1]
by anon_item_id anon_byr_id: gen end = response_time[_N]
format start end %tc
tempfile offer
save `offer'
keep if order == 1 // keep one observation for each bargaining
tempfile bargaining
save `bargaining'

* Calculating frequency of simultaneity, swiftness of switch, and repeated interaction

**********************************************************************************
* a. How often are buyers bargaining with two different sellers at the same time (in an overlapping time frame)? 
*	 How about sellers with two different buyers?
**********************************************************************************

// fraction of threads/items where seller bargains with multiple buyers simultaneously (in an overlapping time frame)
use `bargaining', clear
sort anon_item_id start end anon_byr_id
by anon_item_id: gen overlap_thread = (start < end[_n - 1] & _n != 1) | (end > start[_n + 1] & _n != _N)
by anon_item_id: egen overlap_item = max(overlap_thread)
gen total_threads = _N
egen total_overlapped_threads = sum(overlap_thread)
duplicates drop anon_item_id, force
gen total_items = _N
egen total_overlapped_items = sum(overlap_item)
sum total_threads total_overlapped_threads total_items total_overlapped_items
dis total_overlapped_threads[1] / total_threads[1]
dis total_overlapped_items[1] / total_items[1]

// fraction of threads where a buyer is declined because of seller accepting an offer from another buyer
use `bargaining', clear
gen declined_thread = (count_byr_declined > 0)
by anon_item_id: egen declined_item = max(declined_thread)
gen total_threads = _N
egen total_declined_threads = sum(declined_thread)
sum declined_thread
duplicates drop anon_item_id, force
gen total_items = _N
egen total_declined_items = sum(declined_item)
sum total_threads total_declined_threads total_items total_declined_items
dis total_declined_threads[1] / total_threads[1]
dis total_declined_items[1] / total_items[1]

// fraction of threads/items where buyer bargains with multiple sellers simultaneously (in an overlapping time frame for same product_id)
use `bargaining', clear
sort anon_byr_id anon_product_id start end anon_item_id
by anon_byr_id anon_product_id: gen overlap_thread = (start < end[_n - 1] & _n != 1 & anon_product_id != .) | ///
  (end > start[_n + 1] & _n != _N & anon_product_id != .)
by anon_byr_id anon_product_id: egen overlap_item = max(overlap_thread)
gen total_threads = _N
count if anon_product_id != .
gen total_threads_nonmissing_product = r(N)
egen total_overlapped_threads = sum(overlap_thread)
duplicates drop anon_byr_id anon_product_id, force
gen total_items = _N
count if anon_product_id != .
gen total_items_nonmissing_product = r(N)
egen total_overlapped_items = sum(overlap_item)
sum total_threads total_threads_nonmissing_product total_overlapped_threads total_items total_items_nonmissing_product total_overlapped_items
dis total_overlapped_threads[1] / total_threads[1]
dis total_overlapped_threads[1] / total_threads_nonmissing_product[1]
dis total_overlapped_items[1] / total_items[1]
dis total_overlapped_items[1] / total_items_nonmissing_product[1]

***********************************************************************************
* b. How often does a bargaining session end in disagreement and then the buyer turns to another seller selling the same product? 
*    When that does happen, what is the average time between when the buyer finished bargaining with one seller and starts with another? 
***********************************************************************************

use `bargaining', clear
sort anon_byr_id anon_product_id start end anon_item_id
gen total_threads = _N
count if anon_product_id != .
gen total_threads_nonmissing_product = r(N)
by anon_byr_id anon_product_id: gen gap = (start - end[_n - 1]) / 1000 / 3600 if sold[_n - 1] == 0 // in hours	
replace gap = . if gap < 0
replace gap = . if anon_product_id == .
gen gap_day = (gap <= 24 & gap >= 0)
egen total_gap_day = sum(gap_day)
sum total_threads total_threads_nonmissing_product gap total_gap_day
dis total_gap_day / total_threads
dis total_gap_day / total_threads_nonmissing_product

***********************************************************************************
* c. How often are there repeated interactions between the same buyer and same seller? 
***********************************************************************************

use `bargaining', clear
sort anon_slr_id anon_byr_id
by anon_slr_id anon_byr_id: gen times = _N
keep anon_slr_id anon_byr_id times
duplicates drop //a unique list of buyer-seller pairs that ever interacted

// Fraction of pairs who see each other more than once
gen repeated = (times >= 2)
sum repeated

//fraction of bargaining threads made up of pairs who have seen each other more than once
egen repeated_threads = sum(times * repeated)
egen all_threads = sum(times)
gen fraction = repeated_threads / all_threads  
sum fraction

***********************************************************************************
* d. How often are buyers bargaining with two different sellers at the same time (in an overlapping time frame)? 
*	 How about sellers with two different buyers? Use new definition of a thread (mini-thread)
*    A thread is divided into mini-threads if there are declines/expires in the middle of the thread
***********************************************************************************
use `offer', clear
// Generate mini-threads
sort anon_item_id anon_byr_id src_cre_date
by anon_item_id anon_byr_id: gen new = (_n == 1)
by anon_item_id anon_byr_id: replace new = 1 if inlist(status_id[_n - 1], 0, 2, 6, 8) // A new mini-thread begins if the offer is declined or expires
by anon_item_id anon_byr_id: replace new = 1 if (src_cre_date - src_cre_date[_n - 1]) / 1000 / 3600 >= 48 // A new mini-thread begins if the offer has been made for 48 hours
by anon_item_id anon_byr_id: gen thread = sum(new) //The order of the mini-thread within a full thread

sort anon_item_id anon_byr_id thread src_cre_date
by anon_item_id anon_byr_id thread: gen order_new = _n
by anon_item_id anon_byr_id thread: egen count_byr_declined_new = sum(status_id == 8)
by anon_item_id anon_byr_id thread: gen double start_new = src_cre_date
by anon_item_id anon_byr_id thread: gen double end_new = response_time[_N]
format start_new end_new %tc
keep if order_new == 1 // keep one observation for each mini-thread
tempfile bargaining_new
save `bargaining_new'

// fraction of threads/items where seller bargains with multiple buyers simultaneously (in an overlapping time frame)
use `bargaining_new', clear
sort anon_item_id start_new end_new anon_byr_id thread
by anon_item_id: gen overlap_thread = (start_new < end_new[_n - 1] & _n != 1) | (end_new > start_new[_n + 1] & _n != _N)
by anon_item_id: egen overlap_item = max(overlap_thread)
gen total_threads = _N
egen total_overlapped_threads = sum(overlap_thread)
duplicates drop anon_item_id, force
gen total_items = _N
egen total_overlapped_items = sum(overlap_item)
sum total_threads total_overlapped_threads total_items total_overlapped_items
dis total_overlapped_threads[1] / total_threads[1]
dis total_overlapped_items[1] / total_items[1]

// fraction of threads where a buyer is declined because of seller accepting an offer from another buyer
use `bargaining_new', clear
gen declined_thread = (count_byr_declined_new > 0)
by anon_item_id: egen declined_item = max(declined_thread)
gen total_threads = _N
egen total_declined_threads = sum(declined_thread)
sum declined_thread
duplicates drop anon_item_id, force
gen total_items = _N
egen total_declined_items = sum(declined_item)
sum total_threads total_declined_threads total_items total_declined_items
dis total_declined_threads[1] / total_threads[1]
dis total_declined_items[1] / total_items[1]

// fraction of threads/items where buyer bargains with multiple sellers simultaneously (in an overlapping time frame for same product_id)
use `bargaining_new', clear
sort anon_byr_id anon_product_id start_new end_new anon_item_id thread
by anon_byr_id anon_product_id: gen overlap_thread = (start_new < end_new[_n - 1] & _n != 1 & anon_product_id != .) | ///
  (end_new > start_new[_n + 1] & _n != _N & anon_product_id != .)
by anon_byr_id anon_product_id: egen overlap_item = max(overlap_thread)
gen total_threads = _N
count if anon_product_id != .
gen total_threads_nonmissing_product = r(N)
egen total_overlapped_threads = sum(overlap_thread)
duplicates drop anon_byr_id anon_product_id, force
gen total_items = _N
count if anon_product_id != .
gen total_items_nonmissing_product = r(N)
egen total_overlapped_items = sum(overlap_item)
sum total_threads total_threads_nonmissing_product total_overlapped_threads total_items total_items_nonmissing_product total_overlapped_items
dis total_overlapped_threads[1] / total_threads[1]
dis total_overlapped_threads[1] / total_threads_nonmissing_product[1]
dis total_overlapped_items[1] / total_items[1]
dis total_overlapped_items[1] / total_items_nonmissing_product[1]


log close
