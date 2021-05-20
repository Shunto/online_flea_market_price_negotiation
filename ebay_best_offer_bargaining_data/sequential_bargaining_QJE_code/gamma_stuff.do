* This dofile generates the gamma plots

* Output 1: Histograms of gamms
* Output 2: Local linear fits of P(accept|gamma)
* Output 3: Lowess fits of P(accept|gamma)
*Fig 9 and 10

clear
set more off

do set_globals.do

cap log close
log using "${figtab}/gamma_stuff.log", replace 

****************************************
* Data Assembly
****************************************
use anon_item_id anon_byr_id src_cre_date offr_type_id slr_hist byr_hist offr_price status_id using "${root}/anon_bo_threads.dta", clear
tempfile threads_needed_variables
save `threads_needed_variables'

use anon_item_id item_cndtn_id start_price_usd anon_leaf_categ_id using "${root}/anon_bo_lists.dta"					// Pulling listing data subject to our standard restrictions			
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", nogen keep(3)
merge 1:m anon_item_id using `threads_needed_variables', nogen keep(3)			// Merging in threads-- note that we throw away listings with no offers here

****************************************
* Organizing Offers
****************************************

sort anon_item_id anon_byr_id src_cre_date
by anon_item_id anon_byr_id: gen order = _n							// These two lines give us the within-item-buyer order

gen seq = 1 if offr_type_id == 0 & order==1							// These are ``first buyer offers"
by anon_item_id anon_byr_id: replace seq=2 if seq[_n-1]== 1 & offr_type_id == 2			// The next five lines set the sequence conditional on the prior sequence (all within item-buyer)
by anon_item_id anon_byr_id: replace seq=3 if seq[_n-1]== 2 & offr_type_id == 1
by anon_item_id anon_byr_id: replace seq=4 if seq[_n-1]== 3 & offr_type_id == 2
by anon_item_id anon_byr_id: replace seq=5 if seq[_n-1]== 4 & offr_type_id == 1
by anon_item_id anon_byr_id: replace seq=6 if seq[_n-1]== 5 & offr_type_id == 2

drop if seq==.											// Throwing away all offers that do not correspond to the 021212 sequence

* A brief note on the above:
* This formulation excludes bargaining sequences that do not fit the 021212 framework (i.e., the left side of our bargaining tree)
* We can think about reincorporating these, if we treat the seller declines as gamma = 0 (I think Brad suggested this at some point)


* This next bit defined seller experience and buyer experience for every offer, since that's the level at which we're running regressions.

// Replace missing history counts with the counts of the first observation in this thread
sort anon_item_id anon_byr_id src_cre_date
by anon_item_id anon_byr_id: gen slr_exp=slr_hist[1]
by anon_item_id anon_byr_id: gen byr_exp=byr_hist[1]
// Treat other missing _hist as 1 (includes THIS obs)
replace slr_exp = 1 if slr_exp==.
replace byr_exp = 1 if byr_exp==.

replace slr_exp = log(slr_exp)
replace byr_exp = log(byr_exp)
label var slr_exp "Log(Seller Experience)"
label var byr_exp "Log(Buyer Experience)"
gen used = item_cndtn_id >= 3000 & item_cndtn_id ~=.

****************************************
* Constructing Gammas
****************************************

gen prior_price = start_price_usd if seq == 1											// Think of prior_price as the standing price when you make your offer
by anon_item_id anon_byr_id: replace prior_price = offr_price[_n-1] if seq >= 2							// This defines it by looking one step up the chain

gen gamma = offr_price/prior_price if seq == 1											// Remember our  defintion of gamma for the first offer
by anon_item_id anon_byr_id: replace gamma = (offr_price - prior_price[_n-1])/(prior_price - prior_price[_n-1]) if seq >= 2	// Solve the formula for gamma, you get this expression (I promise)

by anon_item_id anon_byr_id: egen min_gam = min(gamma)
by anon_item_id anon_byr_id: egen max_gam = max(gamma)
drop if min_gam < 0
drop if max_gam > 1														// Dropping all threads that don't conform to gamma in [0,1] at any point


****************************************
* Defining Variables for Split Difference Analysis
****************************************

gen accepted = (status_id == 1 | status_id==9)		// Dummy for success
gen split_01 = round(gamma,.01) == .5			// Narrow range
gen split_05 = round(gamma,.05) == .5			// Middling range
gen split_10 = round(gamma,.10) == .5			// Wide range

summ accepted split_*


****************************************
* Gamma and Experience table
****************************************

forvalues s = 1(1)6 {
 	eststo gam_exp_all_`s': qui reg gamma byr_exp slr_exp if seq == `s', robust
	eststo gam_exp_leaf_`s': qui areg gamma byr_exp slr_exp if seq == `s', absorb(anon_leaf_categ_id) robust
	estadd local fe = "Yes"

}
esttab gam_exp_all_* , se star(* .1 ** .05 *** .01) label stats(  r2 N, label(  "$ R^2 $" "N")) mtitle type replace
esttab gam_exp_all_* using "${figtab}/gamma_experience.tex", se star(* .1 ** .05 *** .01) label stats( r2 N, label(  "$ R^2 $" "N"))nonotes  mtitles("$\gamma_1$" "$\gamma_2$" "$\gamma_3$" "$\gamma_4$" "$\gamma_5$" "$\gamma_6$") type replace substitute( "\\$" \\$ _ \_ )

esttab gam_exp_leaf_*, se star(* .1 ** .05 *** .01) label stats( r2 df_a N, label( "$ R^2 $" "No. Leaf FE"  "N")) mtitle type replace
esttab gam_exp_leaf_* using "${figtab}/gamma_experience_leaf.tex", se star(* .1 ** .05 *** .01) label stats( fe r2 N, label( "Leaf FE" "$ R^2 $" "N")) nonotes  mtitles("$\gamma_1$" "$\gamma_2$" "$\gamma_3$" "$\gamma_4$" "$\gamma_5$" "$\gamma_6$") type replace substitute( "\\$" \\$ _ \_ )


****************************************
* Gamma Histograms
****************************************

set scheme s1mono									// Monochrome filter best filter
forvalues s = 1(1)6 {
	hist gamma if seq == `s', frac xlab(,labsize(large)) ylab(,labsize(large)) xtitle("") ytitle("") name(h`s', replace)
	graph export "${figtab}/figsh`s'.pdf", as (pdf) replace
}



**************************************
* Now, Local Linear Plots and Regressions for split the difference analysis
**************************************

* generate gammas for polynomial used curvature assessment for optimal bandwidth
forvalues i = 1(1)5 {
	gen gamma_e`i'=gamma^`i'
}
*create recentered gamma so that constants are mean y at .5
gen gamma_r=gamma-.5
 
 * loop over each round
 
label var split_01 "Split"
label var gamma_r "$\gamma_t$"
local y "accepted"


forvalues s = 1(1)6 {
		
		**   find optimal bandwidth
		local r = .05
		local lb = .5-`r'
		local ub = .5+`r'
		qui reg `y' gamma_e* if gamma>`lb' & gamma<`ub'  & split_01==0 & seq==`s'
		capture drop resid
		qui predict resid, resid
		qui summ resid  if gamma>`lb' & gamma<`ub'  & split_01==1 & seq==`s'
		local sigma=r(sd)
		local g2=abs(2*_b[gamma_e2]+6*_b[gamma_e3]*(.5)+12*_b[gamma_e4]*(.5)^2+20*_b[gamma_e5]*(.5)^3 ) 
		qui count if gamma>=.49 & gamma<.5 & seq==`s'
		local cleft=r(N)
		qui count if gamma>.5 & gamma<=.51 & seq==`s'
		local cright=r(N)
		local fn=(`cleft'+`cright')/2
		* constant = 3.4375 for triangular weight, = 5.4 for no-weight
		local bw=5.4*(`sigma'^2/`fn'/`g2')^(1/5)
		*dis in white "for seq=`s' and y=`y', bw=`bw'"
		
		** local linear regressions
		qui eststo e_`y'_`s', title(" $ t=`s' $ "): reg `y' split_01 gamma_r if abs(gamma-.5)<`bw' & seq==`s', robust
		
		** version with leaf fixed effects
		qui eststo e_leaf_`y'_`s', title(" $ t=`s' $ "): areg `y' split_01 gamma_r if abs(gamma-.5)<`bw' & seq==`s', absorb(anon_leaf_categ_id) vce(robust)
		estadd local fe = "Yes"
		*qui estadd scalar bw=`bw'
/*
		** local linear PLOT
		cap drop min max pt5
		qui gen min = S[`s',1] - S[`s',2]*1.96 if _n==1 
		qui gen max = S[`s',1] + S[`s',2]*1.96 if _n==1 
		cap gen pt5 = .5 if _n==1
		qui reg accepted gamma if abs(gamma-.5)<`bw' & seq == `s' & split_01==0
		*/
}

*combine local linear regression estimates
esttab e_accepted* , se star(* .1 ** .05 *** .01) label stats(  r2 N, label( "$ R^2 $" "N")) mtitle type replace
esttab e_accepted* using "${figtab}/local_linear.tex", se star(* .1 ** .05 *** .01) label stats(  r2 N, label(  "$ R^2 $" "N")) mtitle type replace substitute( "\\$" \\$ _ \_ )
esttab e_leaf_accepted* , se star(* .1 ** .05 *** .01) label stats(  r2 df_a N, label(  "$ R^2 $" "No. Leaf FE" "N")) mtitle type replace
esttab e_leaf_accepted* using "${figtab}/local_linear_leaf.tex", se star(* .1 ** .05 *** .01) label stats( r2 df_a N, label(  "$ R^2 $" "No. Leaf FE" "N")) mtitle type replace substitute( "\\$" \\$ _ \_ )


**************************************
* Estimates Used in Plots
**************************************

mat def S = J(6,2,.)						// First column is the mean, second column is the SD
forvalues s = 1(1)6{
	qui sum accepted if seq == `s' & split_01 == 1		// 
	mat def S[`s',1] = r(mean)				// Recording the estimate
	mat def S[`s',2] = sqrt(r(mean)*(1-r(mean))/r(N))	// Recording the standard error of the estimate
}

**************************************
* Lowess Plots 
**************************************

* A note on language:
* We should be careful to call these ``discontinuities in the sample mean"

keep if gamma >=.2 & gamma <=.8 & split_01 == 0
bysort seq: sample 10000, count
forvalues s = 1(1)6 {
	cap drop min max pt5
	gen min = S[`s',1] - S[`s',2]*1.96 if _n==1
	gen max = S[`s',1] + S[`s',2]*1.96 if _n==1
	cap gen pt5 = .5 if _n==1	
	tw (lowess accepted gamma if seq == `s' & split_01==0) (function y=S[`s',1],range(.5 .5)) (rcap max min pt5), legend(off) xlabel(.2(.1).8,labsize(large)) ylabel(0(.1)1,labsize(large)) name(f`s', replace) ytitle(Accept Prob, size(large))
	graph export "${figtab}/figsf`s'.pdf", as(pdf) replace
}

log close
