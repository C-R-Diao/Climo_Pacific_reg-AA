;========================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/dchenrui/ncl/2019_21C_Aero_PDO/func_lib/2d_global_map_resource.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_convergence_map/generate_data_v_potential.ncl"
;========================================================;	
; parameters
;========================================================;	
sigcheck    = 0 ; 1 for yes; 0 for no
sig         = 0.95

startyr = 1981	; startpoint of climo or trend
stopyr = 2020	; end point of climo or trend

LAND_MASK = 0
rewrite_file = 0 ; 1 if re-calculate the results


plotpath = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/figs/"
plotname = "Fig_S2_z_phi_slp_bmb"

;=======================================================;	
; read and process data: aer
;=======================================================;	
data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/data_for_plots/"
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

vp_aer_trend = f->sfvp_aer_trend(1, :, :)
sf_aer_trend = f->sfvp_aer_trend(0, :, :)
u_aer_trend =  f->u_aer_trend 
v_aer_trend =  f->v_aer_trend 
psl_aer_trend =  f->psl_aer_trend 
z200_aer_trend =  f->z200_aer_trend 
z500_aer_trend =  f->z500_aer_trend 
u850_aer_trend =  f->u850_aer_trend 
v850_aer_trend =  f->v850_aer_trend 

;=======================================================;	
; read bmb data 
;=======================================================;	
fname = "sfvp-trend_bmb_"+ startyr + "-" + stopyr + "_" + sigcheck + ".nc"
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

z200e_aer_trend = eddy_z(z200_aer_trend)
z500e_aer_trend = eddy_z(z500_aer_trend)

z200e_bmb_trend = eddy_z(z200_bmb_trend)
z500e_bmb_trend = eddy_z(z500_bmb_trend)

;=======================================================;	
; eddy sfvp
;=======================================================;	
if(1 .eq. 1) then
	vp_aer_trend = eddy_z(vp_aer_trend)
	sf_aer_trend = eddy_z(sf_aer_trend)

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
re2@lbBoxEndCapStyle = "TriangleBothEnds"

;===== wind vector control =====;
vcres                         = True             ; plot mods desired
vcres@gsnDraw  				  = False
vcres@gsnFrame                = False            ; so we can draw time stamp
vcres@vcRefAnnoOrthogonalPosF = -0.22            ; move ref vector up
vcres@vcRefMagnitudeF         = 0.5             ; define vector ref mag
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
; plot panel
;=======================================================;	
undef("plot_panel")
procedure plot_panel(wks, plot, u, v, ts, re_t, re_w)
local p_vec
begin
    plot = gsn_csm_contour_map(wks, ts, re_t)
    p_vec = gsn_csm_vector(wks, u, v, re_w)
    overlay(plot, p_vec)
end


;=======================================================;	
; plot5: z200e, stream function, slp
;=======================================================;	
print("plot eddy geopotential...")

plot = new(6, graphic)

;==========================;	
; a&b: z200e
;==========================;	
re3 = re2
re3@lbLabelBarOn = False
re3@cnLevels    := fspan(-3, 3, 21)
re3@gsnLeftString = "(a)  FF: 200hPa ~F33~D~F~Z~B~g~N~"
plot(0) = gsn_csm_contour_map(wks, z200e_aer_trend, re3)

re3@gsnLeftString = "(b)  BMB: 200hPa ~F33~D~F~Z~B~g~N~"
plot(1) = gsn_csm_contour_map(wks, z200e_bmb_trend, re3)

;==========================;	
; c&d: sf 
;==========================;
vcres@vcRefMagnitudeF = 0.5             ; define vector ref mag
vcres@vcMinMagnitudeF = 0.1

re3@cnLevels    := fspan(-4, 4, 21)
re3@lbTitleString = "10~S~5~N~ m~S~2~N~ s~S~-1~N~/decade"

re3@gsnLeftString = "(c)  ~F8~y"
plot_panel(wks, plot(2), u_aer_trend, v_aer_trend, sf_aer_trend, re3, vcres)

re3@gsnLeftString = "(d)  ~F8~y"
plot_panel(wks, plot(3), u_bmb_trend, v_bmb_trend, sf_bmb_trend, re3, vcres)

;==========================;	
; e&f: psl
;==========================;	
re3@cnLevels    := fspan(-25, 25, 21)
cmap_data = read_colormap_file("BlueWhiteOrangeRed")
re3@cnFillPalette       = cmap_data(::-1,:)

re3@lbTitleString = psl_bmb_trend@units

vcres@vcRefMagnitudeF = 0.2
vcres@vcMinMagnitudeF = 0.05

re3@gsnLeftString = "(e)  SLP" 
plot_panel(wks, plot(4), u850_aer_trend, v850_aer_trend, psl_aer_trend, re3, vcres)  ; create plot

re3@gsnLeftString = "(f)  SLP"
plot_panel(wks, plot(5), u850_bmb_trend, v850_bmb_trend, psl_bmb_trend, re3, vcres)  ; create plot


;==========================;	
; panel plots
;==========================;	
resP                  = True
;resP@gsnMaximize      = True
resP@gsnFrame         = False
resP@gsnPanelLabelBar = True
;resP@pmLabelBarWidthF = 0.8
resP@pmLabelBarOrthogonalPosF = -0.02

resP@gsnDraw = False

pplots = gsn_panel_return(wks,plot(0:1),(/1,2/),resP)

bb     = NhlGetBB(pplots)
height = max(bb(0:1,0)) - min(bb(0:1,1))

;==========;
resP@gsnDraw                          = True
resP@gsnPanelTop                      = 0.9   ; leave room for title
resP@gsnPanelBottom                   = resP@gsnPanelTop - height - 0.075

resP@gsnPanelLabelBar = True
resP@lbOrientation = "horizontal"
resP@lbBoxEndCapStyle = "TriangleBothEnds"

resP@lbTitleOn  = True
resP@lbTitleFontHeightF = 0.012
resP@lbTitlePosition = "Bottom"
resP@lbLabelFontHeightF = 0.01

;===== z200e =====;
resP@lbTitleString = z200e_bmb_trend@units
gsn_panel(wks,plot(0:1),(/1,2/),resP)

;===== sf =====;
resP@lbTitleString = "10~S~5~N~ m~S~2~N~ s~S~-1~N~/decade"
resP@gsnPanelTop        = resP@gsnPanelBottom
resP@gsnPanelBottom     = resP@gsnPanelTop-height -0.075

gsn_panel(wks,plot(2:3),(/1,2/),resP)

;===== slp =====;
resP@lbTitleString = psl_bmb_trend@units
resP@gsnPanelTop        = resP@gsnPanelBottom
resP@gsnPanelBottom     = resP@gsnPanelTop-height -0.075

gsn_panel(wks,plot(4:5),(/1,2/),resP)

;====================;
frame(wks)


