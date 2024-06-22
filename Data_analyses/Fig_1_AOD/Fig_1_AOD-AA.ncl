;========================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/dchenrui/ncl/2019_21C_Aero_PDO/func_lib/2d_global_map_resource.ncl"

load "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/Fig_1_AOD/generate_data_AOD_AA.ncl"
;========================================================;	
; parameters
;========================================================;	
sigcheck    = 0 ; 1 for yes; 0 for no
sig         = 0.95

startyr = 1981	; startpoint of climo or trend
stopyr = 2020	; end point of climo or trend

LAND_MASK = 0

plotpath = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/figs/"
plotname = "Fig_1_AOD-AA-trend"

rewrite_file = 0; 1 if re-calculate the results

;=======================================================;	
; read and process data
;=======================================================;	
data_path = "/glade/u/home/dchenrui/ncl/2021_Aero_IPO/2024_figs_for_manuscript/data_for_plots/"
fname = "AOD-AA-trend_"+ startyr + "-" + stopyr + ".nc"

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

aod_aa_aer_trend = f->aod_aa_aer_trend
aod_aa_eff_trend = f->aod_aa_eff_trend
aod_aa_wff_trend = f->aod_aa_wff_trend
aod_aa_bmb_trend = f->aod_aa_bmb_trend

;===== climo =====;
aod_aa_all_climo  = f->aod_aa_all_climo  

;========================================================;	
;plot resource
;========================================================;	
wks = gsn_open_wks("pdf",plotpath+plotname)

;< re loaded >;

;===== full global map for U =====;
re@mpMinLatF = -60
re@mpMaxLatF = 70

;re@mpMaxLonF = 290
;re@mpMinLonF = 110

;re@gsnRightStringFontHeightF = 0.04
;re@gsnLeftStringFontHeightF = re@gsnRightStringFontHeightF

re2 = re ; for trend

re2@cnLevelSelectionMode = "ExplicitLevels"
re2@cnLevels    = fspan(-0.02, 0.02, 21)
re2@lbLabelBarOn   = False

;=======================================================;	
; plot
;=======================================================;	
	
print("plot response trend...")

plot1 = new(4, graphic)

procedure plot_panel_wind(wks, plot, u, v, ts, re_t, re_w)
local p_vec
begin
	plot = gsn_csm_contour_map(wks, ts, re_t)
	p_vec = gsn_csm_vector(wks, u, v, re_w)		
	overlay(plot, p_vec)
end

;===== plot sst & 850 wind=====;
re2@gsnLeftString = "(a)  EastFF"
plot1(0) = gsn_csm_contour_map(wks, aod_aa_eff_trend, re2)

re2@gsnLeftString = "(b)  WestFF"
plot1(1) = gsn_csm_contour_map(wks, aod_aa_wff_trend, re2)

re2@gsnLeftString = "(c)  FF" 
plot1(2) = gsn_csm_contour_map(wks, aod_aa_aer_trend, re2)

re2@gsnLeftString = "(d)  FF - (WestFF + EastFF)"
aod_aa_temp = aod_aa_wff_trend 
aod_aa_temp = (/aod_aa_aer_trend - aod_aa_wff_trend - aod_aa_eff_trend/)
plot1(3) = gsn_csm_contour_map(wks, aod_aa_temp, re2)

;===== BMB =====;
re2@gsnLeftString = "(a)  BMB"
re2@cnLevels    := fspan(-0.01, 0.01, 21)
plot2 = gsn_csm_contour_map(wks, aod_aa_bmb_trend, re2)

;===== panel plot =====;
resP = True
resP@gsnPanelLabelBar = True
resP@lbOrientation = "horizontal"
resP@lbBoxEndCapStyle = "TriangleBothEnds"
resP@pmLabelBarOrthogonalPosF = -0.02
resP@pmLabelBarHeightF = 0.05
resP@gsnPanelYWhiteSpacePercent = 5

resP@lbTitleOn  = True
resP@lbTitleString  = "/decade"
resP@lbTitleFontHeightF = 0.012
resP@lbTitlePosition = "Bottom"
resP@lbLabelFontHeightF = 0.01

gsn_panel(wks, plot1, (/2,2/), resP)

resP@pmLabelBarWidthF = 0.5
gsn_panel(wks, plot2, (/1,1/), resP)
