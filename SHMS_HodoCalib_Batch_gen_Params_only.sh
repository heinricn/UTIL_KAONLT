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


mv "$REPLAYPATH/PARAM/SHMS/HODO/phodo_Vpcalib_$RUNNUMBER.param" "$REPLAYPATH/PARAM/SHMS/HODO/Calibration/phodo_Vpcalib_$RUNNUMBER.param"


