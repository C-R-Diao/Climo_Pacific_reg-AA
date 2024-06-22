;====================e===================================;
; author: Chenrui Diao
; 2024-04-15
;========================================================;
load "./PDO_cal.ncl"
load "./TPI_cal.ncl"
load "./ETPI_cal.ncl"

load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/func_lib/read_all-xaer-xbmb_data_all_ens.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/func_lib/mask_icechange_region.ncl"
;=======================================================;	

undef("generate_pdv_model")
procedure generate_pdv_model(startyr, stopyr)
begin
	;=======================================================;	
	; read data
	;=======================================================;	
	varname = (/"TS"/)
	LAND_MASK = 1

	result = read_xaer_bmb_response(varname(0), startyr, stopyr)
	result1 = read_reg_xaer_response(varname(0), startyr, stopyr)

	v_a_avg = result[0] ; all-forcing
	v_x_avg = result[1] ; xaer
	v_ex_avg = result1[0] ; AsiaFF
	v_wx_avg = result1[1] ; WestFF

	v_b_avg = read_bmb_response(varname, startyr, stopyr)	

	;==========================;	
	; response 
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

	;==========================;	
	; mask land
	;==========================;	
	a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
    lsdata = a->LSMASK
    lsm  = landsea_mask(lsdata,v_aer_avg&lat, v_aer_avg&lon)
    typ=0   ;0 for ocean & 1 for land

	v_aer_avg = mask(v_aer_avg, lsm .eq. typ, True)
	v_eff_avg = mask(v_eff_avg, lsm .eq. typ, True)
	v_wff_avg = mask(v_wff_avg, lsm .eq. typ, True)
	v_bmb_avg = mask(v_bmb_avg, lsm .eq. typ, True)

	;=======================================================;	
	; calculate PDV
	;=======================================================;	
	domain = "ipo"
	smooth = 1
	detrend_method = "global"

	result = PDO_cal(v_aer_avg, domain, smooth, detrend_method)
	eof_ts_aer 		= result[0]
	ipo_aer	   		= result[1]
	eof_aer    		= result[2]
	eof_pcvar_aer	= result[3]
	
    result = PDO_cal(v_eff_avg, domain, smooth, detrend_method)
    eof_ts_eff      = result[0]
    ipo_eff         = result[1]
    eof_eff         = result[2]
    eof_pcvar_eff   = result[3]

    result = PDO_cal(v_wff_avg, domain, smooth, detrend_method)
    eof_ts_wff      = result[0]
    ipo_wff         = result[1]
    eof_wff         = result[2]
    eof_pcvar_wff   = result[3]

	result = PDO_cal(v_bmb_avg, domain, smooth, detrend_method)
    eof_ts_bmb      = result[0]
    ipo_bmb         = result[1]
    eof_bmb         = result[2]
    eof_pcvar_bmb   = result[3]

	;==========================;	
	; TPI
	;==========================;	
	TPI_aer = TPI_cal(v_aer_avg, detrend_method)
	TPI_eff = TPI_cal(v_eff_avg, detrend_method)
	TPI_wff = TPI_cal(v_wff_avg, detrend_method)
	TPI_bmb = TPI_cal(v_bmb_avg, detrend_method)

	;==========================;	
	; ETPI
	;==========================;	
	ETPI_aer = ETPI_cal(v_aer_avg, detrend_method)
	ETPI_eff = ETPI_cal(v_eff_avg, detrend_method)
	ETPI_wff = ETPI_cal(v_wff_avg, detrend_method)
	ETPI_bmb = ETPI_cal(v_bmb_avg, detrend_method)


	;=======================================================;	
	; save to netcdf file for plot
	;=======================================================;	
	data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/data_for_plots/"
	fname = "IPO_model_"+ startyr + "-" + stopyr + ".nc"
	
	print("saving data to: "+ data_path + fname)
	
	f = addfile(data_path + fname, "c")
	f@author = "Chehnrui"
	f@date = systemfunc("echo $now")

	f->eof_ts_aer 		= eof_ts_aer
	f->eof_ts_eff 		= eof_ts_eff
	f->eof_ts_wff 		= eof_ts_wff
	f->eof_ts_bmb 		= eof_ts_bmb
	f->ipo_aer			= ipo_aer
	f->ipo_eff			= ipo_eff
	f->ipo_wff			= ipo_wff
	f->ipo_bmb			= ipo_bmb
	f->eof_aer			= eof_aer
	f->eof_eff			= eof_eff
	f->eof_wff			= eof_wff
	f->eof_bmb			= eof_bmb
	f->eof_pcvar_aer	= eof_pcvar_aer
	f->eof_pcvar_eff	= eof_pcvar_eff
	f->eof_pcvar_wff	= eof_pcvar_wff
	f->eof_pcvar_bmb	= eof_pcvar_bmb

	f->tpi_aer	= TPI_aer
	f->tpi_eff	= TPI_eff
	f->tpi_wff	= TPI_wff
	f->tpi_bmb	= TPI_bmb

	f->etpi_aer	= ETPI_aer
	f->etpi_eff	= ETPI_eff
	f->etpi_wff	= ETPI_wff
	f->etpi_bmb	= ETPI_bmb

end


