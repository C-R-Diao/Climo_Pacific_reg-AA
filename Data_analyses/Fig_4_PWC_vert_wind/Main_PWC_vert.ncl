;====================e===================================;
; aim: plot global map for CESM outpout AOD-AA (corrected)
; author: Chenrui Diao
; 2020-01-17
;========================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/Fig_3_PWC_vert_wind/generate_wind_sross_sec.ncl"
;========================================================;	
; parameters
;========================================================;	
startyr = 1981	; startpoint of climo or trend
stopyr = 2020	; end point of climo or trend

lat_range = (/-5, 5/)

reverse_west = 0
rewrite_file = 0

plotpath = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/figs/"
plotname = "Fig_3_PWC_vert_motion_trend"
;=======================================================;	
; read data
;=======================================================;	
data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/Fig_PWC_vert_wind/"
fname = "Omega_U_cross-sect_"+ startyr + "-" + stopyr + ".nc"

if (.not.fileexists(data_path + fname) .or. rewrite_file .eq. 1) then
    if(rewrite_file .eq. 1)
        print("rewriting data")
        system("rm -f " + data_path + fname)
    else
        print("generating data")
    end if

	generate_wind_sross_sec(startyr, stopyr, lat_range)

else
    print("load data from nc file directly")
end if
				
f = addfile(data_path + fname, "r")
u_aer_trend =  f->u_aer_trend
u_eff_trend =  f->u_eff_trend
u_wff_trend =  f->u_wff_trend

w_aer_trend =  f->w_aer_trend
w_eff_trend =  f->w_eff_trend
w_wff_trend =  f->w_wff_trend

u_all_climo = f->u_all_climo
u_aer_climo = f->u_aer_climo
u_eff_climo = f->u_eff_climo
u_wff_climo = f->u_wff_climo

w_all_climo = f->w_all_climo
w_aer_climo = f->w_aer_climo
w_eff_climo = f->w_eff_climo
w_wff_climo = f->w_wff_climo

;=======================================================;	
; reverse westff
;=======================================================;	
if(reverse_west .eq. 1)then
    print("reverse westFF")

    function rev_signal(v)
    local temp
    begin
        temp = v
        temp = (/-1.0*v/)
    return(temp)
    end

    u_wff_trend_r = rev_signal(u_wff_trend)
    w_wff_trend_r = rev_signal(w_wff_trend)
end if

;=======================================================;	
; scaling omega
;=======================================================;	
scale = -200.0

;=======================================================;	
; plot
;=======================================================;	
wks   = gsn_open_wks ("pdf", plotpath + plotname)        ; send graphics to PNG file

res                      = True
res@vpWidthF   = 0.4
res@vpHeightF  = 0.3

res@gsnDraw             = False           ; don't draw
res@gsnFrame            = False           ; don't advance frame

res@cnFillOn             = True                ; color on
res@cnLinesOn                   = False 
res@cnLineLabelsOn = False
res@lbOrientation = "Vertical"
res@lbTitlePosition = "Right"
res@lbTitleFontHeightF= .015

gsn_define_colormap(wks, "BlueRed")
gsn_reverse_colormap(wks)
res@cnLevelSelectionMode = "ExplicitLevels"
res@cnLevels    = fspan(-2, 2, 11)
res@lbTitleString = "10^-3 Pa/s per decade"
res@lbTitlePosition  = "Right"
res@lbTitleDirection = "Down"
res@lbLabelBarOn = True

res@gsnRightString = ""
res@gsnLeftStringFontHeightF = 0.025
res@gsnLeftStringFont = "Helvetica-Bold"

;===== wind vector control =====;
res                         = True             ; plot mods desired
res@gsnDraw                 = False
res@gsnFrame                = False            ; so we can draw time stamp
res@vcRefAnnoOrthogonalPosF = -1.05            ; move ref vector up
res@vcRefMagnitudeF         = 0.15             ; define vector ref mag
res@vcRefLengthF            = 0.04            ; define length of vec ref
res@vcRefAnnoString2On      = False           ; turn off the ref vector text
res@vcGlyphStyle            = "CurlyVector"    ; turn on curly vectors
;res@vcGlyphStyle            = "LineArrow"    ; turn on curly vectors
res@vcMinDistanceF          = 0.02

res@vcLineArrowThicknessF = 1.5
res@vcLineArrowHeadMinSizeF = 0.007
res@vcLineArrowHeadMaxSizeF = 0.007



;==========================;	
; plot1 trend
;==========================;	
plot = new(4, graphic)

lev_max = 100

res@gsnLeftString = "(a)  FF"

temp = w_aer_trend
temp = (/w_aer_trend * 1000./)
plot(1)  = gsn_csm_pres_hgt_vector(wks, temp({1000:lev_max}, :), u_aer_trend({1000:lev_max}, :), w_aer_trend({1000:lev_max},:)*scale, res )

res@gsnLeftString = "(a)  EastFF"
temp = w_eff_trend
temp = (/w_eff_trend * 1000./)
plot(2)  = gsn_csm_pres_hgt_vector(wks, temp({1000:lev_max}, :), u_eff_trend({1000:lev_max}, :), w_eff_trend({1000:lev_max},:)*scale, res )

res@gsnLeftString = "(b)  WestFF"
temp = w_wff_trend
temp = (/w_wff_trend * 1000./)
if(reverse_west .eq. 1)then
	plot(3)  = gsn_csm_pres_hgt_vector(wks, temp({1000:lev_max}, :), u_wff_trend_r({1000:lev_max}, :), w_wff_trend_r({1000:lev_max},:)*scale, res )
else
	plot(3)  = gsn_csm_pres_hgt_vector(wks, temp({1000:lev_max}, :), u_wff_trend({1000:lev_max}, :), w_wff_trend({1000:lev_max},:)*scale, res )
end if

;===== climo =====;
res@gsnLeftString = "Climatology"
res@cnLevels    := fspan(-0.04, 0.04, 21)
res@vcRefMagnitudeF         = 8.0             ; define vector ref mag

plot(0)  = gsn_csm_pres_hgt_vector(wks, w_all_climo({1000:lev_max}, :), u_all_climo({1000:lev_max}, :), w_all_climo({1000:lev_max},:)*scale, res )

;===== addition =====;
;res@gsnLeftString = "(d)  EastFF + WestFF"
;
;w_sum = w_eff_trend
;w_sum = (/w_sum + w_wff_trend/)
;u_sum = u_eff_trend
;u_sum = (/u_sum + u_wff_trend/)

;plot(3)  = gsn_csm_pres_hgt_vector(wks, w_sum({1000:lev_max}, :), u_sum({1000:lev_max}, :), w_sum({1000:lev_max},:)*scale, res )


resP                     = True                ; modify the panel plot
resP@lbLabelFontHeightF  = 0.007               ; make labels smaller
;resP@gsnPanelLabelBar = True
resP@lbOrientation = "vertical"

;gsn_panel(wks, (/plot(0), plot(2), plot(3)/),(/3, 1/),resP)               ; now draw as one plot
gsn_panel(wks, plot(1:),(/3, 1/),resP)               ; now draw as one plot
gsn_panel(wks, plot(0),(/3, 1/),resP)               ; now draw as one plot

;==========================;	
; plot2 diff of climo
;==========================;	
plot1 = new(4, graphic)

res@vcRefMagnitudeF         = 0.2             ; define vector ref mag
res@gsnLeftString = "(a)  FF"
plot1(0)  = gsn_csm_pres_hgt_vector(wks, w_aer_climo({1000:lev_max}, :), u_aer_climo({1000:lev_max}, :), w_aer_climo({1000:lev_max},:)*scale, res )

res@gsnLeftString = "(b)  EastFF"
plot1(1)  = gsn_csm_pres_hgt_vector(wks, w_eff_climo({1000:lev_max}, :), u_eff_climo({1000:lev_max}, :), w_eff_climo({1000:lev_max},:)*scale, res )

res@vcRefMagnitudeF         = 0.1             ; define vector ref mag
res@gsnLeftString = "(c)  WestFF"
plot1(2)  = gsn_csm_pres_hgt_vector(wks, w_wff_climo({1000:lev_max}, :), u_wff_climo({1000:lev_max}, :), w_wff_climo({1000:lev_max},:)*scale, res )

;===== climo =====;
res@gsnLeftString = "(d) Vertical montion  Climatology"
res@cnLevels    := fspan(-0.05, 0.05, 21)
res@vcRefMagnitudeF         = 10.0             ; define vector ref mag

plot1(3)  = gsn_csm_pres_hgt_vector(wks, w_all_climo({1000:lev_max}, :), u_all_climo({1000:lev_max}, :), w_all_climo({1000:lev_max},:)*scale, res )


resP                     = True                ; modify the panel plot
resP@lbLabelFontHeightF  = 0.007               ; make labels smaller

gsn_panel(wks, plot1,(/2,2/),resP)               ; now draw as one plot


