;====================e===================================;
; aim: plot global map for CESM outpout AOD-AA (corrected)
; author: Chenrui Diao
; 2020-01-17
;========================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_SST-and-850wind_trend_map/read_2d_data_with_bb.ncl"


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
	psl_bmb_trend = r_ts[7]
	delete(r_ts)

	r_ts = read_2d_data(varname(1), startyr, stopyr, LAND_MASK, sigcheck, sig)
	u_bmb_trend = r_ts[7]
	u_bmb_climo = r_ts[8]
	delete(r_ts)

	r_ts = read_2d_data(varname(2), startyr, stopyr, LAND_MASK, sigcheck, sig)
	v_bmb_trend = r_ts[7]
	v_bmb_climo = r_ts[8]
	delete(r_ts)
	
	r_ts = read_2d_data(varname(3), startyr, stopyr, LAND_MASK, sigcheck, sig)
	z200_bmb_trend = r_ts[7]
	z200_bmb_climo = r_ts[8]
	delete(r_ts)
	
	r_ts = read_2d_data(varname(4), startyr, stopyr, LAND_MASK, sigcheck, sig)
	z500_bmb_trend = r_ts[7]
	z500_bmb_climo = r_ts[8]
	delete(r_ts)

	r_ts = read_2d_data(varname(5), startyr, stopyr, LAND_MASK, sigcheck, sig)
	u850_bmb_trend = r_ts[7]
	u850_bmb_climo = r_ts[8]
	delete(r_ts)

	r_ts = read_2d_data(varname(6), startyr, stopyr, LAND_MASK, sigcheck, sig)
	v850_bmb_trend = r_ts[7]
	v850_bmb_climo = r_ts[8]
	delete(r_ts)
	
	r_ts = read_2d_data(varname(7), startyr, stopyr, LAND_MASK, sigcheck, sig)
	fl_bmb_trend = r_ts[7]
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
	
	sfvp_bmb_trend = cal_sfvp(u_bmb_trend, v_bmb_trend)

	sfvp_bmb_climo = cal_sfvp(u_bmb_climo, v_bmb_climo)

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
	
	dv_bmb_trend = uv2dvF_Wrap(u850_bmb_trend, v850_bmb_trend)

	;=======================================================;	
	; save to netcdf file for plot
	;=======================================================;	
	data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_convergence_map/for_bmb/"
	fname = "sfvp-trend_"+ startyr + "-" + stopyr + "_" + sigcheck + ".nc"
	
	print("saving data to: "+ data_path + fname)
	
	f = addfile(data_path + fname, "c")
	f@author = "Chenrui"

	f->sfvp_bmb_climo = sfvp_bmb_climo
	f->sfvp_bmb_trend = sfvp_bmb_trend
								  
	f->u_bmb_trend  = u_bmb_trend 
	f->v_bmb_trend  = v_bmb_trend
	f->z200_bmb_trend  = z200_bmb_trend 
	f->z500_bmb_trend  = z500_bmb_trend 
	f->psl_bmb_trend  = psl_bmb_trend 
	f->u850_bmb_trend  = u850_bmb_trend 
	f->v850_bmb_trend  = v850_bmb_trend 
	f->dv850_bmb_trend = dv_bmb_trend

	f->fl_bmb_trend = fl_bmb_trend
end

