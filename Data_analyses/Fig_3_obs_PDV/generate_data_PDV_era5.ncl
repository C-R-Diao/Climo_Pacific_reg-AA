;====================e===================================;
; author: Chenrui Diao
; 2024-03-15
;========================================================;
load "./PDO_cal.ncl"
load "./TPI_cal.ncl"
load "./ETPI_cal.ncl"

undef("generate_pdv_era5")
procedure generate_pdv_era5(startyr, stopyr)
begin
	;=======================================================;	
	; read and process data
	;=======================================================;	
	fpath = "/glade/work/dchenrui/ERA5/"	
	fname = "ERA_5.sst.ann.1980-2022.nc"
	
	f = addfile(fpath + fname, "r")
	sst = f->sst({startyr:stopyr}, :, :)

	domain = "ipo"
	smooth = 1
	detrend_method = "global"
	result = PDO_cal(sst, domain, smooth, detrend_method)

	eof_ts 		= result[0]
	ipo	   		= result[1]
	eof    		= result[2]
	eof_pcvar 	= result[3]
	
	ETPI = ETPI_cal(sst, detrend_method)
	TPI = TPI_cal(sst, detrend_method)


	;=======================================================;	
	; save to netcdf file for plot
	;=======================================================;	
	data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/data_for_plots/"
	fname = "IPO_ERA5_"+ startyr + "-" + stopyr + ".nc"
	
	print("saving data to: "+ data_path + fname)
	
	f = addfile(data_path + fname, "c")
	f@author = "Chehnrui"
	f@date = systemfunc("echo $now")

	f->eof_ts 		= eof_ts
	f->ipo			= ipo
	f->eof			= eof
	f->eof_pcvar	= eof_pcvar
	
	f->tpi			= TPI
	f->etpi			= ETPI

end


