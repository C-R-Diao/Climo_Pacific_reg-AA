;====================e===================================;
; author: Chenrui Diao
; 2022-01-26
;=======================================================;	
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/func_lib/read_all-xaer-xbmb_data_all_ens.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/func_lib/mask_icechange_region.ncl"

undef("read_2d_data")
function read_2d_data(varname, startyr, stopyr, LAND_MASK, sigcheck, sig)
local result
begin

	;==========================;	
	; read data from files
	;==========================;	
	if(.not.ismissing(str_match(varname, "-"))) then
		tmp = str_split(varname, "-")
		tmp_name = tmp(0)
		lev = toint(tmp(1))
		print("slice " + tmp_name + " at " + lev + " hPa")

		result = read_xaer_bmb_response(tmp_name, startyr, stopyr)
		result1 = read_reg_xaer_response(tmp_name, startyr, stopyr)
		v_a_avg = result[0] ; all-forcing
		v_x_avg = result[1] ; xaer
		v_ex_avg = result1[0] ; AsiaFF
		v_wx_avg = result1[1] ; WestFF
		
		v_a_avg := v_a_avg(:, {lev}, :, :)
		v_x_avg := v_x_avg(:, {lev}, :, :)
		v_ex_avg := v_ex_avg(:, {lev}, :, :)
		v_wx_avg := v_wx_avg(:, {lev}, :, :)
		printVarSummary(v_a_avg)

	else

		print(varname)
		result = read_xaer_bmb_response(varname, startyr, stopyr)
		result1 = read_reg_xaer_response(varname, startyr, stopyr)

		v_a_avg = result[0] ; all-forcing
		v_x_avg = result[1] ; xaer
		v_ex_avg = result1[0] ; AsiaFF
		v_wx_avg = result1[1] ; WestFF

	end if
	delete(result)
	delete(result1)

	;==========================;	
	; change units
	;==========================;	
	;===== change burden from kg/m2 to kg/km2 =====;
	if(.not.ismissing(str_match((/"BURDENSO4", "BURDENBC", "BURDENPOM", "BURDENSOA"/), varname)))

		v_a_avg = (/v_a_avg*10^6/)
		v_a_avg@units = "kg/km2"

		v_x_avg = (/v_x_avg*10^6/)
		v_x_avg@units = "kg/km2"
		
	end if
	;===== CDNUMC change from /m2 to 10^10/m2
	if(varname.eq."CDNUMC")

		v_a_avg = (/v_a_avg/10^10/)
		v_a_avg@units = "10^10/m2"

		v_x_avg = (/v_x_avg/10^10/)
		v_x_avg@units = "10^10/m2"

	end if

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
		
		;===== smooth =====;
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

	v_a_avg_trend = cal_decadal_trend(v_a_avg, startyr, stopyr)
	v_x_avg_trend = cal_decadal_trend(v_x_avg, startyr, stopyr)
	v_ex_avg_trend = cal_decadal_trend(v_ex_avg, startyr, stopyr)
	v_wx_avg_trend = cal_decadal_trend(v_wx_avg, startyr, stopyr)


	;=======================================================;	
	; climatology
	;=======================================================;	

	print("calculate climatology...")

	v_aer_avg_climo = dim_avg_n_Wrap(v_aer_avg, 0)
	v_eff_avg_climo = dim_avg_n_Wrap(v_eff_avg, 0)
	v_wff_avg_climo = dim_avg_n_Wrap(v_wff_avg, 0)

	v_a_avg_climo = dim_avg_n_Wrap(v_a_avg, 0)
	v_x_avg_climo = dim_avg_n_Wrap(v_x_avg, 0)
	v_ex_avg_climo = dim_avg_n_Wrap(v_ex_avg, 0)
	v_wx_avg_climo = dim_avg_n_Wrap(v_wx_avg, 0)

	;========================================================;	
	; temperature mask land
	;========================================================;	
	;if(LAND_MASK.eq.1 .and. (varname .eq. "TS" .or. varname .eq. "PSL"))then
	if(LAND_MASK.eq.1)then
		
		print("masking land..")

		a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
		lsdata = a->LSMASK
		lsm  = landsea_mask(lsdata,v_aer_avg_trend&lat, v_aer_avg_trend&lon)
		typ=0   ;0 for ocean & 1 for land
		
		v_aer_avg_trend = mask(v_aer_avg_trend, lsm .eq. typ, True)
		v_eff_avg_trend = mask(v_eff_avg_trend, lsm .eq. typ, True)
		v_wff_avg_trend = mask(v_wff_avg_trend, lsm .eq. typ, True)

		v_a_avg_trend = mask(v_a_avg_trend, lsm .eq. typ, True)
		v_x_avg_trend = mask(v_x_avg_trend, lsm .eq. typ, True)
		v_ex_avg_trend = mask(v_ex_avg_trend, lsm .eq. typ, True)
		v_wx_avg_trend = mask(v_wx_avg_trend, lsm .eq. typ, True)
		
	end if

	;=======================================================;	
	; radiation mask ice fraction change region
	;=======================================================;	
	if(varname@mask_ice .eq. True)
		print("masking based on ice change...")
		v_aer_avg_trend = mask_ice(v_aer_avg_trend, "FF", startyr, stopyr)
		v_eff_avg_trend = mask_ice(v_eff_avg_trend, "EFF", startyr, stopyr)
		v_wff_avg_trend = mask_ice(v_wff_avg_trend, "WFF", startyr, stopyr)
	end if

	;=======================================================;	
	; sig check
	;=======================================================;	
	if(sigcheck .eq. 1)
		print("sig check")

		undef("cal_sig")
		function cal_sig(v, sig)
		local dim, df, tval, b, prob, prob2d
		begin
				dim = dimsizes(v)
				df      = v@nptxy-2   ; degrees of freedom
				tval    = v@tval      ; t-statistic
				b       = tval    ; b must be same size as tval (and df)
				b       = 0.5
				prob    = 1-betainc(df/(df+tval^2),df/2.0,b)
				prob2dT =onedtond(prob,(/dim(0), dim(1)/)  )
		
				;===== masking =====;
				rc_sig = v
				;rc_sig = 1.0
				rc_sig = mask(rc_sig,prob2dT.lt.sig, False)
		return(rc_sig)
		end 

		v_aer_avg_prob = cal_sig(v_aer_avg_trend, sig)
		v_eff_avg_prob = cal_sig(v_eff_avg_trend, sig)
		v_wff_avg_prob = cal_sig(v_wff_avg_trend, sig)
		
		v_a_avg_prob = cal_sig(v_a_avg_trend, sig)
		v_x_avg_prob = cal_sig(v_x_avg_trend, sig)
		v_ex_avg_prob = cal_sig(v_ex_avg_trend, sig)
		v_wx_avg_prob = cal_sig(v_wx_avg_trend, sig)

	end if

	;==========================;	
	; remove tval and nptxy from attribute to save space
	;==========================;	
	function remove_tval_attr(x)
	local t
	begin
		t = x 
		delete(t@nptxy)
		delete(t@tval)
	return(t)
	end 
	
	aer_trend = remove_tval_attr(v_aer_avg_trend)
	eff_trend = remove_tval_attr(v_eff_avg_trend)
	wff_trend = remove_tval_attr(v_wff_avg_trend)

return [/aer_trend, eff_trend, wff_trend, \
		 v_a_avg_climo, v_aer_avg_climo, v_eff_avg_climo, v_wff_avg_climo/]
		 ;v_aer_avg_climo, v_eff_avg_climo, v_wff_avg_climo/]
end 
