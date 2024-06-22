;================================;
; ETPI_cal                      =;
; hemispheric asymmetry in ETP  =;
;================================;

undef("ETPI_cal")
function ETPI_cal(ssta, detrend_method)
; ssta = (time, lat, lon) 
; detrend_method = "local" or "global" or "False"

local TS1, TS2, ETPI, wgt, t_detrend
begin

    ;=======================================================;   
    ; smooth using low pass filtering
    ;=======================================================;
    wgts_decade = (/ 1,6,19,42,71,96,106,96,71,42,19,6,1 /)*1.0 ; to make it float
    wgts_decade    = wgts_decade/sum(wgts_decade)
    kopt=1 ; kopt=1 reflective end pts  ;or;  kopt=0 missing end pts
	ssta_smooth = wgt_runave_n_Wrap(ssta, wgts_decade, kopt,0)

    ;=======================================================;   
    ; detrending
    ;=======================================================;   
	if(detrend_method .eq. "local")	

		ssta_smooth_detrend = dtrend_msg_n(ssta_smooth&year, ssta_smooth, True, False, 0)
		copy_VarMeta(ssta_smooth, ssta_smooth_detrend)
	
	else if(detrend_method .eq. "global")

		pi      = 4.*atan(1.0)
		rad     = (pi/180.)
		coswgt  = cos(rad*ssta_smooth&lat)
		coswgt!0    = "lat"
		coswgt&lat  = ssta_smooth&lat	
	
		ssta_smooth_detrend = ssta_smooth
		do ff = 0,dimsizes(ssta_smooth&year) - 1
    		ssta_smooth_detrend(ff,:,:)   = (/ssta_smooth_detrend(ff,:,:)-wgt_areaave(ssta_smooth_detrend(ff,{-60:60},:), coswgt({-60:60}),1.0,0) /)
		end do

	end if
	end if

	;=======================================================;	
	; select regions
	;=======================================================;	
	TS1 = ssta_smooth_detrend(:,{0:20},{240:255})
    TS2 = ssta_smooth_detrend(:,{-20:0},{240:255})   ; region 2
    
	;===== avg over region =====;
    wgt1    = cos((TS1&lat)*2.*3.1415/360.)
    wgt2    = cos((TS2&lat)*2.*3.1415/360.)
    
	SSTA1   = wgt_areaave_Wrap(TS1, wgt1, 1.0, 1)
    SSTA2   = wgt_areaave_Wrap(TS2, wgt2, 1.0, 1)

    ;====== anomaly ======;
    dim = dimsizes(SSTA1)
    norm_1 = avg(SSTA1)
    norm_2 = avg(SSTA2)

    do i = 0, dim - 1, 1
        SSTA1(i) = (/SSTA1(i) - norm_1/)
        SSTA2(i) = (/SSTA2(i) - norm_2/)
    end do

    ETPI = SSTA1 - SSTA2
    copy_VarCoords(SSTA1,ETPI)

return ETPI
end

