;====================e===================================;
; aim: plot global map for CESM outpout AOD-AA (corrected)
; author: Chenrui Diao
; 2020-01-17
;========================================================;
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/read_2d_data_with_bb.ncl"


undef("generate_data")
procedure generate_data(startyr, stopyr, LAND_MASK, sigcheck, sig)
begin
	;=======================================================;	
	; read and process data
	;=======================================================;	
	varname = (/"PRECT"/)
	varname@mask_ice = False
	
	r_prect = read_2d_data(varname(0), startyr, stopyr, LAND_MASK, sigcheck, sig)
	prect_aer_trend = r_prect[0]
	prect_eff_trend = r_prect[1]
	prect_wff_trend = r_prect[2]
	prect_all_climo = r_prect[3]
	prect_aer_climo = r_prect[4]
	prect_eff_climo = r_prect[5]
	prect_wff_climo = r_prect[6]
	prect_bmb_trend = r_prect[7]
	prect_bmb_climo = r_prect[8]

	delete(r_prect)

	;=======================================================;	
	; save to netcdf file for plot
	;=======================================================;	
	data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/data_for_plots/"
	fname = "PRECT-trend_"+ startyr + "-" + stopyr + ".nc"
	
	print("saving data to: "+ data_path + fname)
	
	f = addfile(data_path + fname, "c")
	f@author = "Chehnrui"
	f@date = systemfunc("echo $now")

	f->prect_all_climo = prect_all_climo
	f->prect_aer_climo = prect_aer_climo
	f->prect_eff_climo = prect_eff_climo
	f->prect_wff_climo = prect_wff_climo
	f->prect_bmb_climo = prect_bmb_climo
	f->prect_aer_trend = prect_aer_trend
	f->prect_eff_trend = prect_eff_trend
	f->prect_wff_trend = prect_wff_trend
	f->prect_bmb_trend = prect_bmb_trend
								  

end


