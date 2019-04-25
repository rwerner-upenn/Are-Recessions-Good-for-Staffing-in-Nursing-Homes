*Code to create data and generate paper tables
*"Are Recessions Good for Staffing in Nursing Homes?" 
*American Journal of Health Economics
*R. Tamara Konetzka, Karen B. Lasater, Edward C. Norton, Rachel M. Werner
*code version: November 13, 2018



******************************************************
***************OSHPD data*****************************
******************************************************
* DATA: https://oshpd.ca.gov/data-and-reports/cost-transparency/long-term-care-facility-financial-data/ 

use "2005_LTC_OSHPD.DTA", clear
		drop RN_hppd_05 LVN_hppd_05 AID_hppd_05
	append using "2006_LTC_OSHPD.DTA"
		drop RN_hppd_06 LVN_hppd_06 AID_hppd_06
	append using "2007_LTC_OSHPD.DTA"
		drop RN_hppd_07 LVN_hppd_07 AID_hppd_07
	append using "2008_LTC_OSHPD.DTA"
		drop RN_hppd_08 LVN_hppd_08 AID_hppd_08	
	append using "2009_LTC_OSHPD.DTA"
		drop RN_hppd_09 LVN_hppd_09 AID_hppd_09	
	append using "2010_LTC_OSHPD.DTA"
		drop RN_hppd_10 LVN_hppd_10 AID_hppd_10	
	append using "2011_LTC_OSHPD.DTA"
		drop RN_hppd_11 LVN_hppd_11 AID_hppd_11	
	append using "2012_LTC_OSHPD.DTA"
		drop RN_hppd_12 LVN_hppd_12 AID_hppd_12	

	gen RN_hppd = PRDHR_RN/DAY_TOTL
	gen LVN_hppd = PRDHR_LVN/DAY_TOTL
	gen AID_hppd = PRDHR_NA/DAY_TOTL
	gen totnurs_hppd = RN_hppd + LVN_hppd + AID_hppd

sort FAC_NO year
save "2005-2012_merged_OSHPD.DTA", replace 

*********************************************************************************
**************** AHRF (unemployment data - county level)  ***********************
**************** CROSSWALK to AHRF **********************************************
*********************************************************************************
*DATA: https://data.hrsa.gov/data/download

*AHRF Unemployment Data 1992-2012
use "ahrf1992-2012.dta", clear
	gen county_final=County_name
	replace county_final=county if county_final==""
	replace county_final=upper(county_final)

save "ahrf1992-2012_v2.dta", replace

/*AHRF uses FIPS codes; OSCAR uses SSA state codes;
Use the SSA-->FIPS crosswalk file from http://www.nber.org/data/ssa-fips-state-county-crosswalk.html
to change OSCAR SSA codes to FIPS codes*/
use "CBSAtoCountycrosswalk_FY13.dta", clear
	rename fipscounty st_cty_code /*3,273 unique counties in crosswalk file*/
	merge m:m st_cty_code using "ahrf1992-2012_v2.dta", gen(merge3)
	keep if merge3==3
	drop if survyear <"2005"
	drop if unemp_rate==.
save "ahrf2005-2012", replace

*********************************************************************************
**************** OSHPD **********************************************************
*********************************************************************************
***Merge crosswalk and AHRF data with OSHPD (nursing home) data
use "2005-2012_merged_OSHPD.DTA", clear
	gen state="CA"
	gen county_final= upper(County)
	rename year survyear
	gen year1 = string(survyear, "%04.0f")
	drop survyear
	rename year1 survyear
	
	merge m:m county_final state survyear using "ahrf2005-2012", gen(merge2) 
	keep if merge2==3  | merge2==1
save "final_nursinghome_OSHPD.dta", replace

*********************************************************************************
****************** CROSSWALK OSHPD AND OSCAR DATA (facility level)***************
*********************************************************************************
	rename FAC_NO OSHPD_ID
	tostring OSHPD_ID, replace
	bysort OSHPD_ID: gen OSHPDdriver=_n==1
	tab OSHPDdriver, mis

	collapse BED_END, by(OSHPD_ID)
	drop BED_END

*********
**FINAL**
*********
save "unemployment_staffing_final_CA2005_2012_obslevel_MASTER.dta", replace 

********************************************************************************
****************************** 2005 - 2012 DATASET ******************************
*********************************************************************************
	drop finaldriver
	drop if survyear<"2005"
	bysort FAC_NO: gen finaldriver=_n==1 
	keep if Type_of_Care == "INTERMEDIATE CARE" | Type_of_Care == "Skilled Nursing & Intermediate" | Type_of_Care == "Skilled Nursing & DD Care" | Type_of_Care == "Intermediate Care" | Type_of_Care == "Intermediate Care Only" | Type_of_Care =="SKILLED NURSING" |  Type_of_Care== "Skilled Nursing & Hospice" | Type_of_Care=="Skilled Nursing Only" | Type_of_Care=="Skilled Nursing & Sub-Acute"

save "unemployment_staffing_final_CA2005_2012_obslevel_MASTER_05-12_tempagency.dta"

*********************************************************************************
**************************NH AFFILIATED WITH HOSPITALS **************************
*********************************************************************************
*exclude nursing homes that are affiliated with hospitals
drop if hospbase==1

*********************************************************************************
****************************** STAFFING  ****************************************
*********************************************************************************
*generating staffing including temp workers and skill mix
	gen tempRN_05=TMP_HR_RN/DAY_TOTL_05 if survyear=="2005"
	gen tempLVN_05=TMP_HR_LVN/DAY_TOTL_05 if survyear=="2005"
	gen tempAid_05=TMP_HR_NA/DAY_TOTL_05 if survyear=="2005"

	gen tempRN_06=TMP_HR_RN/DAY_TOTL_06 if survyear=="2006"
	gen tempLVN_06=TMP_HR_LVN/DAY_TOTL_06 if survyear=="2006"
	gen tempAid_06=TMP_HR_NA/DAY_TOTL_06 if survyear=="2006"

	gen tempRN_07=TMP_HR_RN/DAY_TOTL_07 if survyear=="2007"
	gen tempLVN_07=TMP_HR_LVN/DAY_TOTL_07 if survyear=="2007"
	gen tempAid_07=TMP_HR_NA/DAY_TOTL_07 if survyear=="2007"

	gen tempRN_08=TMP_HR_RN/DAY_TOTL_08 if survyear=="2008"
	gen tempLVN_08=TMP_HR_LVN/DAY_TOTL_08 if survyear=="2008"
	gen tempAid_08=TMP_HR_NA/DAY_TOTL_08 if survyear=="2008"

	gen tempRN_09=TMP_HR_RN/DAY_TOTL_09 if survyear=="2009"
	gen tempLVN_09=TMP_HR_LVN/DAY_TOTL_09 if survyear=="2009"
	gen tempAid_09=TMP_HR_NA/DAY_TOTL_09 if survyear=="2009"

	gen tempRN_10=TMP_HR_RN/DAY_TOTL_10 if survyear=="2010"
	gen tempLVN_10=TMP_HR_LVN/DAY_TOTL_10 if survyear=="2010"
	gen tempAid_10=TMP_HR_NA/DAY_TOTL_10 if survyear=="2010"

	gen tempRN_11=TMP_HR_RN/DAY_TOTL_11 if survyear=="2011"
	gen tempLVN_11=TMP_HR_LVN/DAY_TOTL_11 if survyear=="2011"
	gen tempAid_11=TMP_HR_NA/DAY_TOTL_11 if survyear=="2011"

	gen tempRN_12=TMP_HR_RN/DAY_TOTL_12 if survyear=="2012"
	gen tempLVN_12=TMP_HR_LVN/DAY_TOTL_12 if survyear=="2012"
	gen tempAid_12=TMP_HR_NA/DAY_TOTL_12 if survyear=="2012"

	gen tempRN_hppd = tempRN_05 if survyear=="2005"
	replace tempRN_hppd = tempRN_06 if survyear=="2006"
	replace tempRN_hppd = tempRN_07 if survyear=="2007"
	replace tempRN_hppd = tempRN_08 if survyear=="2008"
	replace tempRN_hppd = tempRN_09 if survyear=="2009"
	replace tempRN_hppd = tempRN_10 if survyear=="2010"
	replace tempRN_hppd = tempRN_11 if survyear=="2011"
	replace tempRN_hppd = tempRN_12 if survyear=="2012"

	gen tempLVN_hppd = tempLVN_05 if survyear=="2005"
	replace tempLVN_hppd = tempLVN_06 if survyear=="2006"
	replace tempLVN_hppd = tempLVN_07 if survyear=="2007"
	replace tempLVN_hppd = tempLVN_08 if survyear=="2008"
	replace tempLVN_hppd = tempLVN_09 if survyear=="2009"
	replace tempLVN_hppd = tempLVN_10 if survyear=="2010"
	replace tempLVN_hppd = tempLVN_11 if survyear=="2011"
	replace tempLVN_hppd = tempLVN_12 if survyear=="2012"

	gen tempAID_hppd = tempAid_05 if survyear=="2005"
	replace tempAID_hppd = tempAid_06 if survyear=="2006"
	replace tempAID_hppd = tempAid_07 if survyear=="2007"
	replace tempAID_hppd = tempAid_08 if survyear=="2008"
	replace tempAID_hppd = tempAid_09 if survyear=="2009"
	replace tempAID_hppd = tempAid_10 if survyear=="2010"
	replace tempAID_hppd = tempAid_11 if survyear=="2011"
	replace tempAID_hppd = tempAid_12 if survyear=="2012"

	replace RN_hppd = RN_hppd + tempRN_hppd
	replace LVN_hppd = LVN_hppd + tempLVN_hppd
	replace AID_hppd = AID_hppd + tempAID_hppd

	gen totnurs_hppd = RN_hppd + LVN_hppd + AID_hppd 

* RN/TOTAL 
	gen skillmix_RN = RN_hppd/totnurs_hppd

*********************************************************************************
************************* OVERALL STAFFING LEVEL ********************************
*********************************************************************************
*Per OSCAR exclusion criteria:
	drop if totnurs_hppd>12
	drop if RN_hppd==0 & Bed_Size!="1-59"
	bysort OSHPD_ID: egen avg_totnurs_hppd = mean(totnurs_hppd)
	gen low_totnurs=.
	replace low_totnurs=1 if avg_totnurs_hppd <=3.57
	replace low_totnurs=0 if low_totnurs!=1

*********************************************************************************
**************************** PROFIT STATUS **************************************
*********************************************************************************
*exclude if government owned
	replace Investor=1 if Type_of_Control=="INVESTOR OWNED" | Type_of_Control=="Investor Owned"
	replace Not_for_profit=0 if Investor==1
	replace Not_for_profit=1 if Type_of_Control=="NOT-FOR-PROFIT" | Type_of_Control=="Not-for-Profit" | Type_of_Control=="CHURCH RELATED"
	replace Investor=0 if Not_for_profit==1
	drop if Type_of_Control=="GOVERNMENTAL" | Type_of_Control=="Governmental"

*********************************************************************************
**************************** BED SIZE *******************************************
*********************************************************************************
	bysort OSHPD_ID: egen Bed_Avg= mean(BED_AVG)
	gen small=.
		replace small=1 if BED_AVG<= 95.02
		replace small=0 if small!=1
	gen large=.
		replace large=1 if small==0
		replace large=0 if large!=1

*2005-2012
save "unemployment_staffing_final_CA2005_2012_obslevel_MASTER_final_05-12_temp.dta", replace

*********************************************************************************
****************************  For Tables  ***************************************
*********************************************************************************
	bysort OSHPD_ID: egen avg_RN_hppd = mean(RN_hppd)
	bysort OSHPD_ID: egen avg_LVN_hppd = mean(LVN_hppd)
	bysort OSHPD_ID: egen avg_AID_hppd = mean(AID_hppd)
	bysort OSHPD_ID: egen avg_skillmix_RN = mean(skillmix_RN)
	gen small=.
		replace small=1 if BED_AVG<=95.02
		replace small=0 if small!=1
	gen large=.
		replace large=1 if small==0
		replace large=0 if large!=1
	bysort OSHPD_ID: egen TOT_HC_REV_Avg= mean(TOT_HC_REV)
	format TOT_HC_REV_Avg %12.0g

*Defining BedSize by #RNS (5/3/2016)
	gen RNhrs=. 
	replace RNhrs= avg_RN_hppd*BED_AVG
	bysort OSHPD_ID: egen avg_RNhrs = mean(RNhrs)

**30th PERCENTILE
*calculating RN hours per week
	gen RNhrs_wk=.
		replace RNhrs_wk= RNhrs*7
		bysort OSHPD_ID: egen avg_RNhrs_wk = mean(RNhrs_wk)
	gen smallRN=.
		replace smallRN=1 if BED_AVG<=62
		replace smallRN=0 if smallRN!=1

*2005-2012
save "unemployment_staffing_final_CA2005_2012_obslevel_MASTER_final_05-12_tables_temp.dta", replace

*********************************************************************************
**************************For REGRESSIONS****************************************
*********************************************************************************
*2005-2012
use "unemployment_staffing_final_CA2005_2012_obslevel_MASTER_final_05-12_tables_temp.dta", clear
	replace state="California" if state=="CA" 
	*merge in demongraphic variables, Data from:https://factfinder.census.gov/faces/nav/jsf/pages/download_center.xhtml
	merge m:m state using "/ACS_RobustnessChecks_final.dta", gen(mergeACS)
	keep if mergeACS==3

	gen y2005=1 if survyear=="2005"
	replace y2005=0 if survyear!="2005"
	gen y2006=1 if survyear=="2006"
	replace y2006=0 if survyear!="2006"
	gen y2007=1 if survyear=="2007"
	replace y2007=0 if survyear!="2007"
	gen y2008=1 if survyear=="2008"
	replace y2008=0 if survyear!="2008"
	gen y2009=1 if survyear=="2009"
	replace y2009=0 if survyear!="2009"
	gen y2010=1 if survyear=="2010"
	replace y2010=0 if survyear!="2010"
	gen y2011=1 if survyear=="2011"
	replace y2011=0 if survyear!="2011"
	gen y2012=1 if survyear=="2012"
	replace y2012=0 if survyear!="2012"

****************
*STAFFING*******
****************
	gen RN_hppd60 = RN_hppd*60
	gen LVN_hppd60 = LVN_hppd*60
	gen AID_hppd60 = AID_hppd*60
	gen totnurs_hppd60= totnurs_hppd*60

	bysort OSHPD_ID: egen RN_hppd60_avg=mean(RN_hppd60)
	bysort OSHPD_ID: egen LVN_hppd60_avg=mean(LVN_hppd60)
	bysort OSHPD_ID: egen AID_hppd60_avg=mean(AID_hppd60)
	bysort OSHPD_ID: egen totnurs_hppd60_avg=mean(totnurs_hppd60)

***************************************************************************************
***************************************************************************************
***************************************************************************************
*****************FOR PAPER TABLES******************************************************
***************************************************************************************
***************************************************************************************
***************************************************************************************

*** TABLE 1***
	sum RN_hppd60_avg if finaldriver==1
	sum LVN_hppd60_avg if finaldriver==1
	sum AID_hppd60_avg if finaldriver==1
	sum totnurs_hppd60_avg if finaldriver==1
	sum skillmix_RN_avg if finaldriver==1

	sum BED_AVG if finaldriver==1
	tab small if finaldriver==1, mis
	tab large if finaldriver==1, mis
	tab low_totnurs if finaldriver==1

	tab Investor if finaldriver==1, mis
	tab Not_for_profit if finaldriver==1, mis
	tab Governmental if finaldriver==1, mis
	sum TOT_HC_REV_Avg

**TABLE 2***
	*California NHs
	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	*Stratified by bed size with year and nursing home FE
	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	*Stratified by staffing level with year and nursing home FE
	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	*Stratified by profit status with year and nursing home FE
	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Investor==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Investor==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate  y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Investor==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate  y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Investor==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Investor==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Not_for_profit==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Not_for_profit==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Not_for_profit==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Not_for_profit==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Not_for_profit==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)

**TABLE 3***
	*Total Health Care Revenue in nursing homes as DV
	eststo: xtreg TOT_HC_REV unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	*Stratified by bed size with year and nursing home FE
	eststo: xtreg TOT_HC_REV unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg TOT_HC_REV unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	*Stratified by staffing level with year and nursing home FE
	eststo: xtreg TOT_HC_REV unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg TOT_HC_REV unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0, fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	*Stratified by profit status with year and nursing home FE
	eststo: xtreg TOT_HC_REV unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Investor==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg TOT_HC_REV unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Not_for_profit==1, fe i(OSHPD_ID) vce(cluster OSHPD_ID)

***TABLE 4***
	**Log the DV
	gen log_RN_hppd60= log(RN_hppd60)
	gen log_LVN_hppd60= log(LVN_hppd60)
	gen log_AID_hppd60= log(AID_hppd60)
	gen log_totnurs_hppd60= log(totnurs_hppd60)
	gen log_skillmix_RN= log(skillmix_RN)
	gen log_TOT_HC_REV= log(TOT_HC_REV)

	destring survyear, replace
	encode state, gen(state_new)
	*Demographic controls, total number of beds, state-specific controls
	eststo: xtreg RN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg LVN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg AID_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg RNLPN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)

	*Demographic controls, total number of beds, state-specific controls w/ logged DV
	eststo: xtreg log_RN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg log_LVN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg log_AID_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg log_RNLPN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)

	*Demographic controls, total number of beds, state-year dummies
	eststo: xtreg RN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg LVN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg AID_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg RNLPN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)

	*Demographic controls, total number of beds, state-year dummies w/ logged DV
	eststo: xtreg log_RN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg log_LVN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg log_AID_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg log_RNLPN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)

	encode county, gen(county_new)
	destring survyear, replace
	*Demographic controls, total number of beds, county-specific trends
	eststo: xtreg RN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_newtotbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg LVN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg AID_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg RNLPN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)

	*Demographic controls, total number of beds, county-specific trends w/ logged DV
	eststo: xtreg log_RN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg log_LVN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_newtotbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg log_AID_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg log_RNLPN_hppd60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)

 
***APPENDIX TABLE 1 *** 
	*California NHs
	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	*Stratified by bed size with year and nursing home FE
	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	*Stratified by staffing level with year and nursing home FE
	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	*Stratified by profit status with year and nursing home FE
	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Investor==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Investor==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate  y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Investor==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate  y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Investor==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Investor==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)

	eststo: xtreg RN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Not_for_profit==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg LVN_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Not_for_profit==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg AID_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Not_for_profit==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg totnurs_hppd60 unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Not_for_profit==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)
	eststo: xtreg skillmix_RN unemp_rate y2006 y2007 y2008 y2009 y2010 y2011 y2012 if Not_for_profit==1 [aweight=Bed_Avg], fe i(OSHPD_ID) vce(cluster OSHPD_ID)

***APPENDIX TABLE 2 *** 
			use "unemployment_staffing_final.dta", clear 
			drop if survyear<"2005"
			gen skillmix_RN = hprd_totrns/hprd_totnurs
			drop if hospitalbase==1
			bysort prov: egen avg_hprd_totnurs = mean(hprd_totnurs)		 
			drop if excl_staff==1
			drop if excl_staff==3
			drop if excl_staff==4

			gen low_totnurs=.
			replace low_totnurs=1 if avg_hprd_totnurs <=3.91
			replace low_totnurs=0 if low_totnurs!=1
			tab low_totnurs if prov_driver==1

			drop if control=="GOVERNMENT"
			drop if control=="" 

			bysort prov: egen totbeds_avg= mean(totbeds)
			gen small=.
			replace small=1 if totbeds_avg<= 108.74
			replace small=0 if small!=1
			gen large=.
			replace large=1 if small==0
			replace large=0 if large!=1

			bysort prov: egen avg_hprd_totrns = mean(hprd_totrns)
			bysort prov: egen avg_hprd_totlpn = mean(hprd_totlpn)
			bysort prov: egen avg_hprd_totaides = mean(hprd_totaides)
			bysort prov: egen avg_skillmix_RN = mean(skillmix_RN)

			gen RNhrs=. 
			replace RNhrs= avg_hprd_totrns*totbeds_avg
			bysort prov: egen avg_RNhrs = mean(RNhrs)

			gen RNhrs_wk=.
			replace RNhrs_wk= RNhrs*7
			bysort prov: egen avg_RNhrs_wk = mean(RNhrs_wk)

			gen smallRN=.
			replace smallRN=1 if totbeds_avg<=60
			replace smallRN=0 if smallRN!=1
			save "unemployment_staffing_final_tables_05-12.dta", replace 

			keep if state=="CA"

			tostring state1, replace
			drop state
			rename state1 state

			merge m:m state using "ACS_RobustnessChecks_final.dta", gen(mergeACS)
			keep if mergeACS==3
			encode prov, gen(provd)

			gen y2005=1 if survyear=="2005"
			replace y2005=0 if survyear!="2005"
			gen y2006=1 if survyear=="2006"
			replace y2006=0 if survyear!="2006"
			gen y2007=1 if survyear=="2007"
			replace y2007=0 if survyear!="2007"
			gen y2008=1 if survyear=="2008"
			replace y2008=0 if survyear!="2008"
			gen y2009=1 if survyear=="2009"
			replace y2009=0 if survyear!="2009"
			gen y2010=1 if survyear=="2010"
			replace y2010=0 if survyear!="2010"
			gen y2011=1 if survyear=="2011"
			replace y2011=0 if survyear!="2011"
			gen y2012=1 if survyear=="2012"
			replace y2012=0 if survyear!="2012"

			gen hprd_totrns60 = hprd_totrns*60
			gen hprd_totlpn60 = hprd_totlpn*60
			gen hprd_totaides60 = hprd_totaides*60
			gen hprd_totnurs60 = hprd_totnurs*60
			gen skillmix_RN60 = skillmix_RN*60
			gen hprd_RNLPN60= hprd_totrns60+hprd_totlpn60

	*California nursing homes
	eststo: xtreg hprd_totrns60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totlpn60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totaides60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totnurs60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(provd) vce(cluster provd)
	eststo: xtreg skillmix_RN unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_RNLPN60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012, fe i(provd) vce(cluster provd)

	*Stratified by bed size with year and nursing home FE
	eststo: xtreg hprd_totrns60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totlpn60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totaides60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totnurs60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1, fe i(provd) vce(cluster provd)
	eststo: xtreg skillmix_RN unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==1, fe i(provd) vce(cluster provd)

	eststo: xtreg hprd_totrns60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totlpn60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totaides60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totnurs60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0, fe i(provd) vce(cluster provd)
	eststo: xtreg skillmix_RN unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if smallRN==0, fe i(provd) vce(cluster provd)

	*Stratified by staffing level with year and nursing home FE
	eststo: xtreg hprd_totrns60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totlpn60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totaides60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totnurs60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1, fe i(provd) vce(cluster provd)
	eststo: xtreg skillmix_RN unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==1, fe i(provd) vce(cluster provd)

	eststo: xtreg hprd_totrns60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totlpn60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totaides60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totnurs60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0, fe i(provd) vce(cluster provd)
	eststo: xtreg skillmix_RN unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if low_totnurs==0, fe i(provd) vce(cluster provd)

	*Stratified by profit status with year and nursing home FE
	eststo: xtreg hprd_totrns60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if control== "FOR-PROFIT", fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totlpn60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if control== "FOR-PROFIT", fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totaides60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if control== "FOR-PROFIT", fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totnurs60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if control== "FOR-PROFIT", fe i(provd) vce(cluster provd)
	eststo: xtreg skillmix_RN unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if control== "FOR-PROFIT", fe i(provd) vce(cluster provd)

	eststo: xtreg hprd_totrns60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if control== "NON-PROFIT", fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totlpn60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if control== "NON-PROFIT", fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totaides60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if control== "NON-PROFIT", fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totnurs60 unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if control== "NON-PROFIT", fe i(provd) vce(cluster provd)
	eststo: xtreg skillmix_RN unemp_rate y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 if control== "NON-PROFIT", fe i(provd) vce(cluster provd)

***APPENDIX TABLE 3 *** 
	**COUNTY-SPECIFIC TRENDS
	encode county, gen(county_new)
	*California
	eststo: xtreg hprd_totrns60 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new unemp_rate totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totlpn60  y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new unemp_rate totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totaides60 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new unemp_rate totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totnurs60 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new unemp_rate totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg skillmix_RN y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new unemp_rate totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_RNLPN60 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#county_new unemp_rate totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)

	*LINEAR STATE_YEAR TRENDS
	destring survyear, replace
	encode state, gen(state_new)

	eststo: xtreg hprd_totrns60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totlpn60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totaides60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totnurs60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg skillmix_RN unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_RNLPN60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 c.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)

	*STATE_YEAR DUMMIES
	eststo: xtreg hprd_totrns60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totlpn60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totaides60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_totnurs60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg skillmix_RN unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)
	eststo: xtreg hprd_RNLPN60 unemp_rate y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 i.survyear#state_new totbeds highschool_dropout some_college college less_than_yr5 yr5_y17 yr20_y29 greater_than_yr65 prop_black prop_hispanic, fe i(provd) vce(cluster provd)


