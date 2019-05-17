#!/bin/bash

### Script for running (via batch or otherwise) the HMS hodoscope calibration, this one script does all of the relevant steps for the calibration process
### Note, for these to run they require the HMSHodo_Calib_Coin_Pt1 sym links to exist in your replay path
### If you want to run for the SHMS you will also have to modify the scripts to make and look at similar sym links
### Note that the second part also has an additional bit where it checks for a database file based upon the run number

# The path to your hallc replay directory, change as needed
#REPLAYPATH="/group/c-kaonlt/USERS/${USER}/hallc_replay_kaonlt"
REPLAYPATH="/home/${USER}/work/JLab/hallc_replay_kaonlt"
RUNNUMBER=$1
MAXEVENTS=-1
#MAXEVENTS=50000
if [[ $1 -eq "" ]]; then
    echo "I need a Run Number!"
    echo "Please provide a run number as input"
    exit 2
fi

#Initialize enviroment
#export OSRELEASE="Linux_CentOS7.2.1511-x86_64-gcc5.2.0"
#source /site/12gev_phys/softenv.sh 2.1

#Initialize hcana, change if not running on the farm!
# Change this path if you're not on the JLab farm!
#cd "/u/group/c-kaonlt/hcana/"
#source "/u/group/c-kaonlt/hcana/setup.sh"
cd "/home/apps/hcana/"
source "/home/apps/hcana/setup.sh"
cd "$REPLAYPATH"
source "$REPLAYPATH/setup.sh"

eval "hcana -l -q \"SCRIPTS/SHMS/PRODUCTION/SHMSHodo_calib_Coin_Pt1.C($RUNNUMBER,$MAXEVENTS)\""
ROOTFILE="$REPLAYPATH/ROOTfiles/HodoCalibPt1/shms_Hodo_Calib_Pt1_"$RUNNUMBER"_-1.root" 
OPT="shms"
cd "$REPLAYPATH/CALIBRATION/shms_hodo_calib/"
root -l -q -b "timeWalkHistos.C (\"$ROOTFILE\", $RUNNUMBER, \"$OPT\")"
root -l -q -b "timeWalkCalib.C($RUNNUMBER)"

# After executing first two root scripts, should have a new .param file so long as scripts ran ok, IF NOT THEN EXIT
if [ ! -f "$REPLAYPATH/PARAM/SHMS/HODO/phodo_TWcalib_$RUNNUMBER.param" ]; then
    echo "TWCalib_$RUNNUMBER not found, calibration script likely failed"
    exit 2
fi

### Now we set up the second replay by making some .database and .param files for them
cd "$REPLAYPATH/DBASE/COIN"
if [ "$RUNNUMBER" -le "6580" ]; then
    # Copy our normal ones
    cp standard.database SHMS_HodoCalib/standard_$RUNNUMBER.database
    cp general.param SHMS_HodoCalib/general_$RUNNUMBER.param
    # Use sed to replace the strings, 3 means line 3, note for sed to work with a variable we need to use "", syntax "Line# s/TEXT TO REPLACE/REPLACEMENT/" FILE
    sed -i "3 s/general.param/SHMS_HodoCalib\/general_$RUNNUMBER.param/" SHMS_HodoCalib/standard_$RUNNUMBER.database
    sed -i "40 s/phodo_TWcalib.param/phodo_TWcalib_$RUNNUMBER.param/" SHMS_HodoCalib/general_$RUNNUMBER.param 
fi

if [ "$RUNNUMBER" -ge "6581" ]; then
    cp standard.database SHMS_HodoCalib/standard_$RUNNUMBER.database
    cp general_runperiod2.param SHMS_HodoCalib/general_$RUNNUMBER.param
    sed -i "8 s/general_runperiod2.param/SHMS_HodoCalib\/general_$RUNNUMBER.param/" SHMS_HodoCalib/standard_$RUNNUMBER.database
    sed -i "40 s/phodo_TWcalib.param/phodo_TWcalib_$RUNNUMBER.param/" SHMS_HodoCalib/general_$RUNNUMBER.param
fi
# Back to the main directory
cd "$REPLAYPATH"                                
# Off we go again replaying
eval "$REPLAYPATH/hcana -l -q \"SCRIPTS/SHMS/PRODUCTION/SHMSHodo_calib_Coin_Pt2.C($RUNNUMBER,$MAXEVENTS)\""

# Clean up the directories of our generated files
mv "$REPLAYPATH/PARAM/SHMS/HODO/phodo_TWcalib_$RUNNUMBER.param" "$REPLAYPATH/PARAM/SHMS/HODO/Calibration/phodo_TWcalib_$RUNNUMBER.param"
mv "$REPLAYPATH/CALIBRATION/shms_hodo_calib/timeWalk_Histos"$RUNNUMBER".root" "$REPLAYPATH/CALIBRATION/shms_hodo_calib/Calibration_Plots/timeWalkHistos_"$RUNNUMBER".root"

cd "$REPLAYPATH/CALIBRATION/shms_hodo_calib/"
# Define the path to the second replay root file
ROOTFILE2="$REPLAYPATH/ROOTfiles/HodoCalibPt2/shms_Hodo_Calib_Pt2_"$RUNNUMBER"_-1.root"
# Execute final script
root -l -q -b "fitHodoCalib.C(\"$ROOTFILE2\", $RUNNUMBER)" 
 
# Check our new file exists, if not exit, if yes, move it
if [ ! -f "$REPLAYPATH/PARAM/SHMS/HODO/phodo_Vpcalib_$RUNNUMBER.param" ]; then
    echo "phodo_Vpcalib_$RUNNUMBER.param not found, calibration script likely failed"
    exit 2
fi

mv "$REPLAYPATH/PARAM/SHMS/HODO/phodo_Vpcalib_$RUNNUMBER.param" "$REPLAYPATH/PARAM/SHMS/HODO/Calibration/phodo_Vpcalib_$RUNNUMBER.param"

# Check our new file exists, if not exit, if yes, move it
if [ ! -f "$REPLAYPATH/CALIBRATION/shms_hodo_calib/HodoCalibPlots_$RUNNUMBER.root" ]; then
    echo "HodoCalibPlots_$RUNNUMBER.root not found, calibration script likely failed"
    exit 2
fi

mv "$REPLAYPATH/CALIBRATION/shms_hodo_calib/HodoCalibPlots_$RUNNUMBER.root" "$REPLAYPATH/CALIBRATION/shms_hodo_calib/Calibration_Plots/HodoCalibPlots_$RUNNUMBER.root"
