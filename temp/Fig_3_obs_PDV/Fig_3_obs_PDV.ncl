load "/glade/u/home/dchenrui/ncl/2019_21C_Aero_PDO/func_lib/2d_global_map_resource.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/func_lib/PDO_cal.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/Fig_4_PWC_vert_wind/generate_data_PRECT.ncl"
load "/glade/u/home/dchenrui/ncl/2019_21C_Aero_PDO/func_lib/2d_global_map_resource.ncl"
load "./generate_data_PDV_era5.ncl"
load "generate_data_PDV_model.ncl"
;=======================================================;	
startyr = 1981
stopyr = 2020

rewrite_file = 0

plotpath = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/figs/"
plotname = "Fig_3_PDV_" + startyr + "-" + stopyr

;=======================================================;	
; read data era5
;=======================================================;	
data_path = "../data_for_plots/"
fname = "IPO_ERA5_"+ startyr + "-" + stopyr + ".nc"

if (.not.fileexists(data_path + fname) .or. rewrite_file .eq. 1) then
    if(rewrite_file .eq. 1)
        print("rewriting data")
        system("rm -f " + data_path + fname)
    else
        print("generating data")
    end if

    generate_pdv_era5(startyr, stopyr)

else
    print("load data from nc file directly")
end if

f = addfile(data_path + fname, "r")

eof_ts_era5		= f->eof_ts       
ipo_era5		= f->ipo         
eof_era5		= f->eof        
eof_pcvar_era5	= f->eof_pcvar 

tpi_era5 = f->tpi
etpi_era5 = f->etpi

;=======================================================;	
; read data model
;=======================================================;	
data_path = "../data_for_plots/"
fname = "IPO_model_"+ startyr + "-" + stopyr + ".nc"

if (.not.fileexists(data_path + fname) .or. rewrite_file .eq. 1) then
    if(rewrite_file .eq. 1)
        print("rewriting data")
        system("rm -f " + data_path + fname)
    else
        print("generating data")
    end if

    generate_pdv_model(startyr, stopyr)

else
    print("load data from nc file directly")
end if

f = addfile(data_path + fname, "r")

eof_ts_aer		= f->eof_ts_aer
ipo_aer			= f->ipo_aer  
eof_aer			= f->eof_aer    
eof_pcvar_aer	= f->eof_pcvar_aer

eof_ts_eff		= f->eof_ts_eff
ipo_eff			= f->ipo_eff
eof_eff			= f->eof_eff    
eof_pcvar_eff	= f->eof_pcvar_eff

eof_ts_wff		= f->eof_ts_wff
ipo_wff			= f->ipo_wff
eof_wff			= f->eof_wff    
eof_pcvar_wff	= f->eof_pcvar_wff

eof_ts_bmb		= f->eof_ts_bmb
ipo_bmb			= f->ipo_bmb  
eof_bmb			= f->eof_bmb
eof_pcvar_bmb	= f->eof_pcvar_bmb

tpi_aer = f->tpi_aer
tpi_eff = f->tpi_eff
tpi_wff = f->tpi_wff
tpi_bmb = f->tpi_bmb

etpi_aer = f->etpi_aer
etpi_eff = f->etpi_eff
etpi_wff = f->etpi_wff
etpi_bmb = f->etpi_bmb

;=======================================================;	
;plot res
;=======================================================;	
;< re loaded from file >;

;==========================;	
; re for map contour
;==========================;	
re@mpMinLatF = -60
re@mpMaxLatF = 60
re@mpMinLonF = 110
re@mpMaxLonF = 290

re@gsnAddCyclic = False ;not global map

re@cnLevelSelectionMode = "ExplicitLevels"
re@cnLevels    = fspan(-0.018, 0.018, 19)
re@lbLabelBarOn   = False
re@cnSmoothingOn = True

;==========================;	
; re_l for line plots
;==========================;	
re_1 = True
re_1@gsnDraw  = False                          ; don't draw
re_1@gsnFrame = False

re_1@vpWidthF = 0.359488
re_1@vpHeightF = 0.2

re_1@xyLineColors = (/"black", "blue", "black", "blue"/)
re_1@xyLineThicknesses = (/4, 4, 4, 4/)
re_1@xyDashPatterns = (/0, 0, 1, 1/)

re_1@gsnStringFontHeightF = 0.0135
re_1@gsnStringFont = "helvetica-bold"
re_1@gsnRightString = ""

re_1@trXMinF = 1980
re_1@tiXAxisString = "Year"

re_1@gsnYRefLine           = 0.0
re_1@gsnYRefLineDashPatterns = 2

;==========================;	
; resP panel
;==========================;	
resP = True
resP@gsnPanelLabelBar = True
resP@lbOrientation = "horizontal"
resP@lbBoxEndCapStyle = "TriangleBothEnds"
resP@pmLabelBarOrthogonalPosF = 0.015
resP@gsnPanelYWhiteSpacePercent = 5

resP@lbTitleOn  = True
resP@lbTitleString  = "K"
resP@lbTitleFontHeightF = 0.012
resP@lbTitlePosition = "Bottom"

resP@lbLabelFontHeightF = 0.01

;=======================================================;	
; plot
;=======================================================;	
print("plot: " + "Fig_S3_PDV_era5_model")
wks = gsn_open_wks("pdf",plotpath+"Fig_S3_PDV_era5_model")

undef("plot_pdv")
procedure plot_pdv(eof_pcvar, eof, eof_ts, tpi, etpi)
local plot
begin 
	
	plot = new(6, graphic)
	;==========================;	
	; map contour 
	;==========================;	
	;===== eof 1 =====
	re@gsnLeftString = "(a)  EOF1"
	re@gsnRightString = eof_pcvar(0)+ "%"
	
	if(eof(0,{10},{180}) .lt. 0) then
		temp = eof(0,:,:)
		temp = (/temp * -1.0/)
	else
		temp = eof(0,:,:)
	end if
	plot(0) = gsn_csm_contour_map(wks, temp, re)

	;===== eof 2 =====;
	re@gsnLeftString = "(b)  EOF2"
	re@gsnRightString = eof_pcvar(1)+ "%"

    if(eof(1,{10},{180}) .lt. 0) then
        temp = eof(1,:,:)
        temp = (/temp * -1.0/)
    else
        temp = eof(1,:,:)
    end if
	plot(1) = gsn_csm_contour_map(wks, temp, re)


	;==========================;	
	; ts plot
	;==========================;	
	re_1@gsnLeftString = "PC1"
	re_1@tiYAxisString = ""

	if(eof(0,{10},{180}) .lt. 0) then
		plot(2) = gsn_csm_xy(wks, eof_ts&year, eof_ts(0,:) * -1.0, re_1)
	else
		plot(2) = gsn_csm_xy(wks, eof_ts&year, eof_ts(0,:), re_1)
	end if

	re_1@gsnLeftString = "PC2"

	if(eof(1,{10},{180}) .lt. 0) then
		plot(3) = gsn_csm_xy(wks, eof_ts&year, eof_ts(1,:) * -1.0, re_1)
	else
		plot(3) = gsn_csm_xy(wks, eof_ts&year, eof_ts(1,:), re_1)
	end if

	;==========================;	
	; tpi and etpi
	;==========================;	
	re_1@gsnLeftString = "TPI"
	plot(4) = gsn_csm_xy(wks, tpi&year, tpi, re_1)

	re_1@gsnLeftString = "ETP asymmetry"
	plot(5) = gsn_csm_xy(wks, etpi&year, etpi, re_1)

	;==========================;	
	; panel plot
	;==========================;	
	gsn_panel(wks, plot, (/3,2/), resP)
end 

;==========================;	
plot_pdv(eof_pcvar_era5, eof_era5, eof_ts_era5, tpi_era5, etpi_era5)
plot_pdv(eof_pcvar_aer, eof_aer, eof_ts_aer, tpi_aer, etpi_aer)
plot_pdv(eof_pcvar_eff, eof_eff, eof_ts_eff, tpi_eff, etpi_eff)
plot_pdv(eof_pcvar_wff, eof_wff, eof_ts_wff, tpi_wff, etpi_wff)
plot_pdv(eof_pcvar_bmb, eof_bmb, eof_ts_bmb, tpi_bmb, etpi_bmb)


;=======================================================;
; plot Fig3
;=======================================================;
print("plot: " + plotname)
wks = gsn_open_wks("pdf",plotpath+plotname)
plot = new(6, graphic)

;=======================================================;	
; a&b: era5 eof1&2
;=======================================================;	
re@cnSmoothingOn = True
re@gsnLeftString = "(a)  ERA5: EOF1"
re@gsnRightString = eof_pcvar_era5(0)+ "%"

if(eof_era5(0,{10},{180}) .lt. 0) then
	temp = eof_era5(0,:,:)
	temp = (/temp * -1.0/)
else
	temp = eof_era5(0,:,:)
end if
plot(0) = gsn_csm_contour_map(wks, temp, re)

;===== eof 2 =====;
re@gsnLeftString = "(b)  ERA5: EOF2"
re@gsnRightString = eof_pcvar_era5(1)+ "%"

if(eof_era5(1,{10},{180}) .lt. 0) then
	temp = eof_era5(1,:,:)
	temp = (/temp * -1.0/)
else
	temp = eof_era5(1,:,:)
end if
plot(1) = gsn_csm_contour_map(wks, temp, re)

;=======================================================;	
; c: eff eof1
;=======================================================;	
re@gsnLeftString = "(c)  EastFF: EOF1"
re@gsnRightString = eof_pcvar_eff(0)+ "%"
re@cnLevels    := fspan(-0.018, 0.018, 19)

if(eof_eff(0,{10},{180}) .lt. 0) then
    temp = eof_eff(0,:,:)
    temp = (/temp * -1.0/)
else
    temp = eof_eff(0,:,:)
end if
plot(2) = gsn_csm_contour_map(wks, temp, re)

;=======================================================;	
; d: wff eof1
;=======================================================;	
re@gsnLeftString = "(d)  WestFF: EOF1"
re@gsnRightString = eof_pcvar_wff(0)+ "%"

if(eof_wff(0,{10},{180}) .lt. 0) then
    temp = eof_wff(0,:,:)
    temp = (/temp * -1.0/)
else
    temp = eof_wff(0,:,:)
end if
plot(3) = gsn_csm_contour_map(wks, temp, re)

;=======================================================;	
; e: TPI lines from era5 and eff
;=======================================================;	
re_1@gsnLeftString = "(e)  TPI"

;re_1@trYMaxF = 0.6
;re_1@trYMinF = -0.6

;plot(4) = gsn_csm_xy(wks, tpi_eff&year, (/tpi_era5({1981:2020}), tpi_eff, eof_ts_era5(0, {1981:2020}), eof_ts_eff(0,:)/), re_1)
plot(4) = gsn_csm_xy(wks, tpi_eff&year, (/eof_ts_era5(0, {1981:2020}), eof_ts_eff(0,:)/), re_1)

;===== add legend =====;
lgres                    = True
lgres@lgLineColors 		 = re_1@xyLineColors
lgres@lgLineThicknessF	 = re_1@xyLineThicknesses
lgres@lgDashIndexes      = (/0, 0/)
lgres@LineLengthPercent  = 0.1
lgres@lgLabelFontHeightF = .1
lgres@vpWidthF           = 0.1
lgres@vpHeightF          = 0.05
lgres@lgPerimOn          = False

labels = (/"ERA5","EastFF"/)
lbid = gsn_create_legend(wks,2,labels,lgres)

amres                  = True
amres@amJust           = "TopRight"
amres@amOrthogonalPosF =  -0.5   ;  0.5 is the bottom edge of the plot.
amres@amParallelPosF   =  0.47   ;  0.5 is the right edge of the plot.
annoid = gsn_add_annotation(plot(4), lbid, amres)

;=======================================================;	
; f: ETPI from era5 and wff
;=======================================================;	
re_1@gsnLeftString = "(f)  ETP Asymmetry"

re_1@trYMaxF = 0.4
re_1@trYMinF = -0.4

plot(5) = gsn_csm_xy(wks, etpi_wff&year, (/etpi_era5({1981:2020}), etpi_wff/), re_1)

labels = (/"ERA5","WestFF"/)
lbid = gsn_create_legend(wks,2,labels,lgres)
amres@amJust           = "TopLeft"
amres@amOrthogonalPosF =  -0.5   ;  0.5 is the bottom edge of the plot.
amres@amParallelPosF   =  -0.45   ;  0.5 is the right edge of the plot.
annoid = gsn_add_annotation(plot(5), lbid, amres)

;==========================;	
; panel plot
;==========================;	
resP = True
resP@gsnFrame = False

resP@gsnPanelLabelBar = True
resP@pmLabelBarHeightF = 0.05
resP@pmLabelBarOrthogonalPosF = -0.02
resP@lbBoxEndCapStyle = "TriangleBothEnds"
;resP@gsnPanelYWhiteSpacePercent = 5

resP@lbOrientation = "horizontal"
resP@lbTitleOn  = True
resP@lbTitleString  = "K"
resP@lbTitleFontHeightF = 0.012
resP@lbTitlePosition = "Bottom"
resP@lbLabelFontHeightF = 0.01

;==========================;	
resP@gsnDraw = False
pplots = gsn_panel_return(wks,plot(0:1),(/1,2/),resP)
bb     = NhlGetBB(pplots)
height = max(bb(0:1,0)) - min(bb(0:1,1))
;==========================;	
resP@gsnDraw                          = True
resP@gsnPanelTop                      = 0.95   ; leave room for title
resP@gsnPanelBottom                   = resP@gsnPanelTop - height - 0.075

;===== era5 =====;
gsn_panel(wks,plot(0:1),(/1,2/),resP)

;===== model =====;
resP@gsnPanelTop        = resP@gsnPanelBottom
resP@gsnPanelBottom     = resP@gsnPanelTop-height -0.075
gsn_panel(wks,plot(2:3),(/1,2/),resP)

frame(wks)
;===== xy plot =====;
resP1 = True
gsn_panel(wks,plot(4:5),(/1,2/),resP1)

frame(wks)

;=======================================================;
; plot FigS2
;=======================================================;


