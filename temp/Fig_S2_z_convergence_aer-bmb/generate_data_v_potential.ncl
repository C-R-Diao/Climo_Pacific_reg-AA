;====================e===================================;
; aim: plot global map for CESM outpout AOD-AA (corrected)
; author: Chenrui Diao
; 2020-01-17
;========================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_SST-and-850wind_trend_map/read_2d_data.ncl"


undef("generate_data_v_potential")
procedure generate_data_v_potential(startyr, stopyr, sigcheck, sig)
begin
	;=======================================================;	
	; read and process data
	;=======================================================;	
	varname = (/"PSL", "U-200", "V-200", "Z3-200", "Z3-500", "U-850", "V-850", "FLNT"/)
	varname@mask_ice = False
	
	LAND_MASK = 0

	r_ts = read_2d_data(varname(0), startyr, stopyr, LAND_MASK, sigcheck, sig)
	psl_aer_trend = r_ts[0]
	psl_eff_trend = r_ts[1]
	psl_wff_trend = r_ts[2]
	psl_all_climo = r_ts[3]
	delete(r_ts)

	r_ts = read_2d_data(varname(1), startyr, stopyr, LAND_MASK, sigcheck, sig)
	u_aer_trend = r_ts[0]
	u_eff_trend = r_ts[1]
	u_wff_trend = r_ts[2]
	u_all_climo = r_ts[3]
	u_aer_climo = r_ts[4]
	u_eff_climo = r_ts[5]
	u_wff_climo = r_ts[6]
	delete(r_ts)

	r_ts = read_2d_data(varname(2), startyr, stopyr, LAND_MASK, sigcheck, sig)
	v_aer_trend = r_ts[0]
	v_eff_trend = r_ts[1]
	v_wff_trend = r_ts[2]
	v_all_climo = r_ts[3]
	v_aer_climo = r_ts[4]
	v_eff_climo = r_ts[5]
	v_wff_climo = r_ts[6]
	delete(r_ts)
	
	r_ts = read_2d_data(varname(3), startyr, stopyr, LAND_MASK, sigcheck, sig)
	z200_aer_trend = r_ts[0]
	z200_eff_trend = r_ts[1]
	z200_wff_trend = r_ts[2]
	z200_all_climo = r_ts[3]
	delete(r_ts)
	
	r_ts = read_2d_data(varname(4), startyr, stopyr, LAND_MASK, sigcheck, sig)
	z500_aer_trend = r_ts[0]
	z500_eff_trend = r_ts[1]
	z500_wff_trend = r_ts[2]
	z500_all_climo = r_ts[3]
	delete(r_ts)

	r_ts = read_2d_data(varname(5), startyr, stopyr, LAND_MASK, sigcheck, sig)
	u850_aer_trend = r_ts[0]
	u850_eff_trend = r_ts[1]
	u850_wff_trend = r_ts[2]
	u850_all_climo = r_ts[3]
	delete(r_ts)

	r_ts = read_2d_data(varname(6), startyr, stopyr, LAND_MASK, sigcheck, sig)
	v850_aer_trend = r_ts[0]
	v850_eff_trend = r_ts[1]
	v850_wff_trend = r_ts[2]
	v850_all_climo = r_ts[3]
	delete(r_ts)
	
	r_ts = read_2d_data(varname(7), startyr, stopyr, LAND_MASK, sigcheck, sig)
	fl_aer_trend = r_ts[0]
	fl_eff_trend = r_ts[1]
	fl_wff_trend = r_ts[2]
	fl_all_climo = r_ts[3]
	delete(r_ts)
	;=======================================================;	
	; calculate velocity potential
	; 1st dimension stores: stream function and velocity potential
	;=======================================================;	
	function cal_sfvp(u, v)
	local temp, x
	begin
		x = uv2sfvpF(u, v)
		
		x@long_name = "stream function and velocity potential calculated from: " + u@long_name + " and " + v@long_name
		x@variables = "0th: stream function; 1st velocity potential"
		
		x!0 = "var"
		x!1 = "lat"
		x!2 = "lon"
		x&lat = u&lat
		x&lon = u&lon

		x@units_of_velocity_potential = "10^5 m^2/s"
		x = (/x*0.00001/)

	return(x)
	end
	
	sfvp_aer_trend = cal_sfvp(u_aer_trend, v_aer_trend)
	sfvp_eff_trend = cal_sfvp(u_eff_trend, v_eff_trend)
	sfvp_wff_trend = cal_sfvp(u_wff_trend, v_wff_trend)
	printVarSummary(sfvp_aer_trend)

	sfvp_all_climo = cal_sfvp(u_all_climo, v_all_climo)

	;=======================================================;	
	; calculate divergence
	;=======================================================;	
	function divergence(u, v)
	local dv
	begin
		dv = uv2dvF_Wrap(u, v)
		dv = (/dv*10^5/)
	return(dv)
	end
	
	dv_aer_trend = uv2dvF_Wrap(u850_aer_trend, v850_aer_trend)
	dv_eff_trend = uv2dvF_Wrap(u850_eff_trend, v850_eff_trend)
	dv_wff_trend = uv2dvF_Wrap(u850_wff_trend, v850_wff_trend)

	dv_all_climo = uv2dvF_Wrap(u850_all_climo, v850_all_climo)

	;=======================================================;	
	; save to netcdf file for plot
	;=======================================================;	
	data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_convergence_map/"
	fname = "sfvp-trend_"+ startyr + "-" + stopyr + "_" + sigcheck + ".nc"
	
	print("saving data to: "+ data_path + fname)
	
	f = addfile(data_path + fname, "c")
	f@author = "Chenrui"

	f->sfvp_all_climo = sfvp_all_climo
	f->sfvp_aer_trend = sfvp_aer_trend
	f->sfvp_eff_trend = sfvp_eff_trend
	f->sfvp_wff_trend = sfvp_wff_trend
								  
	f->u_all_climo  = u_all_climo
	f->u_aer_trend  = u_aer_trend 
	f->u_eff_trend  = u_eff_trend 
	f->u_wff_trend  = u_wff_trend 
								  
	f->v_all_climo  = v_all_climo
	f->v_aer_trend  = v_aer_trend 
	f->v_eff_trend  = v_eff_trend 
	f->v_wff_trend  = v_wff_trend 

	f->z200_all_climo  = z200_all_climo
	f->z200_aer_trend  = z200_aer_trend 
	f->z200_eff_trend  = z200_eff_trend 
	f->z200_wff_trend  = z200_wff_trend 
								  
	f->z500_all_climo  = z500_all_climo
	f->z500_aer_trend  = z500_aer_trend 
	f->z500_eff_trend  = z500_eff_trend 
	f->z500_wff_trend  = z500_wff_trend 
								  
	f->psl_all_climo  = psl_all_climo
	f->psl_aer_trend  = psl_aer_trend 
	f->psl_eff_trend  = psl_eff_trend 
	f->psl_wff_trend  = psl_wff_trend 
	
	f->u850_all_climo  = u850_all_climo
	f->u850_aer_trend  = u850_aer_trend 
	f->u850_eff_trend  = u850_eff_trend 
	f->u850_wff_trend  = u850_wff_trend 
	
	f->v850_all_climo  = v850_all_climo
	f->v850_aer_trend  = v850_aer_trend 
	f->v850_eff_trend  = v850_eff_trend 
	f->v850_wff_trend  = v850_wff_trend 

	f->dv850_all_climo = dv_all_climo
	f->dv850_aer_trend = dv_aer_trend
	f->dv850_eff_trend = dv_eff_trend
	f->dv850_wff_trend = dv_wff_trend

	f->fl_all_climo = fl_all_climo
	f->fl_aer_trend = fl_aer_trend
	f->fl_eff_trend = fl_eff_trend
	f->fl_wff_trend = fl_wff_trend
end

