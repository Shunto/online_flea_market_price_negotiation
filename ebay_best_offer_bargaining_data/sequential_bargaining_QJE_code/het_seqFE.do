
do set_globals.do

// Pulling only the BO sales with strong (20+) reference prices
use count4 anon_item_id item_cndtn_id  ref_price4 item_price anon_product_id  ship_time_slowest ship_time_chosen anon_leaf_categ_id if count4~=. & count4>=20 using "${root}/anon_bo_lists.dta", clear

// Our standard listing sample restriction
merge 1:1 anon_item_id using "${derived_data}/sample_id_list.dta", keep(3) nogen			

// Merging in threads, keep only if an offer exists
merge 1:m anon_item_id using "${root}/anon_bo_threads", keep(3) nogen				

gen used = item_cndtn_id >= 3000 if item_cndtn_id ~=.
gen success = (status_id == 1 | status_id == 9)

sort anon_item_id anon_byr_id

by anon_item_id anon_byr_id: egen sold = max(success)
by anon_item_id anon_byr_id: egen offers = count(anon_item_id)
by anon_item_id anon_byr_id: gen price = item_price/ref_price4 if sold == 1


by anon_item_id anon_byr_id: keep if _n==1

local tabrow1
local tabrow2 "...Buyer FE & "
local tabrow3 "...Product FE & "
local tabrow4 "...Buyer and Product FE & "
local tabrow5 
local tabrow6 "...Seller FE & "
local tabrow7 "...Product FE & "
local tabrow8 "...Seller and Product FE & "
local tabrow9
local tabrow10 "...Seller FE & "
local tabrow11 "...Buyer FE & "
local tabrow12 "...Seller and Buyer FE & "

local sellerFE_count_row = "No. Seller Fixed Effects & "
local buyerFE_count_row = "No. Buyer Fixed Effects & "
local productFE_count_row = "No. Product Fixed Effects & "
		


local FEvars1 anon_slr_id
local FEvars2 anon_byr_id
local FEvars3 anon_product_id
local FEvars4 anon_slr_id anon_byr_id 
local FEvars5 anon_slr_id anon_product_id
local FEvars6 anon_byr_id anon_product_id
local FEvars7 anon_byr_id anon_product_id anon_slr_id

local FEnames1 S
local FEnames2 B
local FEnames3 P
local FEnames4 SB
local FEnames5 SP
local FEnames6 BP
local FEnames7 ALL

local table_header_num " & "
local column_count = 0



forvalues condition = 0/1 { 
 
	foreach depvar in price sold offers {
		
		** keep track of which column of the table we are creating
		local column_count = `column_count' + 1

		di "Running regressions for `depvar', used = `condition' "		
		forvalues j = 1/7 { 
			** run regression
			 qui reghdfe `depvar' if used == `condition', absorb(`FEvars`j'')
			** save adjusted R^2
			local `FEnames`j'' = e(r2_a)
			if `j'==1 | `j'==2 | `j'==3 {
				local numFE`j' = e(df_a)
			}
			
			
		}
	
		** Create a column for final table of marginal contributions to adjusted R^2
		local rowend = " & "
		if `column_count' == 6 {
			local rowend = " \\ "
		} 
		
		local table_header_num = "`table_header_num'" + "(`column_count')" + "`rowend'"
		local sellerFE_count_row = "`sellerFE_count_row'" + "`numFE1'" + "`rowend'"
		local buyerFE_count_row = "`buyerFE_count_row'" + "`numFE2'" + "`rowend'"
		local productFE_count_row = "`productFE_count_row'" + "`numFE3'" + "`rowend'"
		
		
		** marginal contribution of seller FEs: 
		local delta1 = round(`S', 0.001)
		local delta2 = round(`SB' - `B', 0.001)
		local delta3 = round(`SP' - `P', 0.001)
		local delta4 = round(`ALL' - `BP', 0.001)
		
		** marginal contribution of buyer FEs: 
		local delta5 = round(`B', 0.001)
		local delta6 = round(`SB' - `S', 0.001)
		local delta7 = round(`BP' - `P', 0.001)
		local delta8 = round(`ALL' - `SP', 0.001)
		
		** marginal contribution of product FEs: 
		local delta9 = round(`P', 0.001)
		local delta10 = round(`SP' - `S', 0.001)
		local delta11 = round(`BP' - `B', 0.001)
		local delta12 = round(`ALL' - `SB', 0.001)
		
		forvalues k = 1/12 { 
			local tabrow`k' = "`tabrow`k''" + " `delta`k'' " + "`rowend'"
 		}
		
		

	}

}

forvalues j = 1/12 {
	di "`tabrow`j''"
}




** Now output full table 
file open het_seqFE using "${figtab}/het_seqFE.tex", write replace

file write het_seqFE "{\begin{tabular}{l*{6}{c}} \hline\hline" _n
file write het_seqFE " `table_header_num' " _n
file write het_seqFE " & Price & Sold & No. Offers & Price & Sold & No. Offers \\ \hline " _n


** Seller FE panel
file write het_seqFE "Adjusted $ R^2 $, Seller FE  & `tabrow1'" _n
file write het_seqFE "\multicolumn{7}{l}{Change in Adjusted $ R^2 $ from Adding Seller FE After... } \\" _n
forvalues j = 2/4 {
	file write het_seqFE "`tabrow`j''" _n
}
file write het_seqFE "& & & & & & \\" _n

** Buyer FE panel
file write het_seqFE "Adjusted $ R^2 $, Buyer FE  & `tabrow5' " _n
file write het_seqFE "\multicolumn{7}{l}{ Change in  Adjusted $ R^2 $ from Adding Buyer FE After... } \\" _n
forvalues j = 6/8 {
	file write het_seqFE "`tabrow`j''" _n
}
file write het_seqFE "& & & & & & \\ " _n

** Product FE panel
file write het_seqFE "Adjusted $ R^2 $, Product FE  & `tabrow9' " _n
file write het_seqFE "\multicolumn{7}{l}{ Change in  Adjusted $ R^2 $ from Adding Product FE After... } \\" _n
forvalues j = 10/12 {
	file write het_seqFE "`tabrow`j''" _n
}
file write het_seqFE "& & & & & & \\ " _n

file write het_seqFE "`sellerFE_count_row'" _n
file write het_seqFE "`buyerFE_count_row'" _n
file write het_seqFE "`productFE_count_row'" _n

file write het_seqFE "& & & & & & \\ " _n

file write het_seqFE "Condition & Used & Used & Used & New & New & New \\" _n

file write het_seqFE "\hline\hline \end{tabular} }"

file close het_seqFE
