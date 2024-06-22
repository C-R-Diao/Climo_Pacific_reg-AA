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
	if(varname .eq. "AOD-AA") then	

		print(varname)
        result = read_xaer_bmb_response(varname, startyr, stopyr)
        result1 = read_reg_xaer_response(varname, startyr, stopyr)

        v_a_avg = result[0] ; all-forcing
        v_x_avg = result[1] ; xaer
        v_ex_avg = result1[0] ; AsiaFF
        v_wx_avg = result1[1] ; WestFF

        v_b_avg = read_bmb_response(varname, startyr, stopyr)

	else if(.not.ismissing(str_match(varname, "-"))) then
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

		v_b_avg = read_bmb_response(tmp_name, startyr, stopyr)

		v_a_avg := v_a_avg(:, {lev}, :, :)
		v_x_avg := v_x_avg(:, {lev}, :, :)
		v_b_avg := v_b_avg(:, {lev}, :, :)
		v_ex_avg := v_ex_avg(:, {lev}, :, :)
		v_wx_avg := v_wx_avg(:, {lev}, :, :)
		printVarSummary(v_a_avg)

	else if(varname .eq. "PRECT") then

		function precp_total(precc, precl)
		local temp
		begin
				temp = precc
				temp = (/(temp + precl) * 10.^4 * 86400. /)

				temp@long_name = "total precipitation rate"
				temp@units = "mm/day"
		return(temp)
		end

		r1 = read_xaer_bmb_response("PRECC", startyr, stopyr)
		r2 = read_xaer_bmb_response("PRECL", startyr, stopyr)
		v_a_avg = precp_total(r1[0], r2[0])
		v_x_avg = precp_total(r1[1], r2[1])

		r3 = read_reg_xaer_response("PRECC", startyr, stopyr)
		r4 = read_reg_xaer_response("PRECL", startyr, stopyr)

		v_ex_avg = precp_total(r3[0], r4[0])
		v_wx_avg = precp_total(r3[1], r4[1])

		r5 = read_bmb_response("PRECC", startyr, stopyr)
		r6 = read_bmb_response("PRECL", startyr, stopyr)
		v_b_avg = precp_total(r5, r6)

		delete([/r1,r2, r3, r4, r5, r6/])

	else

		print(varname)
		result = read_xaer_bmb_response(varname, startyr, stopyr)
		result1 = read_reg_xaer_response(varname, startyr, stopyr)

		v_a_avg = result[0] ; all-forcing
		v_x_avg = result[1] ; xaer
		v_ex_avg = result1[0] ; AsiaFF
		v_wx_avg = result1[1] ; WestFF

		v_b_avg = read_bmb_response(varname, startyr, stopyr)

	end if
	end if
	end if
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

	v_bmb_avg = v_b_avg
	v_bmb_avg = (/ v_a_avg - v_b_avg/)
	v_bmb_avg@long_name = v_b_avg@long_name + " (all-forcing - xbmb)"

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
	v_bmb_avg_trend = cal_decadal_trend(v_bmb_avg, startyr, stopyr)
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
	v_bmb_avg_climo = dim_avg_n_Wrap(v_bmb_avg, 0)
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
		v_bmb_avg_trend = mask(v_bmb_avg_trend, lsm .eq. typ, True)
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
		v_bmb_avg_trend = mask_ice(v_bmb_avg_trend, "BB", startyr, stopyr)
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
		v_bmb_avg_prob = cal_sig(v_bmb_avg_trend, sig)
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
	bmb_trend = remove_tval_attr(v_bmb_avg_trend)
	eff_trend = remove_tval_attr(v_eff_avg_trend)
	wff_trend = remove_tval_attr(v_wff_avg_trend)

return [/aer_trend, eff_trend, wff_trend, \
		 v_a_avg_climo, v_aer_avg_climo, v_eff_avg_climo, v_wff_avg_climo, bmb_trend, v_bmb_avg_climo/]
		 ;v_aer_avg_climo, v_eff_avg_climo, v_wff_avg_climo/]
end 
