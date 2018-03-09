$OnText
French power sector financial modelling for only renewable energies as supply technologies (Offshore and Onshore wind, PV and Hydro)
and Battery and PHS (pumped hydro storage) as storage technologies, considering reserve requirements, for 2016;
Linear optimisation using one-hour time step with respect to Investment Cost.
By Behrang SHIRIZADEH -  March 2018
$Offtext

*-------------------------------------------------------------------------------
*                                Defining the sets
*-------------------------------------------------------------------------------
sets     i               'all hours'                     /0*8783/
         h(i)            'experimental period'           /0*4000/
         m               'month'                         /jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec/
         tec             'technology'                    /offshore, onshore, PV, river, lake, PHS, battery, biogas/
         vre(tec)        'variable tecs'                 /offshore, onshore, PV/
         FRR(tec)        'technologies for upward FRR'   /lake, PHS, battery, biogas/
;
alias(h,hh);
*-------------------------------------------------------------------------------
*                                Inputs
*-------------------------------------------------------------------------------
$ontext
2016 had 366 days, and the hours of each month is as below:
January from 0 to 743, February from 744 to 1439, March from 1440 to 2183,
April from 2184 to 2903, May from 2904 to 3647, June from 3648 to 4367,
July from 4368 to 5111, August from 5112 to 5855, September from 5856 to 6575,
October from 6576 to 7319, November from 7320 to 8039 and December from 8040 to 8783.
$offtext
parameter month(i)  /0*743 1, 744*1439 2, 1440*2183 3, 2184*2903 4
                    2904*3647 5, 3648*4367 6, 4368*5111 7, 5112*5855 8
                    5856*6575 9, 6576*7319 10, 7320*8039 11, 8040*8783 12/
$Offlisting
parameter load_factor(vre,i) 'Production profiles of VRE'
/
$ondelim
$include  inputs/vre_inputs.csv
$offdelim
/;
parameter demand(i) 'demand profile in each hour in kW'
/
$ondelim
$include inputs/dem_input.csv
$offdelim
/;
Parameter lake_inflows(m) 'monthly lake inflows in GWh'
*Resource: RTE - Hourly nationwide electricity generation by sectors in 2016 for France
/
$ondelim
$include  inputs/lake_inflows.csv
$offdelim
/ ;
parameter gene_river(i) 'hourly run of river power generation in GWh'
*Resource: RTE - Hourly nationwide electricity generation by sectors in 2016 for France
/
$ondelim
$include  inputs/run_of_river.csv
$offdelim
/ ;
parameter epsilon(vre) 'additional FRR requirement for variable renewable energies because of forecast errors'
/
$ondelim
$include  inputs/reserve_requirements.csv
$offdelim
/ ;
parameter capa_ex(tec) 'existing capacities of the technologies by December 2017 in GW'
*Resource: RTE
/
$ondelim
$include  inputs/existing_capacities.csv
$offdelim
/ ;
$ontext
Resource for the prices : EUR 26950 EN – Joint Research Centre – Institute for Energy and Transport;
"Energy Technology Reference Indicator (ETRI) projections for 2010-2050", 2014, ISBN 978-92-79-44403-6.
$offtext
parameter capex(tec) 'annualized capex cost in M€/GW/year'
/
$ondelim
$include  inputs/annuities.csv
$offdelim
/ ;
parameter fOM(tec) 'annualized fixed operation and maintenance costs M€/GW'
/
$ondelim
$include  inputs/fO&M.csv
$offdelim
/ ;
Parameter vOM(tec) 'Variable operation and maintenance costs in M€/GWh'
/
$ondelim
$include  inputs/vO&M.csv
$offdelim
/ ;
$Onlisting
scalar pump_capa 'pumping capacity in GWh' /9.3/;
scalar reservoir_max 'maximum volume of energy can be stored in PHS reservoir' /180/;
scalar bat_eff_in 'battery charging efficiency' /0.9/;
scalar bat_eff_out 'battery decharging efficiency' /0.9/;
scalar pump_eff 'pump input efficiency' /0.95/;
scalar turb_eff 'turbine output efficiency' /0.9/;
scalar load_uncertainty 'uncertainty coefficient for hourly demand' /0.01/;
scalar delta 'load variation factor'     /0.1/;
*-------------------------------------------------------------------------------
*                                Model
*-------------------------------------------------------------------------------
variables        GENE(tec,h)     'energy generation'
                 CAPA(tec)       'capacity'
                 STORAGE(h)      'hourly electricity input of battery storage'
                 COST            'final investment cost'
                 PUMP(h)         'pumping for PHS facilities'
                 RSV_FRR(FRR)    'required upward frequency restoration reserve'
positive variables GENE(tec,h), CAPA(tec), STORAGE(h), PUMP(h) ,RSV_FRR(FRR);
equations        gene_vre        'variables renewable profiles generation'
                 gene_capa       'capacity and genration relation for technologies'
                 capa_FRR        'capacity needed for the secondary reserve requirements'
                 batt_max        'generation of battery should be less than stored energy'
                 lake_res        'constraint on water for lake reservoirs'
                 adequacy        'supply/demand relation'
                 PHS_max         'maximum PHS generation'
                 reserves_FCR    'FCR requirement'
                 reserves_FRR    'FRR requirement'
                 obj             'the final objective function which is COST';
gene_vre(vre,h)..                GENE(vre,h)             =e=     CAPA(vre)*load_factor(vre,h);
capa_FRR(FRR,h)..                CAPA(FRR)               =g=     GENE(FRR,h) + RSV_FRR(FRR);
batt_max(h)..                    GENE('battery',h)       =l=     sum(hh$(ord(hh)<ord(h)),STORAGE(hh)*bat_eff_in - GENE('battery',hh)/bat_eff_out);batt_max..                       sum(h,GENE('battery',h))=l=     bat_eff_out*bat_eff_in*sum(h,STORAGE(h));
lake_res(m)..                    lake_inflows(m)         =g=     sum(h$(month(h) = ord(m)),GENE('lake',h));
PHS_max(h)..                     GENE('PHS',h)           =l=     sum(hh$(ord(hh)<ord(h)),PUMP(hh)*pump_eff - GENE('PHS',hh)/turb_eff);
reserves_FCR..                   sum(FCR, RSV_FCR(FCR))  =e=     fcr_requirement;
reserves_FRR..                   sum(FRR, RSV_FRR(FRR))  =e=     sum(vre,epsilon(vre)*CAPA(vre))+smax(h,demand(h))*load_uncertainty*(1+delta);
adequacy(h)..                    sum(tec,GENE(tec,h))    =g=     demand(h) + PUMP(h) + STORAGE(h);
obj..                            COST                    =e=     (sum(tec,(CAPA(tec)-capa_ex(tec))*capex(tec))+sum(tec,(CAPA(tec)*fOM(tec))) +sum((tec,h),GENE(tec,h)*vOM(tec)))/1000;
*-------------------------------------------------------------------------------
*                                Initial and fixed values
*-------------------------------------------------------------------------------
CAPA.lo(tec) = capa_ex(tec);
CAPA.fx('PHS') = pump_capa;
CAPA.fx('river')= capa_ex('river');
CAPA.fx('lake') = 13;
CAPA.up('onshore') = 174;
PUMP.up(h) = pump_capa;
*-------------------------------------------------------------------------------
*                                Model options
*-------------------------------------------------------------------------------
model flore /all/;
option solvelink=2;
option RESLIM = 1000000;
option lp=cplex;
option Savepoint=1;
option solveopt = replace;
option limcol = 0;
option limrow = 0;
option SOLPRINT = OFF;
*-------------------------------------------------------------------------------
*                                Solve statement
*-------------------------------------------------------------------------------
$If exist res_p1.gdx execute_loadpoint 'res_p1';
Solve flore using lp minimizing COST;
*-------------------------------------------------------------------------------
*                                Display statement
*-------------------------------------------------------------------------------
display cost.l;
display capa.l;
display gene.l;
display demand;
parameter sumdemand      'the whole demand per year in TWh';
sumdemand =  sum(h,demand(h))/1000;
parameter sumgene        'the whole generation per year in TWh';
sumgene = sum((tec,h),GENE.l(tec,h))/1000 - sum (h,gene.l('battery',h))/1000 - sum(h,GENE.l('PHS',h))/1000;
display sumdemand; display sumgene;
parameter battery_storage 'needed energy storage per year in TWh';
battery_storage = sum (h,GENE.l('battery',h))/1000;
display battery_storage;
parameter sumgene_river  'yearly hydro-river energy generation in TWh';
sumgene_river = sum(h,GENE.l('river',h))/1000;
parameter sumgene_lake  'yearly hydro-lake energy generation in TWh';
sumgene_lake = sum(h,GENE.l('lake',h))/1000;
parameter sumgene_PHS  'yearly hydro-PHS energy generation in TWh';
sumgene_PHS = sum(h,GENE.l('PHS',h))/1000;
parameter sumgene_offshore  'yearly offshore energy generation in TWh';
sumgene_offshore = sum(h,GENE.l('offshore',h))/1000;
parameter sumgene_onshore  'yearly onshore energy generation in TWh';
sumgene_onshore = sum(h,GENE.l('onshore',h))/1000;
parameter sumgene_PV  'yearly PV energy generation in TWh';
sumgene_PV = sum(h,GENE.l('PV',h))/1000;
parameter sumgene_biogas 'yearly biogas generation in TWh';
sumgene_biogas = sum(h,GENE.l('biogas',h))/1000;
display sumgene_river;
display sumgene_lake;
display sumgene_PHS;
display sumgene_offshore;
display sumgene_onshore;
display sumgene_PV;
display sumgene_biogas;;
display RSV_FRR.l;
Parameter lcoe(tec);
lcoe(tec) = ((CAPA.l(tec)*(fOM(tec)+capex(tec)))+(sum(h,GENE.l(tec,h))*vOM(tec)))/sum(h,GENE.l(tec,h))*1000;
display lcoe;
*-------------------------------------------------------------------------------
*                                Output
*-------------------------------------------------------------------------------
$Ontext
two main output files;
The .txt file just to have a summary and general idea of the key numbers
The .csv file to have a fine output with hourly data for final data processing and analysis
$Offtext

file results /results4.txt/ ;
*the .txt file  
put results;
put '                            the main results' //
//
'I)Overall investment cost is' cost.l 'b€' //
//
'II)the Renewable capacity ' //
'PV              'capa.l('PV')'  GW'//
'Offshore        'capa.l('offshore')'    GW'//
'onsore          'capa.l('onshore')'     GW' //
'run of river    'CAPA.l('river') 'GW' //
'lake            'CAPA.l('lake') 'GW' //
'biogas          'CAPA.l('biogas')' GW'// 
'Pumped Storage  'CAPA.l('PHS') 'GW' //
'Battery Storage 'capa.l('battery')'     GW' //
//
'III)Needed storage' //
'Battery Storage         'battery_storage'       TWh' //
'PHS Storage             'sumgene_PHS'       TWh' //
//
'IV)Secondary reserve requirements'//
'lake                    'RSV_FRR.l('lake') 'GW'//
'biogass                 'RSV_FRR.l('biogas')  'GW'//
'Pumped Storage          'RSV_FRR.l('PHS') 'GW'//
'Battery                 'RSV_FRR.l('battery') 'GW'//
//
;
file results4 /results41.csv / ;
*the .csv file
put results4;
results4.pc=5;
put 'hour'; put 'Offshore';  put 'Onshore'; put 'PV'; put 'lake' ; put 'river' ; put 'biogas' ; put 'PHS' ; put 'battery'; put 'demand'/ ;
loop (h,
put h.tl; put gene.l('offshore',h); put gene.l('onshore',h); put gene.l('PV',h); put GENE.l('lake',h); put GENE.l('river',h); put GENE.l('biogas',h); put GENE.l('PHS',h);put gene.l('battery',h); put demand(h)/ ;
;);

$onecho > sedscript
s/\,/\;/g
$offecho
$call sed -f sedscript results41.csv > results42.csv

$onecho > sedscript
s/\./\,/g
$offecho
$call sed -f sedscript results42.csv > results4.csv
*-------------------------------------------------------------------------------
*                                The End :D
*-------------------------------------------------------------------------------
