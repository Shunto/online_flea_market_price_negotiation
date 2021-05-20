/* create price convergence plots */
* Brad Larsen
* June 17 2019
* keep threads that follow 021212
* July 8 2019 Yuyang
* Updated by Brad, Aug 2019
* Edited to simplify code by Chuan Yu, August 28, 2019

clear all
set more off
set scheme s1mono

do set_globals.do

// Define program for plotting figures
program plot_figure
    syntax, name(string) max_y(string)

    reg of_p offer_num_player if seller_turn == 1
    local coef_s = round(_b[offer_num_player], .01)
    reg of_p offer_num_player if seller_turn == 0
    local coef_b = round(_b[offer_num_player], .01)
    collapse (mean) of_p, by(seller_turn event_num)
    graph twoway (connected of_p event_num if seller_turn == 1, msize(medlarge) msymbol(O) mcolor(black) lp(dash)) ///
                 (connected of_p event_num if seller_turn == 0, msize(medlarge) msymbol(O) mcolor(black) lp(dash)), ///
      text(50 0 "Seller per-offer change: `coef_s'", place(ne) size(large)) ///
      text(30 0 "Buyer per-offer change: `coef_b'",  place(se) size(large)) ///
      xlab(, labsize(large)) ylab(0(50)`max_y', labsize(large)) ///
      ytitle("Offer amount", size(large)) xtitle("") legend(off)
    graph export "${figtab}/`name'.pdf", replace
end


// Merge all data	
use anon_item_id start_price_usd using "${root}/anon_bo_lists.dta"
tempfile lists_needed_variables		
save `lists_needed_variables'
use anon_item_id anon_byr_id offr_type_id status_id offr_price src_cre_date response_time using "${root}/anon_bo_threads.dta", clear
merge m:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen  // Merge our standard listing sample restriction
merge m:1 anon_item_id using `lists_needed_variables', keep(3) nogen      // Merge in lists, keep only if an offer exists
rename (anon_item_id anon_byr_id src_cre_date start_price_usd offr_price) (item_id byr_id offr_date bin of_p)

// keep threads that follow 021212
sort item_id byr_id offr_date
gen seq = .
by item_id byr_id: replace seq = 1 if _n == 1          & offr_type_id == 0 //PB1
by item_id byr_id: replace seq = 2 if seq[_n - 1] == 1 & offr_type_id == 2 //PS1    
by item_id byr_id: replace seq = 3 if seq[_n - 1] == 2 & offr_type_id == 1 //PB2
by item_id byr_id: replace seq = 4 if seq[_n - 1] == 3 & offr_type_id == 2 //PS2
by item_id byr_id: replace seq = 5 if seq[_n - 1] == 4 & offr_type_id == 1 //PB3
by item_id byr_id: replace seq = 6 if seq[_n - 1] == 5 & offr_type_id == 2 //PS3
drop if seq == .  // Throwing away all offers that do not correspond to the 021212 sequence

// Number of rounds and who is playing
by item_id byr_id: gen event_num = _n
by item_id byr_id : gen total_events = _N
gen seller_turn = mod(event_num, 2) == 0
gen offer_num_player = event_num / 2 if seller_turn == 1
replace offer_num_player = (event_num + 1) / 2 - 1 if seller_turn == 0

// Replace offer expire or decline because of another offer with an explicit decline
replace status_id = 2 if status_id == 0 | status_id == 8
// Mark cases where one party counters and the other party accepts (1 or 9) or declines (2 or 6) and the thread ends
gen of_c = ""
replace of_c = "SA" if seller_turn == 0 & event_num == total_events & (status_id == 1 | status_id == 9)
replace of_c = "SD" if seller_turn == 0 & event_num == total_events & (status_id == 2 | status_id == 6)
replace of_c = "BA" if seller_turn == 1 & event_num == total_events & (status_id == 1 | status_id == 9)
replace of_c = "BD" if seller_turn == 1 & event_num == total_events & (status_id == 2 | status_id == 6)

// Create code for how the thread ended
foreach c in SA SD BA BD {
	by item_id byr_id: egen `c'_end = max(of_c == "`c'")
}

// Generate indicators of whether the thread ends with agreement or disagreement
gen agree = (SA_end == 1 | BA_end == 1)
gen disagree = (SD_end == 1 | BD_end == 1)

// Drop threads where there is no agreement or disagreement (ends with status_id == 7)
drop if agree == 0 & disagree == 0

// Add one row for the BIN
expand 2 if event_num == 1, gen(bin_flag)
replace of_c = "BIN"         if bin_flag
replace of_p = bin           if bin_flag
replace event_num = 0        if bin_flag
replace seller_turn = 1      if bin_flag
replace offer_num_player = 0 if bin_flag
replace total_events = total_events + 1
drop bin_flag

sort item_id byr_id event_num
tempfile price_conv_plot_data
save `price_conv_plot_data', replace

// Create plots 

* Game ends at t = 6, agreement 
use `price_conv_plot_data' if total_events == 6 & agree, clear
plot_figure, name(price_conv_6A) max_y(150)
* Game ends at t = 6, disagreement
use `price_conv_plot_data' if total_events == 6 & disagree, clear
plot_figure, name(price_conv_6D) max_y(200)
* Game ends at t = 7, agreement 
use `price_conv_plot_data' if total_events == 7 & agree, clear
plot_figure, name(price_conv_7A) max_y(200)
* Game ends at t = 7, disagreement
use `price_conv_plot_data' if total_events == 7 & disagree, clear
plot_figure, name(price_conv_7D) max_y(200)



