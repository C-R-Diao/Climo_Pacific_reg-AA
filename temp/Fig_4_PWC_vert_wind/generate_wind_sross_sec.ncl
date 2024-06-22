;====================e===================================;
; author: Chenrui Diao
; 2022-01-30
;=======================================================;	
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/func_lib/read_all-xaer-xbmb_data_all_ens.ncl"

undef("read_v_sross_sec")
function read_v_sross_sec(varname, startyr, stopyr, lat_range)
local result
begin

	;==========================;	
	; read data from files
	;==========================;	
	result = read_xaer_bmb_response(varname, startyr, stopyr)
	result1 = read_reg_xaer_response(varname, startyr, stopyr)
	v_a_avg = result[0] ; all-forcing
	v_x_avg = result[1] ; xaer
	v_ex_avg = result1[0] ; AsiaFF
	v_wx_avg = result1[1] ; WestFF
	
	v_a_avg := v_a_avg(:, :, {lat_range(0): lat_range(1)}, :)
	v_x_avg := v_x_avg(:, :, {lat_range(0): lat_range(1)}, :)
	v_ex_avg := v_ex_avg(:, :, {lat_range(0): lat_range(1)}, :)
	v_wx_avg := v_wx_avg(:, :, {lat_range(0): lat_range(1)}, :)
	printVarSummary(v_a_avg)

	delete(result)
	delete(result1)

	;==========================;	
	; avg via latitude
	;==========================;	
	v_a_avg := dim_avg_n_Wrap(v_a_avg, 2)
	v_x_avg := dim_avg_n_Wrap(v_x_avg, 2)
	v_ex_avg := dim_avg_n_Wrap(v_ex_avg, 2)
	v_wx_avg := dim_avg_n_Wrap(v_wx_avg, 2)

	;==========================;	
	; calculate climo
	;==========================;	
	v_a_climo = dim_avg_n_Wrap(v_a_avg, 0)
	v_x_climo = dim_avg_n_Wrap(v_x_avg, 0)
	v_ex_climo = dim_avg_n_Wrap(v_ex_avg, 0)
	v_wx_climo = dim_avg_n_Wrap(v_wx_avg, 0)

	v_aer_climo = v_a_climo
	v_aer_climo = (/v_a_climo - v_x_climo/)

	v_eff_climo = v_a_climo
	v_eff_climo = (/v_a_climo - v_ex_climo/)

	v_wff_climo = v_a_climo
	v_wff_climo = (/v_a_climo - v_wx_climo/)

	;==========================;	
	; calculate response
	;==========================;	
	v_aer_avg = v_x_avg
	v_aer_avg = (/ v_a_avg - v_x_avg/)
	v_aer_avg@long_name = v_x_avg@long_name + " (all-forcing - xaer)"

	v_eff_avg := v_ex_avg  ; eh ff
	v_wff_avg := v_wx_avg  ; wh ff

	printVarSummary(v_eff_avg)
	v_eff_avg = (/ v_a_avg - v_ex_avg/)
	v_eff_avg@long_name = v_ex_avg@long_name + " (all-forcing - xAsiaFF)"

	v_wff_avg = (/ v_a_avg - v_wx_avg/)
	v_wff_avg@long_name = v_wx_avg@long_name + " (all-forcing - xWestFF)"

	dim_v = dimsizes(v_a_avg)

	;========================================================;	
	; decadal trend 
	;========================================================;	
	print("calculate decadal trends....")	

	undef("cal_decadal_trend")
	function cal_decadal_trend(v, startyr, stopyr)
	local v, temp, v_trend, stopyr, startyr
	begin

		v = runave_n_Wrap(v, 5, 1, 0)

		if(dimsizes(dimsizes(v)).eq.3)then
			temp := regCoef_n(v&year, v, 0, 0)
			v_trend = temp *10.0 ; month to decade
			copy_VarMeta(v(0,:,:), v_trend)
			v_trend@nptxy = temp@nptxy
			v_trend@tval = temp@tval
			delete(temp)
		else if(dimsizes(dimsizes(v)).eq.4)then
			temp := regCoef_n(v&year, v, 0, 1)
			v_trend = temp *10.0 ; month to decade
			delete(temp)
			copy_VarMeta(v(:,0,:,:), v_trend)
		end if
		end if
		v_trend@units = v@units + "/decade"

		v_trend@long_name = v@long_name+ "_Linear-Trend_" + startyr + "-" + stopyr
	return(v_trend)
	end 

	v_aer_avg_trend = cal_decadal_trend(v_aer_avg, startyr, stopyr)
	v_eff_avg_trend = cal_decadal_trend(v_eff_avg, startyr, stopyr)
	v_wff_avg_trend = cal_decadal_trend(v_wff_avg, startyr, stopyr)

	;==========================;	
	; remove tval and nptxy from attribute to save space
	;==========================;	
	function remove_tval_attr(x)
	local t
	begin;		t = x 
		t = x 
		delete(t@nptxy)
		delete(t@tval)
	return(t)
	end 
	
	aer_trend = remove_tval_attr(v_aer_avg_trend)
	eff_trend = remove_tval_attr(v_eff_avg_trend)
	wff_trend = remove_tval_attr(v_wff_avg_trend)

return [/aer_trend, eff_trend, wff_trend, \
		 v_a_climo, v_aer_climo, v_eff_climo, v_wff_climo/]
end


;=======================================================;	
; generate nc data
;=======================================================;

procedure generate_wind_sross_sec(startyr, stopyr, lat_range)
begin
	varname = (/"U", "OMEGA"/)

	r_u = read_v_sross_sec(varname(0), startyr, stopyr, lat_range)
    u_aer_trend = r_u[0]
    u_eff_trend = r_u[1]
    u_wff_trend = r_u[2]
    u_all_climo = r_u[3]
	u_aer_climo = r_u[4]
	u_eff_climo = r_u[5]
	u_wff_climo = r_u[6]
    delete(r_u)	

	r_w = read_v_sross_sec(varname(1), startyr, stopyr, lat_range)
    w_aer_trend = r_w[0]
    w_eff_trend = r_w[1]
    w_wff_trend = r_w[2]
    w_all_climo = r_w[3]
	w_aer_climo = r_w[4]
	w_eff_climo = r_w[5]
	w_wff_climo = r_w[6]
    delete(r_w)	

	;==========================;	
	; save to file
	;==========================;	
	data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_PWC_vert_wind/"
    fname = "Omega_U_cross-sect_"+ startyr + "-" + stopyr + ".nc"

    print("saving data to: "+ data_path + fname)

    f = addfile(data_path + fname, "c")
    f@author = "Chehnrui"
    f@date = systemfunc("echo $now")
	
	f->latitude_range = lat_range

    f->u_all_climo  = u_all_climo
    f->u_aer_climo  = u_aer_climo
	f->u_eff_climo  = u_eff_climo
	f->u_wff_climo  = u_wff_climo
	f->u_aer_trend  = u_aer_trend
    f->u_eff_trend  = u_eff_trend
    f->u_wff_trend  = u_wff_trend


    f->w_all_climo  = w_all_climo
    f->w_aer_climo  = w_aer_climo
	f->w_eff_climo  = w_eff_climo
	f->w_wff_climo  = w_wff_climo
    f->w_aer_trend  = w_aer_trend
    f->w_eff_trend  = w_eff_trend
    f->w_wff_trend  = w_wff_trend

end

