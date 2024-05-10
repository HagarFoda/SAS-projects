%let path=/home/u63388714/EPG1V2/Final_project/TSAClaims2002_2017.csv;
libname tsa "/home/u63388714/EPG1V2/Final_project";
options validvarname=v7;

proc import 
		datafile="/home/u63388714/EPG1V2/Final_project/TSAClaims2002_2017.csv" 
		dbms=csv out=tsa.claims_cleaned replace;
	guessingrows=max;
run;

/*Explore Data Preview the data.*/
proc print data=tsa.claims_cleaned (obs=20);
run;

proc contents data=tsa.claims_cleaned varnum;
run;

proc freq data=tsa.Claims_NoDups;
 tables Claim_Site Disposition Claim_Type / nocum nopercent;
 tables Date_Received Incident_Date / nocum nopercent;
 format Date_Received Incident_Date year4.;
run;

/*Removing Dublicates*/
PROC SORT DATA=tsa.claims_cleaned out=tsa.Claims_CLEANED NODUPKEY 
		dupout=duplicated_removed;
	BY _all_;
RUN;

/*Sort the data by ascending Incident_Date.*/
proc sort data=tsa.Claims_CLEANED;
	by Incident_Date;
run;

data tsa.Claims_CLEANED;
	set tsa.Claims_CLEANED;

	/*Clean the Claim_Site column.*/
	if Claim_Site in ('-', "") then
		Claim_Site="Unknown";

	/*Clean the Disposition column.*/
	if Disposition in ("-", "") then
		Disposition='Unknown';
	else if Disposition='Closed: Canceled' then
		Disposition='Closed:Canceled';
	else if Disposition='losed: Contractor Claim' then
		Disposition='Closed:Contractor Claim';

	/*Clean the Claim_Type column.*/
	if Claim_Type in ("-", "") then
		Claim_Type="Unknown";
	else if Claim_Type='Passenger Property Loss/Personal Injur' then
		Claim_Type='Passenger Property Loss';
	else if Claim_Type='Passenger Property Loss/Personal Injury' then
		Claim_Type='Passenger Property Loss';
	else if Claim_Type='Property Damage/Personal Injury' then
		Claim_Type='Property Damage';
run;

/*Convert all State values to uppercase and all StateName values to proper case.*/
data tsa.Claims_CLEANED;
	set tsa.Claims_CLEANED;
	State=upcase(state);
	StateName=propcase(StateName);
RUN;

/*Create a new column that indicates date issues.*/
data tsa.Claims_CLEANED;
	set tsa.Claims_CLEANED;

	if (Incident_Date > Date_Received or Incident_Date=. or Date_Received=. or 
		year(Incident_Date) < 2002 or year(Incident_Date) > 2017 or 
		year(Date_Received) < 2002 or year(Date_Received) > 2017) then
			Date_Issues="Needs Review";
RUN;

/*8. Add permanent labels and formats.*/
data tsa.Claims_CLEANED;
	set tsa.Claims_CLEANED;
	format Incident_Date Date_Received date9. Close_Amount Dollar20.2;
	label Airport_Code="Airport Code" Airport_Name="Airport Name" 
		Claim_Number="Claim Number" Claim_Site="Claim Site" Claim_Type="Claim Type" 
		Close_Amount="Close Amount" Date_Issues="Date Issues" 
		Date_Received="Date Received" Incident_Date="Incident Date" 
		Item_Category="Item Category";

	/*9. Drop County and City.*/
	drop County City;
RUN;

/*Analyze
1. Analyze the overall data to answer the business questions. Be sure to add appropriate titles.
*/
title "Overall Date Issues in the Data";

proc freq data=TSA.Claims_Cleaned;
	table Date_Issues / nocum nopercent;
run;

title;
ods graphics on;
title "Overall Claims by Year";

proc freq data=TSA.Claims_Cleaned;
	table Incident_Date / nocum nopercent plots=freqplot;
	format Incident_Date year4.;
	where Date_Issues is null;
run;

title;

/*2. Analyze the state-level data to answer the business questions. add appropriate titles.
*/
%let StateName=California;
title "&StateName Claim Types, Claim Sites and Disposition
Frequencies";

proc freq data=TSA.Claims_Cleaned order=freq;
	table Claim_Type Claim_Site Disposition / nocum nopercent;
	where StateName="&StateName" and Date_Issues is null;
run;

title "Close_Amount Statistics for &StateName";

proc means data=TSA.Claims_Cleaned mean min max sum maxdec=0;
	var Close_Amount;
	where StateName="&StateName" and Date_Issues is null;
run;

title;

%let outpath=/home/u63388714/EPG1V2/Final_project;
ods pdf file="&outpath\ClaimsReports.pdf" style=Meadow;
ods proclabel "Enter new procedure title";
