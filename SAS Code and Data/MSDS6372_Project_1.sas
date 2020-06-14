**** Input data steps below ****;
libname xl xlsx '/home/u41086138/6372_Project_1/train_df.xlsx';
data modelData; 
	set xl.Data; 
run;

libname xl xlsx '/home/u41086138/6372_Project_1/test_df.xlsx';
data dataForPred;
	set xl.Sheet1; 
 	priceNum = input(price_doc, 8.); 
 	drop price; rename priceNum = price_doc; 
run;

data forModelAndPred; 
	set modelData dataForPred; 
run;

proc print data=forModelAndPred; run;

**Test for normality***;
Proc sgscatter data=modelData;
	matrix price_doc full_sq floor hospital_beds_raion
	        healthcare_centers_raion university_top_20_raion shopping_centers_raion office_raion; 
run;

PROC UNIVARIATE NORMAL PLOT DATA=modelData; 
	VAR price_doc full_sq floor hospital_beds_raion;
	HISTOGRAM full_sq floor hospital_beds_raion/NORMAL (COLOR=RED W=5);
RUN;

title "Use proc glm for predictions";
ods output predictedValues=predGLMWithCI;
proc glm data=forModelAndPred plots=all;
	model price_doc =
        timestamp build_year
        full_sq floor hospital_beds_raion life_sq num_room max_floor raion_popul kitch_sq preschool_quota
        healthcare_centers_raion university_top_20_raion shopping_centers_raion office_raion
        build_count_block build_count_wood build_count_frame build_count_brick build_count_before_1920                 
        kremlin_km big_road1_km big_road2_km railroad_km bus_terminal_avto_km big_market_km market_shop_km metro_km_walk
        railroad_station_avto_min public_transport_station_km ice_rink_km
        swim_pool_km fitness_km university_km
        X7_14_all X0_17_all X16_29_all X0_13_all /solution clparm cli;
run;
quit;

proc print data=predGLMWithCI; run;

data predGLMWithCI; 
	retain obsNum; 
	set predGLMWithCI; 
	obsNum=_n_; 
run;

proc export data=predGLMWithCI(keep=obsNum Observed Predicted Residual LowerCL UpperCL)
 dbms=xlsx outfile="/home/u41086138/6372_Project_1/GLM_Predic.xlsx" replace;
 sheet = "glm";
run;

title "Use proc glmSelect for predictions with OLS to get fit statistics - does not produce confidence intervals";
ods graphics on;
title "Selection Method forward";                                                                                                                                                                                                         
proc glmselect data=forModelAndPred                                                                                                                                                                           
               seed=1 plots(stepAxis=number)=(criterionPanel ASEPlot CRITERIONPANEL);                                                                                                                                    
model price_doc =
        timestamp 
        full_sq floor hospital_beds_raion life_sq num_room max_floor raion_popul kitch_sq preschool_quota
        healthcare_centers_raion university_top_20_raion shopping_centers_raion office_raion
        build_count_block build_count_wood build_count_frame build_count_brick build_count_before_1920                 
        kremlin_km big_road1_km big_road2_km railroad_km bus_terminal_avto_km big_market_km market_shop_km metro_km_walk
        railroad_station_avto_min public_transport_station_km ice_rink_km
        swim_pool_km fitness_km university_km
        X7_14_all X0_17_all X16_29_all X0_13_all	
           / selection=Forward( choose=CV stop=CV) CVdetails;
output out=predDataOLS p=predOLS; 
run;                                                                                                                                                                                                                     
quit; 

title "Use proc glmSelect for predictions with OLS to get fit statistics - does not produce confidence intervals";
ods graphics on;
title "Selection Method backwards";                                                                                                                                                                                                         
proc glmselect data=forModelAndPred                                                                                                                                                                           
               seed=1 plots(stepAxis=number)=(criterionPanel ASEPlot CRITERIONPANEL);                                                                                                                                    
model price_doc =
        timestamp
        full_sq floor hospital_beds_raion life_sq num_room max_floor raion_popul kitch_sq preschool_quota
        healthcare_centers_raion university_top_20_raion shopping_centers_raion office_raion
        build_count_block build_count_wood build_count_frame build_count_brick build_count_before_1920                 
        kremlin_km big_road1_km big_road2_km railroad_km bus_terminal_avto_km big_market_km market_shop_km metro_km_walk
        railroad_station_avto_min public_transport_station_km ice_rink_km
        swim_pool_km fitness_km university_km
        X7_14_all X0_17_all X16_29_all X0_13_all	
           / selection=backwards( choose=CV stop=CV include=2) CVdetails;
output out=predDataOLS p=predOLS; 
run;                                                                                                                                                                                                                     
quit;

**** Show how to get predicted values with proc glm select and LASSO below ****;
title "Use proc glmSelect for predictions with Lasso - does not produce confidence intervals";
ods graphics on;
title "Selection Method LASSO Using Cross Validation";                                                                                                                                                                                                         
proc glmselect data=forModelAndPred                                                                                                                                                                            
               seed=1 plots(stepAxis=number)=(criterionPanel ASEPlot CRITERIONPANEL);        
               
model price_doc =
        timestamp
        full_sq floor hospital_beds_raion life_sq num_room max_floor raion_popul kitch_sq preschool_quota
        healthcare_centers_raion university_top_20_raion shopping_centers_raion office_raion
        build_count_block build_count_wood build_count_frame build_count_brick build_count_before_1920                 
        kremlin_km big_road1_km big_road2_km railroad_km bus_terminal_avto_km big_market_km market_shop_km metro_km_walk
        railroad_station_avto_min public_transport_station_km ice_rink_km
        swim_pool_km fitness_km university_km
        X7_14_all X0_17_all X16_29_all X0_13_all
			/ selection=LASSO( choose=CV stop=CV) CVdetails ;
output out=predDataLasso p=predlasso; 
run;                                                                                                                                                                                                                     
quit; 

proc print data= predDataLasso; run;

data predDataLasso; 
	retain obsNum; 
	set predDataLasso; 
	obsNum=_n_; 
run;

proc export data=predDataLasso
 dbms=xlsx outfile="/home/u41086138/6372_Project_1/predDataLasso.xlsx" replace;
 sheet = "lasso";
run;

**** Show how to get predicted values with proc autoreg below ****;
**** Input data steps below ****;
libname xl xlsx '/home/u41086138/6372_Project_1/aggdataList.xlsx';
data aggDataAutoReg; 
	set xl.Sheet1; 
run;

data forPredAutoReg; 
	do t = 48 to 59; 
	output; 
	end; 
run;

data dataAutoReg; 
	set aggDataAutoReg 
	forPredAutoReg; 
run;

title "Plot AvgPrice Vs Time";
axis1 label="Month";
proc gplot data=aggDataAutoReg;
   symbol i=spline v=circle h=2;
   plot AvgPrice * t /haxis=axis1;
run;

ods graphics on;
proc glm data=aggDataAutoReg plots=all;
	class t monthyear;
	model AvgPrice=t;
	output out = resPlot;
run;
ods graphics off;

proc print data= resPlot; run;

title "Use proc autoreg for predictions";
proc autoreg data=dataAutoReg plots(unpack);
 model AvgPrice = t / nlag =(1) dwprob; 
 output out = predsAutoRegWithCI p = predAutoReg lcl = lower ucl = upper pm = trend;
run;

**OLS Residual plot to confirm autocorelation**;
ods graphics on;
proc glm data=predsAutoRegWithCI plots=(Diagnostics residuals);
	class t monthyear;
	model AvgPrice=t / solution;
	lsmeans t monthyear / CL adjust=bon;
run;
ods graphics off;

data predsAutoRegWithCI; 
	retain t; 
	set predsAutoRegWithCI; 
run;

proc export data=predsAutoRegWithCI
 dbms=xlsx outfile="/home/u41086138/6372_Project_1/predAutoReg.xlsx" replace;
 sheet = "AvgPrice";
run;





