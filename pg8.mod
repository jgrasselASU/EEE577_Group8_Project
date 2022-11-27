reset;	#Clean slate

#### ---- Sets ---- ####
set BUS;	#set of busses, n in BUS
set GEN;	#set of generators, g in GEN
set ELINE;	#set of existing lines, k in ELINE
set NLINE;	#set of candidate (new) lines to be built, k in NLINE

#### ---- Parameters ---- ####
param d		{n in BUS};		#Bus demand
param Pmax	{g in GEN};		#Generator limits
param C		{g in GEN};	#Generator linear cost term
param Gbus	{g in GEN};	#Generator bus location
param C_new	{k in NLINE};	#Cost of installing a new line
param Fe	{k in ELINE};	#Existing line limits
param Fn	{k in NLINE};	#New line limits
param Be	{k in ELINE};	#Existing line susceptance
param Bn	{k in NLINE};	#New line susceptance
param eline_s	{k in ELINE};	#Existing line from bus (sending)
param eline_r	{k in ELINE};	#Existing line to bus (receiving)
param nline_s	{k in NLINE};	#New line from bus
param nline_r	{k in NLINE};	#New line to bus

#### ---- Decision Variables ---- ####
var del	{n in BUS};			#Voltage angle at each bus
var Pgen{g in GEN} >= 0;	#Generator power
var Pel	{k in ELINE};		#Power flow in existing lines
var Pnl	{k in NLINE};		#Power flow on new lines
var w	{k in NLINE} binary;#Binary choice of new line install

#### ---- Objective ---- ####
minimize COST: 
	(sum{g in GEN}Pgen[g]*C[g]) + (sum{k in NLINE}C_new[k]*w[k]);
	
#### ---- Constraints ---- ####
subject to gen_limit {g in GEN}:
	Pgen[g] <= Pmax[g];
	
subject to e_line_limit {k in ELINE}:
	-Fe[k] <= Pel[k] <= Fe[k];
	
subject to n_line_limit1 {k in NLINE}:
	-Fn[k]*w[k] <= Pnl[k];

subject to n_line_limit2 {k in NLINE}:
	Pnl[k] <= Fn[k]*w[k];
	
subject to e_line_angle {k in ELINE}:
	Pel[k] = Be[k]*(del[eline_r[k]] - del[eline_s[k]]);
	
subject to n_line_angle1 {k in NLINE}:
	-(1-w[k])*100000 <= Pnl[k]- Bn[k]*(del[nline_r[k]] - del[nline_s[k]]);
	
subject to n_line_angle2 {k in NLINE}:
	Pnl[k]- Bn[k]*(del[nline_r[k]] - del[nline_s[k]]) <= (1-w[k])*100000;
	
subject to flow_balance {n in BUS}:
	(sum{k in ELINE: eline_s[k] == n}Pel[k]) + (sum{k in NLINE: nline_s[k] == n}Pnl[k])
	- (sum{k in ELINE: eline_r[k] == n}Pel[k]) - (sum{k in NLINE: nline_r[k] == n}Pnl[k])
	=
	(sum{g in GEN: Gbus[g] == n}Pgen[g])
	- d[n];
	
#### ---- Load Data ---- ####
data;

#Bus data - columns:
#bus ID numbers,
#Second column is the demand at that bus
param: BUS: d := include pg8_bus.dat;

#Generator data - columns: 
#gen ID numbers
#linear cost
#generator location bus
#generator max output
param: GEN: C Gbus Pmax := include pg8_gen.dat;

#existing line data - columns:
#line id number
#line flow maximum
#line susceptance
#sending bus id
#receiving bu id
param: ELINE: Fe Be eline_s eline_r := include pg8_eline.dat;

#new line line data - columns:
#line id number
#line flow maximum
#line susceptance
#sending bus id
#receiving bu id
#cost of installing this new line
param: NLINE: Fn Bn nline_s nline_r C_new := include pg8_nline.dat;

#### ---- Solve! ---- ####
options solver gurobi;
solve;
display _total_solve_elapsed_time; 
option show_stats 1;

#### ---- Make output of solution ---- ####
#Generator output
for{g in GEN} {
printf "%s%8.2f\n", g, Pgen[g] > out.Unit_Commit;
}

#Lines to purchase
for{k in NLINE: w[k]=1} {
printf "%s%2i\n", k, w[k] > out.Line_Purchase;
}