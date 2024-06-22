;================================;
;= PDO_cal                      =;
;follow Xu and Hu 2018          =;
;================================;

undef("PDO_cal")
function PDO_cal(ssta, domain, smooth, detrend_method)
; ssta = (time, lat, lon) 
; domain = "pdo" or "ipo"
; detrend_method = "local" or "global" or "False"

local ssta, a, eof
begin

	if(domain .eq. "pdo")
        latMin  = 20
        latMax  = 70
        lonMin  = 110
        lonMax  = 260
    else if(domain .eq. "ipo")
        latMin  = -60
        latMax  = 70
        lonMin  = 110
        lonMax  = 290
	
	end if
	end if

    ;=======================================================;   
    ; mask land
    ;=======================================================;   
;    a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
;    lsdata = a->LSMASK
;	lsm  = landsea_mask(lsdata,ssta&lat,ssta&lon)
;    typ=0
;    ssta = mask(ssta,lsm.eq.typ,True) ; mask to ocean temp

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
    		ssta_smooth_detrend(ff,:,:)   = (/ssta_smooth_detrend(ff,:,:)-wgt_areaave(ssta_smooth_detrend(ff,{latMin:latMax},:), coswgt({latMin:latMax}),1.0,0) /)
		end do

	end if
	end if

	;=======================================================;   
    ; EOF
    ;=======================================================;

    ;===== masking pacific =====;

    ssta_eof = ssta_smooth_detrend({lat|latMin:latMax}, {lon|lonMin:lonMax}, year|:)

	;==========================;	
	; create avraible for eof
	;==========================;	
    neof =3 ;only pick 1st eof TS
	dim = dimsizes(ssta_smooth)
	nyrs = dim(0)
	evn = ispan(1, neof, 1)
	
	;pc time series
	eof_ts = new((/neof, nyrs/), "float")
	eof_ts!0="evn"
	eof_ts!1="year"
	eof_ts&evn = evn
	eof_ts&year = ssta_smooth&year
	
	;Variance explained
	eof_pcvar = new((/neof/),"float")
	eof_pcvar!0="evn"
	eof_pcvar&evn = evn

	;ipo pattern 
	ipo4d = new((/neof, dim(1), dim(2)/), "float")
	ipo4d!0="evn"
	ipo4d!1="lat"
	ipo4d!2="lon"
	ipo4d&evn = evn
	ipo4d&lat = ssta_smooth_detrend&lat
	ipo4d&lon = ssta_smooth_detrend&lon
	
	;eof pattern
	eof4d = ipo4d(:, {latMin:latMax}, {lonMin:lonMax})

    ;==========================;    
    ; eof
    ;==========================;    
    optEOF = True

    ; -- two ways to do EOF --
    ; 1 = correlation EOF ; this is what we used in this paper
    ;  0 = covariance EOF
    optEOF@jopt = 1 ; 

	y = eofunc_Wrap(ssta_eof, neof, optEOF)
	eof4d = y
	eof_pcvar = y@pcvar

	;===== normalize =====;
	eof_ts = eofunc_ts_Wrap(ssta_eof, y, False)
	eof_ts = dim_standardize(eof_ts,0)

	;===== regressed sst as PDO =====;
	ipo4d = escorc(eof_ts, ssta_smooth_detrend(lat|:, lon|:, year|:))
	
	;===== make sure PDO pattern are positive =====;
	do j = 0, neof-1, 1
		if (avg(ipo4d(j, {30:40}, {135:180})) .gt. 0)
			ipo4d(j, :, :) = (/-1.0 * ipo4d(j, :, :)/)
			eof4d(j, :, :) = (/-1.0 * eof4d(j, :, :)/)
			eof_ts(j, :) = (/-1.0 * eof_ts(j, :)/)
		end if
	end do
	eof4d!1 = "lat1"
	eof4d!2 = "lon1"

	lat = ssta_smooth_detrend&lat
	lon = ssta_smooth_detrend&lon
	lat!0 = "lat"
	lon!0 = "lon"
	lat&lat = lat
	lon&lon = lon
	eof4d&lat1 = lat({latMin:latMax})
	eof4d&lon1 = lon({lonMin:lonMax})

    return[/eof_ts, ipo4d, eof4d, eof_pcvar/]

end

