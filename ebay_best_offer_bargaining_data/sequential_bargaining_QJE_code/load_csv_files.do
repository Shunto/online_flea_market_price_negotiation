/* Note: We first downloaded the data from the NBER website to the Stanford server and then unzipped the files as follows

wget "http://www.nber.org/data/bargaining/anon_bo_lists.csv.gz"
wget "http://www.nber.org/data/bargaining/anon_bo_threads.csv.gz"

gunzip anon_bo_lists.csv.gz 
gunzip anon_bo_threads.csv.gz 

*/


do set_globals.do

// load in anon_bo_lists.csv
clear
import delimited using "${root}/anon_bo_lists.csv"

// put date variables in proper stata format
gen auct_start_dt_new = date(auct_start_dt,"DMY")
format auct_start_dt_new %td
drop auct_start_dt
ren auct_start_dt_new auct_start_dt

gen auct_end_dt_new = date(auct_end_dt,"DMY")
format auct_end_dt_new %td
drop auct_end_dt
ren auct_end_dt_new auct_end_dt

// replace (with missing) a set of product_ids that were not recorded correctly
replace anon_product_id=. if anon_product_id==547957

save "${root}/anon_bo_lists.dta", replace


// load in anon_bo_threads.csv
clear
import delimited using "${root}/anon_bo_threads.csv"

// Drop any observations that are complete duplicate records based on the full set of variables 
duplicates drop

// put date and datetime variables in proper stata format
gen src_cre_dt_new = date(src_cre_dt,"DMY")
format src_cre_dt_new %td
drop src_cre_dt
ren src_cre_dt_new src_cre_dt

gen double src_cre_date_new = clock(src_cre_date,"DMYhms")
format src_cre_date_new %tc
drop src_cre_date
ren src_cre_date_new src_cre_date

gen double response_time_new = clock(response_time,"DMYhms")
format response_time_new %tc
drop response_time
ren response_time_new response_time


save "${root}/anon_bo_threads.dta", replace

// 