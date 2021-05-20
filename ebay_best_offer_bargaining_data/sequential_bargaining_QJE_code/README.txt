README for code for Backus, Blake, Larsen, Tadelis (2019) "Sequential Bargaining in the Field: Evidence from Millions of Bargaining Interactions"

The first three files should be run in order. After that, the order is not important. 

1. set_globals.do: This file should be edited to include the user's directories
2. load_csv_files.do: Loads in the raw csv files. The data can be accessed at http://www.nber.org/data/bargaining.html or by contacting the authors. 
3. paper_sample.do: creates a dta file that includes identifiers for observations satisfying the paper's sample restrictions. Also creates Appendix Table A1
4. summary_stats_main.do: creates Table 1
5. summary_stats_cat.do: creates Table 2
6. summary_stats_offer_vs_not: creates Table 3
7. patience_experience.do: creates Table 4
8. competition.do: creates Table 5
9. photo_analysis.do: creates Table 6 and Figure 7
10. concession_regression.do: creates Table 7 and Appendix Table D2
11. gamma_stuff.do: creates Table 8, Appendix Table D1, and Figures 8 and 9
12. game_tree.do: creates Figure 3
13. price_conv.do: creates Figure 4
14. barg_costs_plots: creates Figures 5 and 6
15. competition_facts.do: computes numbers reported in body of Section 4.3
16. summary_stats_ref.do: creates Appendix Table B1
17. het_seqFE.do: creates Appendix Table C1