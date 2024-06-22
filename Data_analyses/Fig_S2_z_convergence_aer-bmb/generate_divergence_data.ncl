;====================e===================================;

;=======================================================;	
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/func_lib/read_all-xaer-xbmb_data_all_ens.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/func_lib/mask_icechange_region.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_SST-and-850wind_trend_map/read_2d_data.ncl"

	
procedure read_divergence(lev, startyr, stopyr)
	
begin
	u_name = "U-" + lev
	u_name@mask_ice = False
	
	v_name = "V-" + lev
	v_name@mask_ice = False
	
    r_ts = read_2d_data(u_name, startyr, stopyr, 0,0,0)
    u_aer_trend = r_ts[0]
    u_eff_trend = r_ts[1]
    u_wff_trend = r_ts[2]
    u_all_climo = r_ts[3]
    delete(r_ts)

    r_ts = read_2d_data(v_name, startyr, stopyr,0,0,0)
    v_aer_trend = r_ts[0]
    v_eff_trend = r_ts[1]
    v_wff_trend = r_ts[2]
    v_all_climo = r_ts[3]
    delete(r_ts)

	;==========================;	
	; calculate divergence
	;==========================;	
	dv_a_avg_climo = uv2dvF_Wrap(u_all_climo, v_all_climo)
	aer_trend = uv2dvF_Wrap(u_aer_trend, v_aer_trend)
	eff_trend = uv2dvF_Wrap(u_eff_trend, v_eff_trend)
	wff_trend = uv2dvF_Wrap(u_wff_trend, v_wff_trend)

	;==========================;	
	; write to file
	;==========================;	
	data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_convergence_map/"
	fname = "divergence_" + lev + "hPa_"+ startyr + "-" + stopyr +  ".nc"
	
	print("saving data to: "+ data_path + fname)
	f = addfile(data_path + fname, "c")
	var_o = "dv" + lev + "_all_climo"
	f->$var_o$ = dv_a_avg_climo
	
	var_o = "dv" + lev + "_aer_trend"
	f->$var_o$ = aer_trend
	var_o = "dv" + lev + "_eff_trend"
	f->$var_o$ = eff_trend
	var_o = "dv" + lev + "_wff_trend"
	f->$var_o$ = wff_trend

end
