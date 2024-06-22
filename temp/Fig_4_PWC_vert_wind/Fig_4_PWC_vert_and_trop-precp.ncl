;====================e===================================;
; aim: plot global map for CESM outpout AOD-AA (corrected)
; author: Chenrui Diao
; 2020-01-17
;========================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/Fig_4_PWC_vert_wind/generate_data_PRECT.ncl"
load "/glade/u/home/dchenrui/ncl/2019_21C_Aero_PDO/func_lib/2d_global_map_resource.ncl"
;========================================================;	
; parameters
;========================================================;	
startyr = 1981	; startpoint of climo or trend
stopyr = 2020	; end point of climo or trend

lat_range = (/-5, 5/)

rewrite_file = 0

plotpath = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/figs/"
plotname = "Fig_4_PWC_vert_motion_trend"

;=======================================================;	
; read data Part 1: vertical motion
;=======================================================;	
data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/data_for_plots/"
fname = "Omega_U_cross-sect_"+ startyr + "-" + stopyr + ".nc"
print("load data from nc file directly")
				
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
; read data Part 2: prect
;=======================================================;	
data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/data_for_plots/"
fname = "PRECT-trend_"+ startyr + "-" + stopyr + ".nc"
print("load PRECT data from nc file directly")

if (.not.fileexists(data_path + fname) .or. rewrite_file .eq. 1) then
    if(rewrite_file .eq. 1)
        print("rewriting data")
        system("rm -f " + data_path + fname)
    else
        print("generating data")
    end if

    generate_data(startyr, stopyr, 0, 0, 0)

else
    print("load data from nc file directly")
end if

f = addfile(data_path + fname, "r")
pr_aer_trend =  f->prect_aer_trend
pr_eff_trend =  f->prect_eff_trend
pr_wff_trend =  f->prect_wff_trend
pr_bmb_trend =  f->prect_bmb_trend

pr_all_climo = f->prect_all_climo
pr_aer_climo = f->prect_aer_climo
pr_eff_climo = f->prect_eff_climo
pr_wff_climo = f->prect_wff_climo
pr_bmb_climo = f->prect_bmb_climo

;=======================================================;	
; scaling omega
;=======================================================;	
scale = -200.0

;=======================================================;	
; plot res
;=======================================================;	
wks   = gsn_open_wks ("pdf", plotpath + plotname)        ; send graphics to PNG file


;==========================;	
; res for vert contour
;==========================;	
res                      = True
res@gsnDraw             = False           ; don't draw
res@gsnFrame            = False           ; don't advance frame
res@cnFillOn             = True                ; color on
res@cnLinesOn                   = False 
res@cnLineLabelsOn = False
res@cnInfoLabelOn = False

;===== label bar =====;
res@vpWidthF   = 0.5
res@vpHeightF  = 0.4
res@lbOrientation = "horizontal"
res@lbTitlePosition = "Bottom"
res@lbTitleFontHeightF= .01

gsn_define_colormap(wks, "BlueRed")
gsn_reverse_colormap(wks)

res@cnLevelSelectionMode = "ExplicitLevels"
res@cnLevels    = fspan(-2, 2, 21)
res@lbLabelBarOn = False

res@gsnRightString = ""
res@gsnLeftStringFontHeightF = 0.015
res@gsnStringFont = "Helvetica-Bold"

;==========================;	
res@gsnPresHgtHeightLabelOn = False
res@tmYROn = False

;===== wind vector control =====;
res@gsnDraw                 = False
res@gsnFrame                = False            ; so we can draw time stamp

res@vcRefAnnoOn       		= False
res@vcRefAnnoOrthogonalPosF = -1.05            ; move ref vector up
res@vcRefMagnitudeF         = 0.15             ; define vector ref mag
res@vcRefLengthF            = 0.04            ; define length of vec ref
res@vcRefAnnoString2On      = False           ; turn off the ref vector text
res@vcGlyphStyle            = "CurlyVector"    ; turn on curly vectors
res@vcMinDistanceF          = 0.02

res@vcLineArrowThicknessF = 1.5
res@vcLineArrowHeadMinSizeF = 0.007
res@vcLineArrowHeadMaxSizeF = 0.007

;==========================;	
; res for map contour
;==========================;	
re2 = re

re2@mpMinLatF = -30
re2@mpMaxLatF = 70

re2@lbLabelBarOn 		 = False
re2@lbTitleOn 			 = True
re2@cnLevelSelectionMode = "ExplicitLevels"
re2@lbBoxEndCapStyle 	 = "TriangleBothEnds"
re2@cnLevels    		:= fspan(-2.4, 2.4, 21)

;==========================;	
; res for panel
;==========================;	
resP                  = True
;resP@gsnMaximize      = True
resP@gsnFrame         = False
resP@gsnPanelLabelBar = True
;resP@pmLabelBarWidthF = 0.8
resP@pmLabelBarOrthogonalPosF = -0.02

resP@gsnPanelTop         = 0.9   ; leave room for title

resP@gsnPanelLabelBar    = True
resP@lbOrientation       = "horizontal"
resP@lbBoxEndCapStyle    = "TriangleBothEnds"
res@pmLabelBarHeightF    = 0.1

resP@lbTitleOn  		 = True
resP@lbTitleFontHeightF  = 0.012
resP@lbTitlePosition     = "Bottom"

;=======================================================;	
; plot
;=======================================================;	
plot = new(4, graphic)

;==========================;	
; vertical
;==========================;	
lev_max = 125

res@gsnLeftString = "(a)  EastFF"
temp = w_eff_trend
temp = (/w_eff_trend * 1000./)
plot(0)  = gsn_csm_pres_hgt_vector(wks, temp({1000:lev_max}, :), u_eff_trend({1000:lev_max}, :), w_eff_trend({1000:lev_max},:)*scale, res )

;===== set middle two bars to white =====#
undef("white_in_middle")
procedure white_in_middle(plot)
begin
	getvalues plot@contour    ; retrieve colors/levels from plot
		"cnFillColors" : colors
		"cnLevels"     : levels
	end getvalues
	ncolors = dimsizes(colors)
	colors(ncolors/2-1 : ncolors/2) = 0    ; set two middle colors to white

	setvalues plot@contour
		 "cnFillColors" : colors       ; reset the colors
	end setvalues
end 

;white_in_middle(plot(0))

res@gsnLeftString = "(b)  WestFF"
temp = w_wff_trend
temp = (/w_wff_trend * 1000./)
plot(1)  = gsn_csm_pres_hgt_vector(wks, temp({1000:lev_max}, :), u_wff_trend({1000:lev_max}, :), w_wff_trend({1000:lev_max},:)*scale, res )
;white_in_middle(plot(1))

;===== find height =====;	
resP@gsnDraw = False
pplots = gsn_panel_return(wks,plot(0:1),(/1,2/),resP)

bb     = NhlGetBB(pplots)
height = max(bb(0:1,0)) - min(bb(0:1,1))

;===== real panel =====;
resP@gsnDraw             = True
resP@gsnPanelBottom      = resP@gsnPanelTop - height 
resP@lbTitleString = "10~S~-3~N~ Pa s~S~-1~N~/decade"
resP@pmLabelBarHeightF = 0.05
gsn_panel(wks,plot(0:1),(/1,2/),resP)


;==========================;	
; prect
;==========================;	
cmap_data = read_colormap_file("BlueWhiteOrangeRed")
;re2@cnFillPalette       = cmap_data(::-1,:)
re2@cnFillPalette       = cmap_data

re2@gsnLeftString = "(c)  "
plot(2) = gsn_csm_contour_map(wks, pr_eff_trend, re2)

re2@gsnLeftString = "(d)  "
plot(3) = gsn_csm_contour_map(wks, pr_wff_trend, re2)

;==========================;	
resP@gsnPanelTop        = resP@gsnPanelBottom
resP@gsnPanelBottom     = resP@gsnPanelTop-height 
resP@lbTitleString = "mm day~S~-1~N~/decade"
resP@pmLabelBarOrthogonalPosF = -0.03

gsn_panel(wks, plot(2:3),(/1,2/),resP)


;==========================;	
frame(wks)