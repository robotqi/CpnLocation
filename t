#!/bin/csh
#
#NAME
#	locations_ipc.csh
#	
#DESCRIPTION
#	Adds a location number for each IPC and AB Coupons in the panel,
#	numbering as follow: "Y1, X2, Y3, X4" (for Top, Right, Bottom, Left).
#
#	
#
#CALLING SCRIPT[S]
#	N/A
#
#CALLED SCRIPT[S]
#	$GENESIS_DIR/.ceirc			[main resources file]
#	
#
#RELATED FILES
#	N/A
#
#AUTHOR
#	Salah Elezaby, Automation Consultant
#
#HISTORY
#	02/18/08	: Version 1.00	: SE
#			
#	02/20/08	: Version 1.01	: SE
#			CHANGES:
#			o Changed text "1Y, 2X, 3Y, 4X" to "Y1, X2, Y3, X4"
#			
#	02/22/08	: Version 1.02	: SE
#			CHANGES:
#			o Allow for drawn outer layer as well. (i.e. job#.1 and job#.1d
#			
#	09/23/08	: Version 2.00	: SE
#			CHANGES:
#			o Now adding the location numbers to the "ab_cpn" as well.
#			o Also, modified the ".ceirc" file.
#			
#	09/24/08	: Version 2.01	: SE
#			CHANGES:
#			o Adding the location numbers to the "a_cpn", and "b_cpn", if it exist.
#
#########################################################################################################


if ($1 != "") then
	COM sel_clear_feat
	exit
endif

set ver_num = "[Version 2.01]"

if (! $?SCR_DIR) then
	set SCR_DIR = $GENESIS_DIR/sys/scripts
endif

source $SCR_DIR/.ceirc

TRY_AGAIN:
if (! $?JOB) then
	echo "WIN 100 40\
	FONT hbr18\
	BG 444444\
	LABEL JOB SELECTION\
	BG 888888\
	FONT hbr14\
	TEXT job_name 2 Enter Control Number :\
	END"> $GENESIS_TMP/job_name.$PID

	$GENESIS_EDIR/all/gui $GENESIS_TMP/job_name.$PID > $GENESIS_TMP/job_name_gui.$PID
	source $GENESIS_TMP/job_name_gui.$PID
	rm $GENESIS_TMP/job_name.$PID $GENESIS_TMP/job_name_gui.$PID

	DO_INFO -t job -e $job_name -d exists
	if ($gEXISTS == yes) then
		set JOB = $job_name
		COM check_inout,mode=out,type=job,job=$JOB
		COM clipb_open_job,job=$JOB,update_clipboard=view_job
		COM open_job,job=$JOB
	else
		PAUSE JOB $job_name DOES NOT EXIST. PRESS Continue script AND TRY AGAIN.
		goto TRY_AGAIN
	endif
endif

set pnl_name = $PNL_WRK
DO_INFO -t step -e $JOB/$pnl_name -d REPEAT
if ($gREPEATstep[1] == $ARR_WRK) then
	set pcb_name = $ARR_WRK
else
	set pcb_name = $PCB_WRK
endif

if (-e $TMP_DIR/cpns_loc.$JOB) rm $TMP_DIR/cpns_loc.$JOB

COM open_entity,job=$JOB,type=step,name=$pnl_name,iconic=yes
set pnl_group = $COMANS
AUX set_group,group=$pnl_group
COM clear_layers
COM affected_layer,mode=all,affected=no
COM affected_filter,filter=(type=signal|power_ground|mixed&context=board&side=top)
COM get_affect_layer
set w_lay = $COMANS
COM affected_layer,mode=all,affected=no

COM display_layer,name=$w_lay,display=yes,number=1
COM work_layer,name=$w_lay
COM zoom_home

#
# Get IPC and AB Coupons Information
#

DO_INFO -t step -e $JOB/$pnl_name -d SR
@ i = 1
@ j = 1
while ($i <= $#gSRstep)
	switch ($gSRstep[$i])
		case $CPN_IPC:
			echo "$j $gSRxa[$i] $gSRya[$i] $gSRangle[$i]" >> $TMP_DIR/cpns_loc.$JOB
			@ j++
			breaksw
		case $CPN_AB:
			echo "$j $gSRxa[$i] $gSRya[$i] $gSRangle[$i]" >> $TMP_DIR/cpns_loc.$JOB
			@ j++
			breaksw
		case $CPN_A:
			echo "$j $gSRxa[$i] $gSRya[$i] $gSRangle[$i]" >> $TMP_DIR/cpns_loc.$JOB
			@ j++
			breaksw
		case $CPN_B:
			echo "$j $gSRxa[$i] $gSRya[$i] $gSRangle[$i]" >> $TMP_DIR/cpns_loc.$JOB
			@ j++
			breaksw
		default:
			:
			breaksw
	endsw

	#
	# Get the S+R limits
	#

	if ($gSRstep[$i] == $pcb_name) then
		set sr_top = $gSRymax[$i]
		set sr_rgt = $gSRxmax[$i]
		set sr_bot = $gSRymin[$i]
		set sr_lft = $gSRxmin[$i]
	endif
	@ i++
end

if (! -e $TMP_DIR/cpns_loc.$JOB) then
	PAUSE JOB $JOB HAS NO IPC or AB COUPONS. ABORTING .....
	exit 0
endif

COM display_layer,name=$w_lay,display=yes,number=1
COM work_layer,name=$w_lay

#
# Text default parameters
#

set x_size = 55
set y_size = 70
set t_size = 12

# dscheuer 05/11/09:
# Changed awk95 to awk
set x_size = `echo $x_size | awk '{printf("%0.3f"), $1/1000}'`
set y_size = `echo $y_size | awk '{printf("%0.3f"), $1/1000}'`
set w_fact = `echo "$t_size * 0.083333" | bc`
set ipc_locx = 0.295
set ipc_locy = 0.520

#
# Check for existing serial numbers
#

COM filter_set,filter_name=popup,update_popup=no,feat_types=text
COM filter_atr_set,filter_name=popup,condition=yes,attribute=.string,text=ipcloc
COM filter_area_strt
COM filter_area_end,layer=,filter_name=popup,operation=select,\
area_type=none,inside_area=no,intersect_area=no,lines_only=no,\
ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0
COM get_select_count
set ipcloc_cnt = $COMANS
if ($ipcloc_cnt > 0) then
	COM do_on_abort,script=$PROG,user_data=unsel
	PAUSE OLD IPC LOCATIONS EXIST. CONTINUE TO DELETE THEM.
	COM sel_delete
endif
COM filter_reset,filter_name=popup

PAUSE WAiting

# Call the script to order the coupons correctly.
$SCR_DIR/ClockwiseSort.pl $TMP_DIR/cpns_loc.$JOB

set step_loc = (`cut -d" " -f1 $TMP_DIR/cpns_loc.$JOB`)
set step_ordr = (`cut -d" " -f2 $TMP_DIR/cpns_loc.$JOB`)
set step_orgx = (`cut -d" " -f3 $TMP_DIR/cpns_loc.$JOB`)
set step_orgy = (`cut -d" " -f4 $TMP_DIR/cpns_loc.$JOB`)
set step_angl = (`cut -d" " -f5 $TMP_DIR/cpns_loc.$JOB`)

rm $TMP_DIR/cpns_loc.$JOB

set Top = 1
set Right = 1
set Left = 1
set Bottom = 1

COM cur_atr_set,attribute=.string,text=ipcloc
@ i = 1
while ($i <= $#step_ordr)

	set NEWipc_loc = $step_loc[$i]

	switch ($step_angl[$i])
		case 0:
			set locx = `echo "scale=6;$step_orgx[$i] + $ipc_locx" | bc`
			set locy = `echo "scale=6;$step_orgy[$i] + $ipc_locy" | bc`
			set res = `echo $locy $sr_top | awk '{if ($1>$2) print 1; else print 0}'`
			if ($res) then
				set ipc_loc = "$IPC_LOC_T-$Top"
				@ Top++
			else
				set ipc_loc = "$IPC_LOC_B-$Bottom"
				@ Bottom++
			endif
			breaksw
		case 90:
			set locx = `echo "scale=6;$step_orgx[$i] + $ipc_locy" | bc`
			set locy = `echo "scale=6;$step_orgy[$i] - $ipc_locx" | bc`
			set res = `echo $locx $sr_rgt | awk '{if ($1>$2) print 1; else print 0}'`
			if ($res) then
				set ipc_loc = "$IPC_LOC_R-$Right"
				@ Right++
			else
				set ipc_loc = "$IPC_LOC_L-$Left"
				@ Left++
			endif
			breaksw
		case 180:
			set locx = `echo "scale=6;$step_orgx[$i] - $ipc_locx" | bc`
			set locy = `echo "scale=6;$step_orgy[$i] - $ipc_locy" | bc`
			set res = `echo $locy $sr_top | awk '{if ($1>$2) print 1; else print 0}'`
			if ($res) then
				set ipc_loc = "$IPC_LOC_T-$Top"
				@ Top++
			else
				set ipc_loc = "$IPC_LOC_B-$Bottom"
				@ Bottom++
			endif
			breaksw
		case 270:
			set locx = `echo "scale=6;$step_orgx[$i] - $ipc_locy" | bc`
			set locy = `echo "scale=6;$step_orgy[$i] + $ipc_locx" | bc`
			set res = `echo $locx $sr_rgt | awk '{if ($1>$2) print 1; else print 0}'`
			if ($res) then
				set ipc_loc = "$IPC_LOC_R-$Right"
				@ Right++
			else
				set ipc_loc = "$IPC_LOC_L-$Left"
				@ Left++
			endif
			breaksw
	endsw
	set angle = $step_angl[$i]
	COM add_text,attributes=yes,type=string,x=$locx,y=$locy,text=$NEWipc_loc,x_size=$x_size,y_size=$y_size,\
	w_factor=$w_fact,polarity=positive,angle=$angle,mirror=no,fontname=standard
	@ i++
	@ start_num++
end
COM cur_atr_reset

COM open_entity,job=$JOB,type=step,name=$pnl_name,iconic=no
COM display_sr,display=yes

exit (0)
