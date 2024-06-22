;====================e===================================;
; aim: plot global map for CESM outpout AOD-AA (corrected)
; author: Chenrui Diao
; 2020-01-17
;========================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_SST-and-850wind_trend_map/read_2d_data.ncl"


undef("generate_data")
procedure generate_data(startyr, stopyr, LAND_MASK, sigcheck, sig)
begin
	;=======================================================;	
	; read and process data
	;=======================================================;	
	varname = (/"TREFHT", "U-850", "V-850","PSL"/)
;	varname@mask_ice = True
	varname@mask_ice = False
	
	r_ts = read_2d_data(varname(0), startyr, stopyr, LAND_MASK, sigcheck, sig)
	ts_aer_trend = r_ts[0]
	ts_eff_trend = r_ts[1]
	ts_wff_trend = r_ts[2]
	ts_all_climo = r_ts[3]
	ts_aer_climo = r_ts[4]
	ts_eff_climo = r_ts[5]
	ts_wff_climo = r_ts[6]
	delete(r_ts)

	r_ts = read_2d_data(varname(1), startyr, stopyr, LAND_MASK, sigcheck, sig)
	u_aer_trend = r_ts[0]
	u_eff_trend = r_ts[1]
	u_wff_trend = r_ts[2]
	u_all_climo = r_ts[3]
	delete(r_ts)

	r_ts = read_2d_data(varname(2), startyr, stopyr, LAND_MASK, sigcheck, sig)
	v_aer_trend = r_ts[0]
	v_eff_trend = r_ts[1]
	v_wff_trend = r_ts[2]
	v_all_climo = r_ts[3]
	delete(r_ts)

	r_ts = read_2d_data(varname(3), startyr, stopyr, LAND_MASK, sigcheck, sig)
	psl_aer_trend = r_ts[0]
	psl_eff_trend = r_ts[1]
	psl_wff_trend = r_ts[2]
	psl_all_climo = r_ts[3]
	delete(r_ts)

	;=======================================================;	
	; save to netcdf file for plot
	;=======================================================;	
	data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/data_for_plots/"
	fname = "SST-n-850wind-trend_"+ startyr + "-" + stopyr + "_" + LAND_MASK + "_" + sigcheck + ".nc"
	
	print("saving data to: "+ data_path + fname)
	
	f = addfile(data_path + fname, "c")
	f@author = "Chehnrui"
	f@date = systemfunc("echo $now")

	f->ts_all_climo = ts_all_climo
	f->ts_aer_climo = ts_aer_climo
	f->ts_eff_climo = ts_eff_climo
	f->ts_wff_climo = ts_wff_climo
	f->ts_aer_trend = ts_aer_trend
	f->ts_eff_trend = ts_eff_trend
	f->ts_wff_trend = ts_wff_trend
								  
	f->u_all_climo  = u_all_climo
	f->u_aer_trend  = u_aer_trend 
	f->u_eff_trend  = u_eff_trend 
	f->u_wff_trend  = u_wff_trend 
								  
	f->v_all_climo  = v_all_climo
	f->v_aer_trend  = v_aer_trend 
	f->v_eff_trend  = v_eff_trend 
	f->v_wff_trend  = v_wff_trend 

	f->psl_all_climo  = psl_all_climo
	f->psl_aer_trend  = psl_aer_trend 
	f->psl_eff_trend  = psl_eff_trend 
	f->psl_wff_trend  = psl_wff_trend 

end


