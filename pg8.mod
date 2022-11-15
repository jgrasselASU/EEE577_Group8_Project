reset;	#Clean slate

#### ---- Sets ---- ####
set GEN;	#set of generators, g in GEN
set ELINE;	#set of existing lines, k in ELINE
set NLINE;	#set of candidate lines to be built, k in NLINE
set BUS;	#set of busses, n in BUS

#### ---- Parameters ---- ####
param C		{g in GEN};	#Generator linear cost term
param C_new	{k in NLINE};	#Cost of installing a new line
param Fe	{k in ELINE};	#Existing line limits
param Fn	{k in NLINE};	#New line limits
param Pmax	{g in GEN};		#Generator limits
param Bel	{k in ELINE};	#Existing line susceptance
param Bnl	{k in NLINE};	#New line susceptance
param d		{n in BUS};		#Bus demand
param eline_fb	{k in ELINE};	#Existing line from bus
param eline_tb	{k in ELINE};	#Existing line to bus
param nline_fb	{k in NLINE};	#New line from bus
param nline_tb	{k in NLINE};	#New line to bus

#### ---- Decision Variables ---- ####
var Pgen{g in GEN} >= 0;	#Generator power
var Pel	{k in ELINE};		#Power flow in existing lines
var Pnl	{k in NLINE};		#Power flow on new lines
var w	{k in NLINE} binary;#Binary choice of new line install
var del	{n in BUS}			#Voltage angle at each bus

#### ---- Objective ---- ####
minimize COST: 
	(sum{g in GEN}P[g]*C[g]) + (sum{k in NLINE}C_new[k]*w[k]);
	
#### ---- Constraints ---- ####
subject to gen_limit {g in GEN}:
	P[g] <= Pmax[g];
	
subject to e_line_limit {k in ELINE}:
	-Fe[k] <= Pel[k] <= Fe[k];
	
subject to n_line_limit {k in NLINE}:
	-Fn[k]*w[k] <= Pnl[k] <= Fn[k]*w[k];
	
subjct to e_line_angle {k in ELINE}:
	Pel[k] = Bel[k]*(del[eline_tb[k]] - del[eline_fb[k]);
	
subjct to n_line_angle {k in NLINE}:
	-(1-w[k])*100000 <= Pnl[k]- Bnl[k]*(del[nline_tb[k]] - del[nline_fb[k]) <= (1-w[k])*100000;
	
subject to flow_balance {n in BUS}:
	sum{k in NLINE: 