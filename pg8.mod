reset;	#Clean slate

#### ---- Sets ---- ####
set BUS;	#set of busses, n in BUS
set GEN;	#set of generators, g in GEN
set ELINE;	#set of existing lines, k in ELINE
set NLINE;	#set of candidate (new) lines to be built, k in NLINE

#### ---- Parameters ---- ####
param d		{n in BUS};	#Bus demand
param Pmax	{g in GEN};	#Generator limits
param C		{g in GEN};	#Generator linear cost term
param ng	{g in GEN};	#Generator bus location
param Cnew	{k in NLINE};	#Cost of installing a new line
param Fe	{k in ELINE};	#Existing line limits
param Fn	{k in NLINE};	#New line limits
param Be	{k in ELINE};	#Existing line susceptance
param Bn	{k in NLINE};	#New line susceptance
param e_ns	{k in ELINE};	#Existing line from bus (sending)
param e_nr	{k in ELINE};	#Existing line to bus (receiving)
param n_ns	{k in NLINE};	#New line from bus
param n_nr	{k in NLINE};	#New line to bus

#### ---- Decision Variables ---- ####
var theta	{n in BUS};			#Voltage angle at each bus
var Pgen	{g in GEN} >= 0;	#Generator power
var Pe		{k in ELINE};		#Power flow in existing lines
var Pn		{k in NLINE};		#Power flow on new lines
var w		{k in NLINE} binary;#Binary choice of new line install

#### ---- Objective ---- ####
minimize COST: 
	(sum{g in GEN}Pgen[g]*C[g]) + (sum{k in NLINE}Cnew[k]*w[k]);
	
#### ---- Constraints ---- ####

subject to gen_limit {g in GEN}:
	Pgen[g] <= Pmax[g];
	
subject to flow_balance {n in BUS}:
	(sum{k in ELINE: e_ns[k] == n}Pe[k]) + (sum{k in NLINE: n_ns[k] == n}Pn[k])
	- (sum{k in ELINE: e_nr[k] == n}Pe[k]) - (sum{k in NLINE: n_nr[k] == n}Pn[k])
	=
	(sum{g in GEN: ng[g] == n}Pgen[g])
	- d[n];
	
subject to e_line_limit {k in ELINE}:
	-Fe[k] <= Pe[k] <= Fe[k];
	
subject to n_line_limit1 {k in NLINE}:
	-Fn[k]*w[k] <= Pn[k];

subject to n_line_limit2 {k in NLINE}:
	Pn[k] <= Fn[k]*w[k];
	
subject to e_line_angle {k in ELINE}:
	Pe[k] = Be[k]*(theta[e_nr[k]] - theta[e_ns[k]]);
	
subject to n_line_angle1 {k in NLINE}:
	-(1-w[k])*100000 <= Pn[k]- Bn[k]*(theta[n_nr[k]] - theta[n_ns[k]]);
	
subject to n_line_angle2 {k in NLINE}:
	Pn[k]- Bn[k]*(theta[n_nr[k]] - theta[n_ns[k]]) <= (1-w[k])*100000;
	
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
param: GEN: C ng Pmax := include pg8_gen.dat;

#Existing line data - columns:
	#line id number
	#line flow maximum
	#line susceptance
	#sending bus id
	#receiving bu id
param: ELINE: Fe Be e_ns e_nr := include pg8_eline.dat;

#New line line data - columns:
	#line id number
	#line flow maximum
	#line susceptance
	#sending bus id
	#receiving bu id
	#cost of installing this new line
param: NLINE: Fn Bn n_ns n_nr Cnew := include pg8_nline.dat;

#### ---- Solve! ---- ####
options solver gurobi;
solve;
display _total_solve_elapsed_time; 
option show_stats 1;

#### ---- Make output of solution ---- ####
#Cost
printf "%12.2f", COST > out.Final_Cost;

#Generator output
for{g in GEN} {
printf "%s%8.2f\n", g, Pgen[g] > out.Unit_Commit;
}

#Lines to purchase
for{k in NLINE: w[k]=1} {
printf "%s%2i\n", k, w[k] > out.Line_Purchase;
}

#For vizualization
for{n in BUS} {
printf "%s, %8.2f, %8.2f\n", n, sum{g in GEN: ng[g] == n} Pgen[g], d[n] > out.Bus_Gen_Dem;
}

for{k in ELINE} {
printf "%s, %s, %s, %8.f\n",k, e_ns[k], e_nr[k], Pe[k] > out.Line_Flow;
}

for{k in NLINE: w[k] > 0}{
printf "%s, %s, %s, %8.f\n",k, n_ns[k], n_nr[k], Pn[k] > out.New_Line_Flow;
}