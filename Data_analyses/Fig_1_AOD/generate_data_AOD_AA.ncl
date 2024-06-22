;====================e===================================;
; aim: plot global map for CESM outpout AOD-AA (corrected)
; author: Chenrui Diao
; 2020-01-17
;========================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/read_2d_data_with_bb.ncl"

undef("generate_data")
procedure generate_data(startyr, stopyr, LAND_MASK, sigcheck, sig)
begin
	;=======================================================;	
	; read and process data
	;=======================================================;	
	varname = (/"AOD-AA"/)
;	varname@mask_ice = True
	varname@mask_ice = False
	
	r_ts = read_2d_data(varname(0), startyr, stopyr, LAND_MASK, sigcheck, sig)
	aod_aa_aer_trend = r_ts[0]
	aod_aa_eff_trend = r_ts[1]
	aod_aa_wff_trend = r_ts[2]
	aod_aa_all_climo = r_ts[3]
	aod_aa_aer_climo = r_ts[4]
	aod_aa_eff_climo = r_ts[5]
	aod_aa_wff_climo = r_ts[6]
	
	aod_aa_bmb_trend = r_ts[7]
	aod_aa_bmb_climo = r_ts[8]
	delete(r_ts)


	;=======================================================;	
	; save to netcdf file for plot
	;=======================================================;	
	data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/data_for_plots/"
	fname = "AOD-AA-trend_"+ startyr + "-" + stopyr + ".nc"
	
	print("saving data to: "+ data_path + fname)
	
	f = addfile(data_path + fname, "c")
	f@author = "Chehnrui"
	f@date = systemfunc("echo $now")

	f->aod_aa_all_climo = aod_aa_all_climo
	f->aod_aa_aer_climo = aod_aa_aer_climo
	f->aod_aa_eff_climo = aod_aa_eff_climo
	f->aod_aa_wff_climo = aod_aa_wff_climo
	f->aod_aa_bmb_climo = aod_aa_bmb_climo
	
	
	f->aod_aa_aer_trend = aod_aa_aer_trend
	f->aod_aa_bmb_trend = aod_aa_bmb_trend
	f->aod_aa_eff_trend = aod_aa_eff_trend
	f->aod_aa_wff_trend = aod_aa_wff_trend
								  
end


