;========================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/dchenrui/ncl/2019_21C_Aero_PDO/func_lib/2d_global_map_resource.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_SST-and-850wind_trend_map/generate_data_SST-and-850wind.ncl" 
;========================================================;	
; parameters
;========================================================;	
sigcheck    = 0 ; 1 for yes; 0 for no
sig         = 0.95

startyr = 1981	; startpoint of climo or trend
stopyr = 2020	; end point of climo or trend

LAND_MASK = 1

plotpath = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/figs/"
plotname = "Fig_2_SST-and-850wind-trend"

rewrite_file = 0; 1 if re-calculate the results

;=======================================================;	
; read and process data
;=======================================================;	
data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/data_for_plots/"
fname = "SST-n-850wind-trend_"+ startyr + "-" + stopyr + "_" + LAND_MASK + "_" + sigcheck + ".nc"

if (.not.fileexists(data_path + fname) .or. rewrite_file .eq. 1) then
	if(rewrite_file .eq. 1)
		print("rewriting data")
		system("rm -f " + data_path + fname)
	else
		print("generating data")
	end if
	
	generate_data(startyr, stopyr, LAND_MASK, sigcheck, sig)

else
	print("load data from nc file directly")
end if

f = addfile(data_path + fname, "r")

ts_aer_trend = f->ts_aer_trend
ts_eff_trend = f->ts_eff_trend
ts_wff_trend = f->ts_wff_trend
                  
u_aer_trend =  f->u_aer_trend 
u_eff_trend =  f->u_eff_trend 
u_wff_trend =  f->u_wff_trend 
                  
v_aer_trend =  f->v_aer_trend 
v_eff_trend =  f->v_eff_trend 
v_wff_trend =  f->v_wff_trend  

psl_aer_trend =  f->psl_aer_trend 
psl_eff_trend =  f->psl_eff_trend 
psl_wff_trend =  f->psl_wff_trend  

;===== climo =====;
ts_all_climo  = f->ts_all_climo  
u_all_climo   = f->u_all_climo
v_all_climo   = f->v_all_climo
psl_all_climo = f->psl_all_climo

;========================================================;	
;plot resource
;========================================================;	
wks = gsn_open_wks("pdf",plotpath+plotname)

;< re loaded >;

;===== full global map for U =====;
re@mpMinLatF = -30
re@mpMaxLatF = 70

;re@mpMaxLonF = 290
;re@mpMinLonF = 110

;re@gsnRightStringFontHeightF = 0.04
;re@gsnLeftStringFontHeightF = re@gsnRightStringFontHeightF

re2 = re ; for trend

re2@cnLevelSelectionMode = "ExplicitLevels"
;re2@cnLevels    = fspan(-0.1, 0.1, 21)
;re2@pmLabelBarOrthogonalPosF = .3
re2@cnLevels    = fspan(-0.12, 0.12, 19)
re2@lbLabelBarOn   = False

;===== wind vector control =====;
vcres                         = True             ; plot mods desired
vcres@gsnDraw  				  = False
vcres@gsnFrame                = False            ; so we can draw time stamp
vcres@vcRefMagnitudeF         = 0.1             ; define vector ref mag
vcres@vcRefLengthF            = 0.02            ; define length of vec ref
vcres@vcMinMagnitudeF 		  = 0.05
vcres@vcRefAnnoString2On	  = False			; turn off the ref vector text
vcres@vcRefAnnoString1		  = "0.1 m/s per 10a"
;vcres@vcGlyphStyle            = "CurlyVector"    ; turn on curly vectors
vcres@vcMinDistanceF          = 0.02
vcres@vcLineArrowThicknessF = 1.5

vcres@gsnLeftString = ""
vcres@gsnRightString = ""

;===== res for sig check =====;
re_sig = re2
re_sig@cnFillOn = False
re_sig@cnLinesOn = False
re_sig@cnLineLabelsOn = False
re_sig@gsnLeftString = ""

opt = True
opt@gsnShadeFillType = "pattern" ; fill with pattern but not color
opt@gsnShadeMid = 17   ; stipples
;opt@gsnShadeHigh = 2   ; stipples
;opt@gsnShadeLow = 3   ; stipples
opt@gsnShadeFillScaleF = 0.6    ;stipple density
;opt@gsnShadeFillDotSizeF = 0.001 ;stipple size

;=======================================================;	
; plot
;=======================================================;	
	
print("plot response trend...")

plot1 = new(4, graphic)

;===== procedure for plot
undef("plot_panel")
procedure plot_panel_wind(wks, plot, u, v, ts, re_t, re_w)
local p_vec
begin
	plot = gsn_csm_contour_map(wks, ts, re_t)
	p_vec = gsn_csm_vector(wks, u, v, re_w)		
	overlay(plot, p_vec)
end

;===== plot sst & 850 wind=====;
re2@gsnLeftString = "(a)  EastFF"
vcres@vcRefAnnoOn = False
plot_panel_wind(wks, plot1(0), u_eff_trend, v_eff_trend, ts_eff_trend, re2, vcres)  ; create plot

re2@gsnLeftString = "(b)  WestFF"
plot_panel_wind(wks, plot1(1), u_wff_trend, v_wff_trend, ts_wff_trend, re2, vcres)  ; create plot

re2@gsnLeftString = "(c)  FF" 
plot_panel_wind(wks, plot1(2), u_aer_trend, v_aer_trend, ts_aer_trend, re2, vcres)  ; create plot

re2@gsnLeftString = "(d)  WestFF + EastFF"
vcres@vcRefAnnoOn = True
vcres@vcRefAnnoOrthogonalPosF = 0.3
;vcres@vcRefAnnoParallelPosF = 0.7

ts_temp = ts_wff_trend 
ts_temp = (/ts_temp + ts_eff_trend/)
u_temp = u_wff_trend 
u_temp = (/u_temp + u_eff_trend/)
v_temp = v_wff_trend 
v_temp = (/v_temp + v_eff_trend/)

plot_panel_wind(wks, plot1(3), u_temp, v_temp, ts_temp, re2, vcres)  ; create plot

;===== panel plot =====;
resP = True
resP@gsnPanelLabelBar = True
resP@lbOrientation = "horizontal"
resP@lbBoxEndCapStyle = "TriangleBothEnds"
resP@pmLabelBarOrthogonalPosF = 0.015   
resP@gsnPanelYWhiteSpacePercent = 5

resP@lbTitleOn  = True
resP@lbTitleString  = "K/decade"
resP@lbTitleFontHeightF = 0.012
resP@lbTitlePosition = "Bottom"

resP@lbLabelFontHeightF = 0.01

gsn_panel(wks, plot1, (/2,2/), resP)

