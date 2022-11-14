
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

#### ---- Decision Variables ---- ####
var Pgen{g in GEN} >= 0;	#Generator power
var Pel	{k in ELINE};		#Power flow in existing lines
var Pnl	{k in NLINE};		#Power flow on new lines
var w	{k in NLINE} binary;#Binary choice of new line install

#### ---- Objective ---- ####
minimize COST: 
	(sum{g in GEN}P[g]*C[g]) + (sum{k in NLINE}C_new[k]*w[k]);
	
#### ---- Constraints ---- ####
subject to gen_limit {g in GEN}:
	P[g] <= Pmax[g];
	
subject to e_line_limit {k in ELINE}:
	-Fe[k] <= Pel[k] <= Fe[k];