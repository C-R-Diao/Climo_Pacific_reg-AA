;========================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/dchenrui/ncl/2019_21C_Aero_PDO/func_lib/2d_global_map_resource.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_convergence_map/for_bmb/generate_data_v_potential_bb.ncl"
;========================================================;	
; parameters
;========================================================;	
sigcheck    = 0 ; 1 for yes; 0 for no
sig         = 0.95

startyr = 1981	; startpoint of climo or trend
stopyr = 2020	; end point of climo or trend

LAND_MASK = 0
rewrite_file = 0 ; 1 if re-calculate the results


plotpath = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/figs/"
plotname = "fig_map_velocity-potential-trend_" + startyr + "-" + stopyr + "_BB"


;=======================================================;	
; read and process data
;=======================================================;	
data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_convergence_map/for_bmb/"
fname = "sfvp-trend_"+ startyr + "-" + stopyr + "_" + sigcheck + ".nc"

if (.not.fileexists(data_path + fname) .or. rewrite_file .eq. 1) then
	if(rewrite_file .eq. 1)
		print("rewriting data")
		system("rm -f " + data_path + fname)
	else
		print("generating data")
	end if
	
	generate_data_v_potential(startyr, stopyr, sigcheck, sig)

else
	print("load data from nc file directly")
end if


f = addfile(data_path + fname, "r")

vp_bmb_trend = f->sfvp_bmb_trend(1, :, :)
sf_bmb_trend = f->sfvp_bmb_trend(0, :, :)
u_bmb_trend =  f->u_bmb_trend 
v_bmb_trend =  f->v_bmb_trend  
psl_bmb_trend =  f->psl_bmb_trend  
z200_bmb_trend =  f->z200_bmb_trend  
z500_bmb_trend =  f->z500_bmb_trend  
u850_bmb_trend =  f->u850_bmb_trend 
v850_bmb_trend =  f->v850_bmb_trend  

;=======================================================;	
; calculate eddy Z
;=======================================================;	
undef("eddy_z")
function eddy_z(z)
local temp, zonal
begin
	temp = z
	temp = (/dim_rmvmean_n(z, 1)/)
return(temp)
end

z200e_bmb_trend = eddy_z(z200_bmb_trend)

z500e_bmb_trend = eddy_z(z500_bmb_trend)

;=======================================================;	
; eddy sfvp
;=======================================================;	
if(1 .eq. 1) then
	vp_bmb_trend = eddy_z(vp_bmb_trend)

	sf_bmb_trend = eddy_z(sf_bmb_trend)
end if

;=======================================================;	
; land mask
;=======================================================;	
if(LAND_MASK .eq. 1)
	
	print("ERR: land mask disableed, please update code!!")

end if



;========================================================;	
;plot resource
;========================================================;	
wks = gsn_open_wks("pdf",plotpath+plotname)

;< re loaded >;

;===== full global map for U =====;
re@mpMinLatF = -30
re@mpMaxLatF = 70

;re@gsnRightStringFontHeightF = 0.04
;re@gsnLeftStringFontHeightF = re@gsnRightStringFontHeightF

re2 = re ; for trend
re2@lbLabelBarOn = True
re2@lbTitleOn = True
re2@cnLevelSelectionMode = "ExplicitLevels"


;===== wind vector control =====;
vcres                         = True             ; plot mods desired
vcres@gsnDraw  				  = False
vcres@gsnFrame                = False            ; so we can draw time stamp
vcres@vcRefAnnoOrthogonalPosF = -0.8            ; move ref vector up
vcres@vcRefMagnitudeF         = 0.4             ; define vector ref mag
vcres@vcRefLengthF            = 0.04            ; define length of vec ref
vcres@vcRefAnnoString2On	  = False			; turn off the ref vector text
;vcres@vcGlyphStyle            = "CurlyVector"    ; turn on curly vectors
vcres@vcMinDistanceF          = 0.02

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
; plot1: vp + sf
;=======================================================;	
print("plot vp and sf...")
	
plot1 = new(6, graphic)

;===== procedure for plot =====;
undef("plot_panel")
procedure plot_panel(wks, plot, u, v, ts, re_t, re_w)
local p_vec
begin
	plot = gsn_csm_contour_map(wks, ts, re_t)
	p_vec = gsn_csm_vector(wks, u, v, re_w)		
	overlay(plot, p_vec)
end

;===== stream function =====;
re2@cnLevels    = fspan(-5, 5, 21)
vcres@vcRefMagnitudeF = 0.3
vcres@vcMinMagnitudeF = 0.1
re2@lbTitleString = "10^5 m^2/s/decade"

re2@gsnLeftString = "(e)  ~F8~y"
plot_panel(wks, plot1(1), u_bmb_trend, v_bmb_trend, sf_bmb_trend, re2, vcres)  ; create plot

;===== panel plot =====;
resP = True
resP@gsnPanelLabelBar = False
;	resP@lbTitleOn  = False
;	resP@lbTitleString  = "10^5 m^2/s/decade"
;	resP@lbTitleFontHeightF = 0.0075
;	resP@lbTitleAngleF = 90.
;	resP@lbTitleDirection = "Across"
;
;	resP@lbTitlePosition = "Right"
;	resP@lbOrientation = "vertical"
;;		resP@lbOrientation = "horizontal"
;	resP@lbLabelFontHeightF = 0.0075
resP@pmLabelBarWidthF = 0.03
resP@gsnPanelBottom   = 0.05	
resP@gsnPanelRight = 0.95



;=======================================================;	
; plot3 z200e, z500e
;=======================================================;	
print("plot eddy geopotential...")

;gsn_reverse_colormap(wks) 
re3 = re2 ; for psl
;re3@lbLabelBarOn = False

plot3 = new(9, graphic)

;===== z200e =====;
re3@cnLevels    := fspan(-3, 3, 19)
re3@lbTitleString = z200e_bmb_trend@units
re3@gsnLeftString = "(d)  BMB: ~F33~D~F~Z~B~g~N" 
;plot_panel(wks, plot3(0), u_bmb_trend, v_bmb_trend, z200e_bmb_trend, re3, vcres)  ; create plot
plot3(0) = gsn_csm_contour_map(wks, z200e_bmb_trend, re3)

;===== z500 =====;
re3@cnLevels    := fspan(-2, 2, 17)
re3@lbTitleString = z500_bmb_trend@units

re3@gsnLeftString = "(d) Z500e @ BMB" 
plot3(3) = gsn_csm_contour_map(wks, z500e_bmb_trend, re3)

;===== psl =====;
re3@cnLevels    := fspan(-30, 30, 21)
re3@lbTitleString = psl_bmb_trend@units

vcres@vcRefMagnitudeF         = 0.2
vcres@vcMinMagnitudeF = 0.05
re3@gsnLeftString = "(f) SLP" 
plot_panel(wks, plot3(6), u850_bmb_trend, v850_bmb_trend, psl_bmb_trend, re3, vcres)  ; create plot

gsn_panel(wks, (/plot3(0), plot1(1), plot3(6),plot1(0)/), (/3,1/), resP)
