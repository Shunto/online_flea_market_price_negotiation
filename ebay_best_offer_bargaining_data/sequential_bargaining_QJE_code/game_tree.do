/*
This is the final draft of the game tree construction dofile.
Originally written by Tom in 2014 (?), substantially revised in 2016.
NB: Remeber to re-run when we fix the dataset.
*/

do set_globals.do 

clear
set more off

use "${root}/anon_bo_threads.dta"
merge m:1 anon_item_id using "${derived_data}/sample_id_list.dta", nogen keep(3)	// matching to our sample

ren offr_type of_type
ren status_id status

// index sequence of offers
sort anon_item_id anon_byr_id src_cre_date
*egen thrd_idx=group(item arrival)
by anon_item_id anon_byr_id: gen seq_simp=_n
gen seq = 1 if of_type==0 & seq_simp==1 
replace seq=2 if of_type==2 & seq_simp==2 
replace seq=3 if of_type==1 & seq_simp==3 
replace seq=4 if of_type==2 & seq_simp==4 
replace seq=5 if of_type==1 & seq_simp==5 
replace seq=6 if of_type==2 & seq_simp==6 


gen seq2=""

// row 1
replace seq2=" L-1-a" if of_type==0 & seq_simp==1 & inlist(status,1,9) 
replace seq2=" L-1-c" if of_type==0 & seq_simp==1 & inlist(status,7)
replace seq2=" L-1-d" if of_type==0 & seq_simp==1 & !inlist(status,1,9,7)

// row 2 Left
replace seq2=" L-2-a" if of_type==2 & seq_simp==2 & inlist(status,1,9) & seq2[_n-1]==" L-1-c"
replace seq2=" L-2-c" if of_type==2 & seq_simp==2 & inlist(status,7) & seq2[_n-1]==" L-1-c"
replace seq2=" L-2-d" if of_type==2 & seq_simp==2 & !inlist(status,1,9,7) & seq2[_n-1]==" L-1-c"

// row 3 Left
replace seq2=" L-3-a" if of_type==1 & seq_simp==3 & inlist(status,1,9) & seq2[_n-1]==" L-2-c"
replace seq2=" L-3-c" if of_type==1 & seq_simp==3 & inlist(status,7) & seq2[_n-1]==" L-2-c"
replace seq2=" L-3-d" if of_type==1 & seq_simp==3 & !inlist(status,1,9,7) & seq2[_n-1]==" L-2-c"

// row 4 Left
replace seq2=" L-4-a" if of_type==2 & seq_simp==4 & inlist(status,1,9) & seq2[_n-1]==" L-3-c"
replace seq2=" L-4-c" if of_type==2 & seq_simp==4 & inlist(status,7) & seq2[_n-1]==" L-3-c"
replace seq2=" L-4-d" if of_type==2 & seq_simp==4 & !inlist(status,1,9,7) & seq2[_n-1]==" L-3-c"

// row 5 Left
replace seq2=" L-5-a" if of_type==1 & seq_simp==5 & inlist(status,1,9) & seq2[_n-1]==" L-4-c"
replace seq2=" L-5-c" if of_type==1 & seq_simp==5 & inlist(status,7) & seq2[_n-1]==" L-4-c"
replace seq2=" L-5-d" if of_type==1 & seq_simp==5 & !inlist(status,1,9,7) & seq2[_n-1]==" L-4-c"

// row 6 Left *note: only a-d at this point.
replace seq2=" L-6-a" if of_type==2 & seq_simp==6 & inlist(status,1,9) & seq2[_n-1]==" L-5-c"
replace seq2=" L-6-d" if of_type==2 & seq_simp==6 & !inlist(status,1,9) & seq2[_n-1]==" L-5-c"

// row 2 center
*replace seq2="C-2-c" if of_type==0 & seq_simp==2 
* Note: row 2 is taken by summing over row 3

// row 3 center
replace seq2="C-3-a" if of_type==0 & seq_simp==2 & inlist(status,1,9) 
replace seq2="C-3-c" if of_type==0 & seq_simp==2 & inlist(status,7)
replace seq2="C-3-d" if of_type==0 & seq_simp==2 & !inlist(status,1,9,7)

// row 4 center
replace seq2="C-4-a" if of_type==2 & seq_simp==3 & inlist(status,1,9) & seq2[_n-1]=="C-3-c"
replace seq2="C-4-c" if of_type==2 & seq_simp==3 & inlist(status,7) & seq2[_n-1]=="C-3-c"
replace seq2="C-4-d" if of_type==2 & seq_simp==3 & !inlist(status,1,9,7) & seq2[_n-1]=="C-3-c"

// row 5 center
replace seq2="C-5-a" if of_type==1 & seq_simp==4 & inlist(status,1,9) & seq2[_n-1]=="C-4-c"
replace seq2="C-5-c" if of_type==1 & seq_simp==4 & inlist(status,7) & seq2[_n-1]=="C-4-c"
replace seq2="C-5-d" if of_type==1 & seq_simp==4 & !inlist(status,1,9,7) & seq2[_n-1]=="C-4-c"

// row 6 center * Only a-d now
replace seq2="C-6-a" if of_type==2 & seq_simp==5 & inlist(status,1,9) & seq2[_n-1]=="C-5-c"
replace seq2="C-6-d" if of_type==2 & seq_simp==5 & !inlist(status,1,9) & seq2[_n-1]=="C-5-c"


// row 4 right
*replace seq2="R-4-c" if of_type==0 & seq_simp==3 & seq2[_n-1] == "C-2-c"
* Note: row 4 is taken by summing over row 5

// row 5 right
replace seq2="R-5-a" if of_type==0 & seq_simp==3 & inlist(status,1,9) & of_type[_n-1]==0 & of_type[_n-2]==0
replace seq2="R-5-c" if of_type==0 & seq_simp==3 & inlist(status,7) & of_type[_n-1]==0 & of_type[_n-2]==0
replace seq2="R-5-d" if of_type==0 & seq_simp==3 & !inlist(status,1,9,7) & of_type[_n-1]==0 & of_type[_n-2]==0

// row 6 right *only a-d now
replace seq2="R-6-a" if of_type==2 & seq_simp==4 & inlist(status,1,9) & seq2[_n-1]=="R-5-c"
replace seq2="R-6-d" if of_type==2 & seq_simp==4 & !inlist(status,1,9) & seq2[_n-1]=="R-5-c"

// row 4 left of center
*replace seq2="R-4-c" if of_type==0 & seq_simp==3 & seq2[_n-1] == "C-2-c"
* Note: row 4 is taken by summing over row 5

// row 5 left of center
replace seq2="LC-5-a" if of_type==0 & seq_simp==4 & inlist(status,1,9) & of_type[_n-1]==1 & of_type[_n-2]==2
replace seq2="LC-5-c" if of_type==0 & seq_simp==4 & inlist(status,7) & of_type[_n-1]==1 & of_type[_n-2]==2
replace seq2="LC-5-d" if of_type==0 & seq_simp==4 & !inlist(status,1,9,7) & of_type[_n-1]==1 & of_type[_n-2]==2

// row 6 left of center *only a-d now
replace seq2="LC-6-a" if of_type==2 & seq_simp==5 & inlist(status,1,9) & seq2[_n-1]=="LC-5-c"
replace seq2="LC-6-d" if of_type==2 & seq_simp==5 & !inlist(status,1,9) & seq2[_n-1]=="LC-5-c"

* Note to self-- we need to figure out how to add the LC guys to the pat matrix without screwing up all of the subsequent indexing. Might be time to overhaul the tree construction again...



// put counts in matrices to call
tab seq, matcell(off)
tab seq2, matcell(pat)


/// OUTPUT TO TIKZ tex FILE
#delimit #

file open treetex using "${figtab}/tree_final_fix.tex", write replace;
file write treetex "

 \tikzstyle{buy} = [text width=2.2em, text centered,draw=blue!80!black, ultra thick]
 \tikzstyle{sell} = [text width=2.2em, text centered,draw=red!60!black, ultra thick]
 \tikzstyle{non} = [text width=2.2em, text centered] 
 \tikzstyle{bag} = [text width=2.2em, text centered]  \begin{tikzpicture}[scale=1.5,font=\footnotesize] 
 \tikzstyle{solid node}=[circle,draw,inner sep=1.5,fill=black] 
 \tikzstyle{hollow node}=[circle,draw,inner sep=1.2]
 
\node(0)[solid node,label=above:{\$B\$}]{} 
child[grow=down]{node[sell](s11){\$S\$}
         child[xshift = -4cm]{node[non]{`=string(pat[1,1]/off[1,1]*100,`"%20.0f"')'\%} edge from parent node[left, xshift=-1cm]{\$A\$}}
         child[xshift = -3.5cm]{node[non]{`=string(pat[2,1]/off[1,1]*100,`"%20.0f"')'\%}
          child[grow=down,level distance = 5mm]{node[buy](b11){\$B\$}
                  [level distance = 15mm]
				  child{node[non]{`=string(pat[4,1]/pat[2,1]*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
                         child{node[non]{`=string(pat[5,1]/pat[2,1]*100,`"%20.0f"')'\%}
                          child[grow=down,level distance = 5mm]{node[sell](s12){\$S\$}
                          [level distance = 15mm]
                         child{node[non]{`=string(pat[7,1]/pat[5,1]*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
                         child{node[non]{`=string(pat[8,1]/pat[5,1]*100,`"%20.0f"')'\%}
                          child[grow=down,level distance = 5mm]{node[buy](b12){\$B\$}
                          [level distance = 15mm] 
                                 child{node[non]{`=string(pat[10,1]/pat[8,1]*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
                                 child{node[non]{`=string(pat[11,1]/pat[8,1]*100,`"%20.0f"')'\%}
                                  child[grow=down,level distance = 5mm]{node[sell](s13){\$S\$}
								 [level distance = 15mm]
                                         child{node[non]{`=string(pat[13,1]/pat[11,1]*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
                                         child{node[non]{`=string(pat[14,1]/pat[11,1]*100,`"%20.0f"')'\%}
                                          child[grow=down,level distance = 5mm]{node[buy](b13){\$B\$}
										  [level distance = 15mm]
                                                 child{node[non]{`=string(pat[16,1]/pat[14,1]*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
										  child{node[non]{`=string(pat[17,1]/pat[14,1]*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
                                         }edge from parent
										 node[left]{\$C\$}}
										 child{node[bag]{`=string(pat[15,1]/pat[11,1]*100,`"%20.0f"')'\%} edge from parent
										 node[right]{\$D\$}}
                                 }edge from parent node[left]{\$C\$}}
                                 child{node[bag]{`=string(pat[12,1]/pat[8,1]*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}                         
						} edge from parent node[left]{\$C\$}}
	                         child[sibling distance=3.2cm]{node[non]{`=string(pat[9,1]/pat[5,1]*100,`"%20.0f"')'\%}
                         child[grow=down,level distance = 5mm]{node[buy](b41){\$B\$}
						 [level distance = 15mm,sibling distance=1.2cm] 
                                 	child[grow=down]{node[non]{`=string((pat[29,1]+pat[30,1]+pat[31,1])/pat[9,1]*100,`"%20.0f"')'\%}
                                  	child[grow=down,level distance = 5mm]{node[sell](s41){\$S\$}
								  [level distance = 15mm]
                                         child{node[non]{`=string(pat[29,1]/(pat[29,1]+pat[30,1]+pat[31,1])*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
                                         child{node[non]{`=string(pat[30,1]/(pat[29,1]+pat[30,1]+pat[31,1])*100,`"%20.0f"')'\%}
										 child[grow=down,level distance = 5mm]{node[buy](b42){\$B\$}
                                                  [level distance = 15mm]
												  child{node[non]{`=string(pat[32,1]/pat[30,1]*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
                                                 child{node[non]{`=string(pat[33,1]/pat[30,1]*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
												  }edge from parent node[left]{\$C\$}}
                                         child{node[bag]{`=string(pat[31,1]/(pat[29,1]+pat[30,1]+pat[31,1])*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
                                 }edge from parent node[left]{\$C\$}}
                                 child[sibling distance=2.7cm]{node[bag]{`=string((1-(pat[29,1]+pat[30,1]+pat[31,1])/pat[9,1])*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
                         }edge from parent node[right,xshift = .5cm]{\$D\$}}
                 }edge from parent node[left]{\$C\$}}
				child{node[non]{`=string(pat[6,1]/pat[2,1]*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
			}edge from parent node[left,xshift=-.5cm]{\$C\$}}
			child[sibling distance=3cm]{node[non]{`=string(pat[3,1]/off[1,1]*100,`"%20.0f"')'\%} 
         child[level distance = 5mm]{node[buy](b21){\$B\$}		 [level distance = 15mm]
		 child[grow=down,sibling distance=1.2cm]{node[non]{`=string((pat[18,1]+pat[19,1]+pat[20,1])/pat[3,1]*100,`"%20.0f"')'\%}
                  child[grow=down,level distance = 5mm]{node[sell](s21){\$S\$}
                          [level distance = 15mm]
                         child{node[non]{`=string(pat[18,1]/(pat[18,1]+pat[19,1]+pat[20,1])*100,`"%20.0f"')'\%} edge from parent node[left]{\$A\$}}
                         child{node[non]{`=string(pat[19,1]/(pat[18,1]+pat[19,1]+pat[20,1])*100,`"%20.0f"')'\%} edge from parent
                         child[grow=down,level distance = 5mm]{node[buy](b22){\$B\$}
						 [level distance = 15mm]
                                 child{node[non]{`=string(pat[21,1]/pat[19,1]*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
                                 child{node[non]{`=string(pat[22,1]/pat[19,1]*100,`"%20.0f"')'\%}
                                  child[grow=down,level distance = 5mm]{node[sell](s22){\$S\$}
								  [level distance = 15mm]
                                         child{node[non]{`=string(pat[24,1]/pat[22,1]*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
                                         child{node[non]{`=string(pat[25,1]/pat[22,1]*100,`"%20.0f"')'\%}
                                          child[grow=down,level distance = 5mm]{node[buy](b23){\$B\$}
                                                  [level distance = 15mm]
                                                 child{node[non]{`=string(pat[27,1]/pat[25,1]*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
                                                 child{node[non]{`=string(pat[28,1]/pat[25,1]*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
												 }edge from parent node[left]{\$C\$}}
                                         child{node[bag]{`=string(pat[26,1]/pat[22,1]*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
                                 }edge from parent node[left]{\$C\$}}
                                 child{node[bag]{`=string(pat[23,1]/pat[19,1]*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
                         } edge from parent node[left]{\$C\$}}
                         child[sibling distance=3.5cm]{node[non]{`=string(pat[20,1]/(pat[18,1]+pat[19,1]+pat[20,1])*100,`"%20.0f"')'\%}
                         child[grow=down,level distance = 5mm]{node[buy](b31){\$B\$}
						 [level distance = 15mm,sibling distance=1.2cm] 
                                 	child[grow=down]{node[non]{`=string((pat[34,1]+pat[35,1]+pat[36,1])/pat[20,1]*100,`"%20.0f"')'\%}
                                  	child[grow=down,level distance = 5mm]{node[sell](s31){\$S\$}
								  [level distance = 15mm]
                                         child{node[non]{`=string(pat[34,1]/(pat[34,1]+pat[35,1]+pat[36,1])*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
                                         child{node[non]{`=string(pat[35,1]/(pat[34,1]+pat[35,1]+pat[36,1])*100,`"%20.0f"')'\%}
										 child[grow=down,level distance = 5mm]{node[buy](b32){\$B\$}
                                                  [level distance = 15mm]
												  child{node[non]{`=string(pat[37,1]/pat[35,1]*100,`"%20.0f"')'\%} edge from parent node[ left]{\$A\$}}
                                                 child{node[non]{`=string(pat[38,1]/pat[35,1]*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
												  }edge from parent node[left]{\$C\$}}
                                         child{node[bag]{`=string(pat[36,1]/(pat[34,1]+pat[35,1]+pat[36,1])*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
                                 }edge from parent node[left]{\$C\$}}
                                 child[sibling distance=2.7cm]{node[bag]{`=string((1-(pat[34,1]+pat[35,1]+pat[36,1])/pat[20,1])*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
                         }edge from parent node[right]{\$D\$}}
                 }edge from parent node[left]{\$C\$}}
                 child[sibling distance=3cm]{node[non]{`=string((1-(pat[18,1]+pat[19,1]+pat[20,1])/pat[3,1])*100,`"%20.0f"')'\%} edge from parent node[right]{\$D\$}}
         }edge from parent node[above right,xshift = .5cm]{\$D\$}
} edge from parent node[left]{\$O\$}}; 
					 
						 \node at(s11)[xshift=1.35cm,font=\scriptsize]{ `=string(off[1,1],`"%20.0fc"')' };
						 \node at(b11)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[2,1],`"%20.0fc"')' };
						 \node at(s12)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[5,1],`"%20.0fc"')' };
						 \node at(b12)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[8,1],`"%20.0fc"')' };
						 \node at(s13)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[11,1],`"%20.0fc"')' };
						 \node at(b13)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[14,1],`"%20.0fc"')' };
						 
						 \node at(b21)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[3,1],`"%20.0fc"')' };
						 \node at(s21)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[18,1]+pat[19,1]+pat[20,1],`"%20.0fc"')' };
						 \node at(b22)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[19,1],`"%20.0fc"')' };
						 \node at(s22)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[22,1],`"%20.0fc"')' };
						 \node at(b23)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[25,1],`"%20.0fc"')' };
						 
						 \node at(b41)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[9,1],`"%20.0fc"')' };
						 \node at(s41)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[29,1]+pat[30,1]+pat[31,1],`"%20.0fc"')' };
						 \node at(b42)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[30,1],`"%20.0fc"')' }; 
						 
						 \node at(b31)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[20,1],`"%20.0fc"')' };
						 \node at(s31)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[34,1]+pat[35,1]+pat[36,1],`"%20.0fc"')' };
						 \node at(b32)[xshift=1.35cm,font=\scriptsize]{ `=string(pat[35,1],`"%20.0fc"')' }; 
\

\end{tikzpicture}


" ;
file close treetex;


