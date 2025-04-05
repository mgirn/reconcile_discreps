#!/bin/bash

############## Activate AFNI and FreeSurfer environments
export FREESURFER_HOME="/Applications/freesurfer"
source "${FREESURFER_HOME}/SetUpFreeSurfer.sh"
export PATH="$PATH:$HOME/abin"
export DYLD_FALLBACK_LIBRARY_PATH="$HOME/abin"

############## General parameters
cohort="LSD"
EPIpname="RS_lowpass"  # Options: RS_lowpass, RS_NOlowpass, RS_lowpass_noSmooth
finished_subjects=0     # 0 = run all preprocessing, 1 = skip all, 2 = skip most

############## Subject lists and cohort-specific settings

if [ "$cohort" == "LSD" ]; then
    allsubjects="S01 S02 S03 S04 S06 S09 S10 S11 S12 S13 S15 S17 S18 S19 S20"
    goodsubjects="$allsubjects"
    goodsubjects_retino="S01 S02 S03 S04 S06 S09 S10 S13 S15 S17 S18 S20"
    very_goodsubjects="S01 S03 S04 S09 S11 S12 S15 S18 S20"
    goodsubjects_music="S01 S02 S04 S06 S09 S10 S11 S13 S17 S18 S19 S20"
    goodsubjects_music_romy="S01 S02 S04 S05 S06 S07 S09 S10 S11 S13 S14 S16 S17 S18 S19 S20"

    a1="S01 S02 S04 S05 S06 S07 S09 S10"
    a2="S11 S13 S14 S16 S17 S18 S19 S20"

    movers="S05 S07 S14 S16"
    sub16="S16"
    again="S07 S14 S16"

    T1pname="T1_CFN_beta"
    session_loop="PCB LSD"
    run_loop="Rest1 Rest2 Rest3"
    T1prepro_session="PCB"

    remove_first_X_tr=3
    fieldmap_available=0
    stc="alt+z2"
    TR=2
    total_TR=217

    dofilter=1
    highpass=0.01
    lowpass=0.08
    polort=2
    polortM=2

    FWHM=6
    WMlocal=2
    model="M_V_DV"
    Despike=1
    prewhitening=1
    epiregtype="FSL_epireg"

    scrub=1
    scrub_criterion="FD_040"
    scrubbing="scrubbed_${scrub_criterion}"

elif [ "$cohort" == "PSILO" ]; then
    allsubjects="S01 S02 S03 S04 S05 S06 S07 S08 S09 S10 S11 S12 S13 S14 S15"
    goodsubjects="S01 S03 S05 S07 S09 S11 S13 S14 S15"
    good_p1="S01 S03 S05 S07 S09"
    good_p2="S11 S13 S14 S15"
    test1="S01"

    T1pname="T1_CFN_beta"
    session_loop="PCB"
    run_loop="2nd_half_3min"
    T1prepro_session="PCB"

    remove_first_X_tr=3
    fieldmap_available=0
    stc="alt+z2"
    TR=3
    total_TR=57

    dofilter=1
    highpass=0
    lowpass=0.08
    polort=0
    polortM=0

    FWHM=6
    WMlocal=2
    model="MD_V_DV_Ex"
    Despike=1
    prewhitening=1
    epiregtype="FSL_epireg"

    scrub=1
    scrub_criterion="FD_040"
    scrubbing="scrubbed_${scrub_criterion}"
fi

############## Directory paths
basedir="/Users/lr912/analysis"
basedir_google="/Users/lr912/Google_Drive/analysis_google"
python="/Users/lr912/anaconda2/bin/python"
scriptsdir="${basedir_google}/pipeline/scripts"
brainwavelet="'/Users/lr912/matlab/BrainWavelet'"

cohortdir="${basedir}/data/${cohort}"
rawdir="${cohortdir}/raw"

T1preprodir="${cohortdir}/preprocessing/${T1pname}"
EPIpreprodir="${cohortdir}/preprocessing/${EPIpname}"
mkdir -p "$T1preprodir" "$EPIpreprodir"

############## FreeSurfer directory
export SUBJECTS_DIR="${cohortdir}/FS_archive"


chosen_ones=`eval echo "\$"${1}`

if [[ "${chosen_ones}" == '$' ]]; then
        echo "                                                          "
        echo "                                                          "
        echo "please enter subjectlist name..."
        echo "                                                          "
        echo "                                                          "
        exit 1
fi

echo $chosen_ones


####To delete a file from all subjects, CD to the directory
#for x in `find . -name "S13"`; do echo $x; done    
#for x in `find . -name "S13"`; do echo $x; rm -r $x; done



############## Run preprocessing 

if [[ ! "${finished_subjects}" == 1 ]]; then	
	for session in `echo $session_loop`
	do
		for run in `echo $run_loop`
		do
			for subject in `echo $chosen_ones` #`echo $chosen_ones`
			do

				if [ $cohort == 'LSD' ]; then
					epiregtype="FSL_epireg"
					if [ $subject == 'S17' ];then
						epiregtype="Free_surfer"
					fi
					if [ $subject == 'S13' ];then
						epiregtype="manual"
					fi
				    if [ $subject == 'S19' ];then
						epiregtype="manual"
					fi

					#for rest 2 (analysis for Romy and Mendel)
					if [ $subject == 'S07' ];then
						epiregtype="manual"
					fi
					if [ $subject == 'S14' ];then
						epiregtype="manual"
					fi
					if [ $subject == 'S16' ];then
						epiregtype="manual"
					fi
				fi


				start=$SECONDS
				pwd
				preBET="$T1preprodir/$T1prepro_session/native/preBET/$subject";mkdir -p $preBET
				strucreg="$T1preprodir/$T1prepro_session/ANTs/MNI152/$subject";mkdir -p $strucreg
				seg="$T1preprodir/$T1prepro_session/native/seg/$subject";mkdir -p $seg
				FS_core="$T1preprodir/$T1prepro_session/native/FS_core/$subject";mkdir -p $FS_core
				FS_archive="$cohortdir/FS_archive"
				FS_orig="$T1preprodir/$T1prepro_session/native/labels/FS_orig/$subject";mkdir -p $FS_orig
				native_prep_labels="$T1preprodir/$T1prepro_session/native/labels/prep/$subject";mkdir -p $native_prep_labels
				MNI152_prep_labels="$T1preprodir/$T1prepro_session/MNI152/labels/prep/$subject";mkdir -p $MNI152_prep_labels
				MNI152_RS_labels="$T1preprodir/$T1prepro_session/MNI152/labels/RS/$subject";mkdir -p $MNI152_RS_labels
				funcreg="$EPIpreprodir/$session/$run/funcreg/$epiregtype/$subject";mkdir -p $funcreg
				prepro1="$EPIpreprodir/$session/$run/native/intact/prepro/$subject";mkdir -p $prepro1
				native_funclabel="$EPIpreprodir/$session/$run/native/intact/funclabel/$subject";mkdir -p $native_funclabel

				diagnostics="$EPIpreprodir/$session/$run/diagnostics";mkdir -p $diagnostics
				motion="$diagnostics/$scrubbing/motion/$subject";mkdir -p ${motion}
				intact_motion="$diagnostics/intact/motion/$subject";mkdir -p ${intact_motion}
				intact_prescrub_dvars="$diagnostics/intact/dvars/prescrub/$subject";mkdir -p ${intact_prescrub_dvars}
				intact_raw_dvars="$diagnostics/intact/dvars/raw/$subject";mkdir -p ${intact_raw_dvars}

				scrubindex="$diagnostics/scrubindex/$subject";mkdir -p $scrubindex
				
				#intact_diagnostics="$EPIpreprodir/$session/$run/diagnostics/intact";mkdir -p $intact_diagnostics
				#scrubbed_diagnostics=="$EPIpreprodir/$session/$run/diagnostics/scrubbed"; if [ ! -d $scrubbed_diagnostics ]; then mkdir -p $scrubbed_diagnostics; fi
				intact_prepro1="$EPIpreprodir/$session/$run/native/intact/prepro/$subject";mkdir -p $intact_prepro1
				intact_prepro2="$EPIpreprodir/$session/$run/MNI152/intact/prepro/$subject";mkdir -p $intact_prepro2

				#postregression="$EPIpreprodir/$session/$run/diagnostics/$scrubbing"; mkdir -p $postregression
				#mkdir -p $intact_diagnostics/wavelet/$subject
				#mkdir -p $intact_diagnostics/prebandpass/$subject
				
				echo `date` > $EPIpreprodir/$session/$run/methods
				methods=$EPIpreprodir/$session/$run/methods

					echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
					echo "beginning processing of subject $subject session ${session} $run"
					echo PREPRODIR - $prepro1
					echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"


				functional="${session}_${run}"


				if [[ ! "${finished_subjects}" == 2 ]]; then	
					if [ ! -f ${intact_prepro1}/${functional}_rdsmf.nii.gz ]; then
						rawfuncfilepath="$rawdir/$subject/$session/${run}.nii.gz"

						#Split out the short TE
						if [[ $cohort == 'PSILODEP' ]]  ; then 
							non_split_dir="$rawdir/$subject/$session/non_split/$run"; mkdir -p $non_split_dir
							if [[ ! -f $non_split_dir/split_out_TE_done ]]; then
								mv $rawfuncfilepath $rawdir/$subject/$session/${run}_nonsplit.nii.gz
								pushd $non_split_dir
									fslsplit $rawdir/$subject/$session/${run}_nonsplit.nii.gz
									fslmerge -tr $rawfuncfilepath vol0001.nii.gz vol0003.nii.gz vol0005.nii.gz vol0007.nii.gz vol0009.nii.gz vol0011.nii.gz vol0013.nii.gz vol0015.nii.gz vol0017.nii.gz vol0019.nii.gz vol0021.nii.gz vol0023.nii.gz vol0025.nii.gz vol0027.nii.gz vol0029.nii.gz vol0031.nii.gz vol0033.nii.gz vol0035.nii.gz vol0037.nii.gz vol0039.nii.gz vol0041.nii.gz vol0043.nii.gz vol0045.nii.gz vol0047.nii.gz vol0049.nii.gz vol0051.nii.gz vol0053.nii.gz vol0055.nii.gz vol0057.nii.gz vol0059.nii.gz vol0061.nii.gz vol0063.nii.gz vol0065.nii.gz vol0067.nii.gz vol0069.nii.gz vol0071.nii.gz vol0073.nii.gz vol0075.nii.gz vol0077.nii.gz vol0079.nii.gz vol0081.nii.gz vol0083.nii.gz vol0085.nii.gz vol0087.nii.gz vol0089.nii.gz vol0091.nii.gz vol0093.nii.gz vol0095.nii.gz vol0097.nii.gz vol0099.nii.gz vol0101.nii.gz vol0103.nii.gz vol0105.nii.gz vol0107.nii.gz vol0109.nii.gz vol0111.nii.gz vol0113.nii.gz vol0115.nii.gz vol0117.nii.gz vol0119.nii.gz vol0121.nii.gz vol0123.nii.gz vol0125.nii.gz vol0127.nii.gz vol0129.nii.gz vol0131.nii.gz vol0133.nii.gz vol0135.nii.gz vol0137.nii.gz vol0139.nii.gz vol0141.nii.gz vol0143.nii.gz vol0145.nii.gz vol0147.nii.gz vol0149.nii.gz vol0151.nii.gz vol0153.nii.gz vol0155.nii.gz vol0157.nii.gz vol0159.nii.gz vol0161.nii.gz vol0163.nii.gz vol0165.nii.gz vol0167.nii.gz vol0169.nii.gz vol0171.nii.gz vol0173.nii.gz vol0175.nii.gz vol0177.nii.gz vol0179.nii.gz vol0181.nii.gz vol0183.nii.gz vol0185.nii.gz vol0187.nii.gz vol0189.nii.gz vol0191.nii.gz vol0193.nii.gz vol0195.nii.gz vol0197.nii.gz vol0199.nii.gz vol0201.nii.gz vol0203.nii.gz vol0205.nii.gz vol0207.nii.gz vol0209.nii.gz vol0211.nii.gz vol0213.nii.gz vol0215.nii.gz vol0217.nii.gz vol0219.nii.gz vol0221.nii.gz vol0223.nii.gz vol0225.nii.gz vol0227.nii.gz vol0229.nii.gz vol0231.nii.gz vol0233.nii.gz vol0235.nii.gz vol0237.nii.gz vol0239.nii.gz vol0241.nii.gz vol0243.nii.gz vol0245.nii.gz vol0247.nii.gz vol0249.nii.gz vol0251.nii.gz vol0253.nii.gz vol0255.nii.gz vol0257.nii.gz vol0259.nii.gz vol0261.nii.gz vol0263.nii.gz vol0265.nii.gz vol0267.nii.gz vol0269.nii.gz vol0271.nii.gz vol0273.nii.gz vol0275.nii.gz vol0277.nii.gz vol0279.nii.gz vol0281.nii.gz vol0283.nii.gz vol0285.nii.gz vol0287.nii.gz vol0289.nii.gz vol0291.nii.gz vol0293.nii.gz vol0295.nii.gz vol0297.nii.gz vol0299.nii.gz vol0301.nii.gz vol0303.nii.gz vol0305.nii.gz vol0307.nii.gz vol0309.nii.gz vol0311.nii.gz vol0313.nii.gz vol0315.nii.gz vol0317.nii.gz vol0319.nii.gz vol0321.nii.gz vol0323.nii.gz vol0325.nii.gz vol0327.nii.gz vol0329.nii.gz vol0331.nii.gz vol0333.nii.gz vol0335.nii.gz vol0337.nii.gz vol0339.nii.gz vol0341.nii.gz vol0343.nii.gz vol0345.nii.gz vol0347.nii.gz vol0349.nii.gz vol0351.nii.gz vol0353.nii.gz vol0355.nii.gz vol0357.nii.gz vol0359.nii.gz vol0361.nii.gz vol0363.nii.gz vol0365.nii.gz vol0367.nii.gz vol0369.nii.gz vol0371.nii.gz vol0373.nii.gz vol0375.nii.gz vol0377.nii.gz vol0379.nii.gz vol0381.nii.gz vol0383.nii.gz vol0385.nii.gz vol0387.nii.gz vol0389.nii.gz vol0391.nii.gz vol0393.nii.gz vol0395.nii.gz vol0397.nii.gz vol0399.nii.gz vol0401.nii.gz vol0403.nii.gz vol0405.nii.gz vol0407.nii.gz vol0409.nii.gz vol0411.nii.gz vol0413.nii.gz vol0415.nii.gz vol0417.nii.gz vol0419.nii.gz vol0421.nii.gz vol0423.nii.gz vol0425.nii.gz vol0427.nii.gz vol0429.nii.gz vol0431.nii.gz vol0433.nii.gz vol0435.nii.gz vol0437.nii.gz vol0439.nii.gz vol0441.nii.gz vol0443.nii.gz vol0445.nii.gz vol0447.nii.gz vol0449.nii.gz vol0451.nii.gz vol0453.nii.gz vol0455.nii.gz vol0457.nii.gz vol0459.nii.gz vol0461.nii.gz vol0463.nii.gz vol0465.nii.gz vol0467.nii.gz vol0469.nii.gz vol0471.nii.gz vol0473.nii.gz vol0475.nii.gz vol0477.nii.gz vol0479.nii.gz 2
									rm vol0*
									touch split_out_TE_done
								popd
							fi
						fi

						#remove TRs
						if [ ! ${remove_first_X_tr} == 0 ]; then
							Raw_TRlength=`3dinfo -ntimes $rawfuncfilepath`
							Trimmed_TRlength=$((Raw_TRlength - $remove_first_X_tr))
							fslroi $rawfuncfilepath ${intact_prepro1}/${functional}_trimmed.nii.gz $remove_first_X_tr $Trimmed_TRlength
							
							3drefit -TR $TR ${intact_prepro1}/${functional}_trimmed.nii.gz
							echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
							echo "TR has been changed to the correct TR of" `3dinfo -TR ${intact_prepro1}/${functional}_trimmed.nii.gz`
							echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
							echo "Trimmed first $remove_first_X_tr TRs from total of $Raw_TRlength, with $Trimmed_TRlength remaining" >> $methods

						else
							cp $rawfuncfilepath ${intact_prepro1}/${functional}_trimmed.nii.gz
							3drefit -TR $TR ${intact_prepro1}/${functional}_trimmed.nii.gz
							echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
							echo "TR has been changed to the correct TR of" `3dinfo -TR ${intact_prepro1}/${functional}_trimmed.nii.gz`
						fi

						echo "Reorienting functionals after deobliquing (3dresample in AFNI)..."
						3dresample -orient RPI -inset ${intact_prepro1}/${functional}_trimmed.nii.gz -prefix ${intact_prepro1}/${functional}_r.nii.gz #2> /dev/null
						if [[ $Despike == "1" ]]; then
							echo "Despiking (3dDespike in AFNI)..." >> $methods
							#or with -nomask
							3dDespike -nomask -prefix ${intact_prepro1}/${functional}_rd.nii.gz ${intact_prepro1}/${functional}_r.nii.gz 
						else
							echo "no despiking applied" >> $methods
							cp ${intact_prepro1}/${functional}_r.nii.gz ${intact_prepro1}/${functional}_rd.nii.gz
						fi
						if [ ! ${stc} == 0 ]; then
							echo "Slice timing correction (3dTshift in AFNI)... with $stc"
							3dTshift -tpattern $stc -prefix ${intact_prepro1}/${functional}_rds.nii.gz ${intact_prepro1}/${functional}_rd.nii.gz #2> /dev/null
							echo "Slice timing correction - $stc" >> $methods
						else
							echo "no slice timing correction was undertaken"
							cp ${intact_prepro1}/${functional}_rd.nii.gz ${intact_prepro1}/${functional}_rds.nii.gz
							echo "No slice timing correction" >> $methods
						fi
						if [ ! -f ${intact_motion}/bestvolume ];then  #This is done in case the bestvolume was copyied from a different preprocessing
							bestvolume=`python $scriptsdir/mofind.py ${intact_prepro1}/${functional}_rds.nii.gz`
							echo "$bestvolume" > ${intact_motion}/bestvolume
						else
							bestvolume=`cat ${intact_motion}/bestvolume`
						fi
						echo "All volumes registered to volume $bestvolume" >> $methods
						3dvolreg -Fourier -twopass -base $bestvolume -zpad 4 -prefix ${intact_prepro1}/${functional}_rdsm.nii.gz -1Dfile ${intact_motion}/motion_predt_prebp.1D ${intact_prepro1}/${functional}_rds.nii.gz
						echo "calculating motion derivative"
						1d_tool.py -infile ${intact_motion}/motion_predt_prebp.1D -derivative -write ${intact_motion}/motion_predt_prebp_deriv.1D
						echo "calculating framewise displacement"
						1deval -a ${intact_motion}/motion_predt_prebp_deriv.1D'[0]' -b ${intact_motion}/motion_predt_prebp_deriv.1D'[1]' -c ${intact_motion}/motion_predt_prebp_deriv.1D'[2]' -d ${intact_motion}/motion_predt_prebp_deriv.1D'[3]' -e ${intact_motion}/motion_predt_prebp_deriv.1D'[4]' -f ${intact_motion}/motion_predt_prebp_deriv.1D'[5]' -expr '100*sind(abs(a)/2) + 100*sind(abs(b)/2) + 100*sind(abs(c)/2) + abs(d) + abs(e) + abs(f)' > ${intact_motion}/FD.1D
						3dmaskave -sigma -quiet ${intact_motion}/FD.1D > ${intact_motion}/mean_sigma_FD

						echo "calculating absolute displacement"
						1deval -a ${intact_motion}/motion_predt_prebp.1D'[0]' -b ${intact_motion}/motion_predt_prebp.1D'[1]' -c ${intact_motion}/motion_predt_prebp.1D'[2]' -d ${intact_motion}/motion_predt_prebp.1D'[3]' -e ${intact_motion}/motion_predt_prebp.1D'[4]' -f ${intact_motion}/motion_predt_prebp.1D'[5]' -expr '100*sind(abs(a)/2) + 100*sind(abs(b)/2) + 100*sind(abs(c)/2) + abs(d) + abs(e) + abs(f)' > ${intact_motion}/AbsD.1D
						3dmaskave -sigma -quiet ${intact_motion}/AbsD.1D > ${intact_motion}/mean_sigma_AbsD

						echo "calculating speed of movement"
						3dmaskave -sum ${intact_motion}/FD.1D | awk '{print $1}' > ${intact_motion}/total_FD
						1deval -a ${intact_motion}/total_FD -expr "a/${TR}/${total_TR}" > ${intact_motion}/mean_speed_TR_${TR}_${total_TR}volumes

						echo "first round of brain extraction"
						bet ${intact_prepro1}/${functional}_rdsm.nii.gz ${intact_prepro1}/${functional}_rdsmf.nii.gz -F
						echo "calculating mean"
						3dTstat -mean -prefix ${intact_prepro1}/${functional}_rdsmf_mean.nii.gz ${intact_prepro1}/${functional}_rdsmf.nii.gz
					fi
					

					if [ ! -f $funcreg/${functional}"_func2struc.tfm" ]; then
						echo "changing filenames to attain compatibility with BBR"
						cp ${FS_core}/T1.nii.gz ${funcreg}/T1_restore.nii.gz
						cp ${FS_core}/T1_brain.nii.gz ${funcreg}/T1_brain_restore.nii.gz
						cp $seg/T1_brain_restore_wmseg.nii.gz ${funcreg}/T1_brain_restore_wmseg.nii.gz

						if [ ${fieldmap_available} == "Siemens" ]; then
							fieldmap="$EPIpreprodir/$session/$run/native/fieldmap/$subject"; if [ ! -d $fieldmap ]; then mkdir -p $fieldmap; fi

							if [ ! -f ${fieldmap}/*_rads.nii.gz ]; then
							fieldmap_rawdir=/Users/lr912/analysis/data/$cohort/raw/$subject/$session/imaging/fieldmap
							magnitude=Fieldmap-MAG-${subject}v${session}
							phase=Fieldmap-PHASE-${subject}v${session}
							delta_TE=2.46 #default usually 2.46 on SIEMENS
			
							echo "copying fieldmap from rawdir"
							cp ${fieldmap_rawdir}/${magnitude}.nii.gz ${fieldmap}/${magnitude}.nii.gz
							3drefit -xdel 3.516 -ydel 3.516 -zdel 3.000 ${fieldmap}/${magnitude}.nii.gz
							cp ${fieldmap_rawdir}/${phase}.nii.gz ${fieldmap}/${phase}.nii.gz
							3drefit -xdel 3.516 -ydel 3.516 -zdel 3.000 ${fieldmap}/${phase}.nii.gz

							echo "brain extracting magnitude map"
							bet ${fieldmap}/${magnitude} ${fieldmap}/${magnitude}_brain.nii.gz -f 0.6 -m
							echo "eroding magnitude map mask"
							3dcalc -a ${fieldmap}/${magnitude}_brain_mask.nii.gz -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'a* (1-amongst(0,b,c,d,e,f,g))' -prefix ${fieldmap}/${magnitude}_brain_erode1.nii.gz
							3dcalc -a ${fieldmap}/${magnitude}_brain_erode1.nii.gz -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'a* (1-amongst(0,b,c,d,e,f,g))' -prefix ${fieldmap}/${magnitude}_brain_erode2.nii.gz
							3dcalc -a ${fieldmap}/${magnitude}_brain_erode2.nii.gz -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'a* (1-amongst(0,b,c,d,e,f,g))' -prefix ${fieldmap}/${magnitude}_brain_erode3.nii.gz
							echo "preparing fieldmap in radians"
							fsl_prepare_fieldmap SIEMENS ${fieldmap}/${phase}.nii.gz ${fieldmap}/${magnitude}_brain_erode2.nii.gz ${fieldmap}/${phase}_rads.nii.gz ${delta_TE}	
							fi
							echo "Aligning native functional image (8th volume only) to native T1 image (Boundary Based Registration in FSL 5) with phase map..."
							epi_reg --epi=${intact_prepro1}/${functional}_rdsmf_mean.nii.gz --t1=${FS_core}/T1_restore.nii.gz --t1brain=${FS_core}/T1_brain_restore.nii.gz --out=$funcreg/$functional"_func2struc" --fmap=${fieldmap}/${phase}_rads.nii.gz --fmapmag=${fieldmap}/${magnitude}.nii.gz --fmapmagbrain=${fieldmap}/${magnitude}_brain_erode2.nii.gz --echospacing=0.00052 --pedir=-y
						else

							if [ $epiregtype == 'FSL_epireg' ]; then
								epi_reg --epi=${intact_prepro1}/${functional}_rdsmf_mean.nii.gz --t1=${funcreg}/T1_restore.nii.gz --t1brain=${funcreg}/T1_brain_restore.nii.gz --out=$funcreg/$functional"_func2struc" 
							elif [ $epiregtype == 'FSL_FLIRT_6dof' ]; then  # no BBR (cost)
								flirt -dof 6 -in ${intact_prepro1}/${functional}_rdsmf_mean.nii.gz -ref ${funcreg}/T1_brain_restore.nii.gz -out $funcreg/$functional"_func2struc" -omat $funcreg/$functional"_func2struc.mat" -cost corratio
							elif [ $epiregtype == 'FSL_FLIRT_7dof' ]; then
								flirt -dof 7 -in ${intact_prepro1}/${functional}_rdsmf_mean.nii.gz -ref ${funcreg}/T1_brain_restore.nii.gz -out $funcreg/$functional"_func2struc" -omat $funcreg/$functional"_func2struc.mat" -cost corratio
							elif [ $epiregtype == 'FSL_FLIRT_12dof' ]; then
								flirt -dof 12 -in ${intact_prepro1}/${functional}_rdsmf_mean.nii.gz -ref ${funcreg}/T1_brain_restore.nii.gz -out $funcreg/$functional"_func2struc" -omat $funcreg/$functional"_func2struc.mat" -cost corratio
							elif [ $epiregtype == 'Free_surfer' ]; then
								bbregister --s $subject --mov ${intact_prepro1}/${functional}_rdsmf_mean.nii.gz --reg $funcreg/register.dat --init-fsl --bold --fslmat $funcreg/$functional"_func2struc_OLD.mat" #--init-reg --init-fsl
								python freesurf2fsl_matrix.py $funcreg/$functional"_func2struc_OLD.mat" $funcreg/$functional"_func2struc.mat"
							elif [ $epiregtype == 'FSL_epireg_deob' ]; then
								3dWarp -oblique2card -quintic -prefix ${intact_prepro1}/${functional}_rdsmf_ob_mean.nii.gz ${intact_prepro1}/${functional}_rdsmf_mean.nii.gz
								epi_reg --epi=${intact_prepro1}/${functional}_rdsmf_ob_mean.nii.gz --t1=${funcreg}/T1_restore.nii.gz --t1brain=${funcreg}/T1_brain_restore.nii.gz --out=$funcreg/$functional"_func2struc" 
							#elif [ $epiregtype == 'manual' ]; then
								##was done manually (see manual_Reg text) 
							fi
						fi

						convert_xfm -omat $funcreg/$functional"_struc2func.mat" -inverse $funcreg/$functional"_func2struc.mat"		
						echo "converting BBR mat file to ITK mat file in 2 steps"
						c3d_affine_tool -ref ${FS_core}/T1_brain.nii.gz -src ${intact_prepro1}/${functional}_rdsmf_mean.nii.gz $funcreg/${functional}"_func2struc.mat" -fsl2ras -oitk $funcreg/${functional}"_func2struc_PRE.tfm"
						sed -e "s|MatrixOffsetTransformBase_double_3_3|"AffineTransform_double_3_3"|g" $funcreg/${functional}"_func2struc_PRE.tfm" > $funcreg/${functional}"_func2struc.tfm"
						echo "converting BBR inverse mat file to ITK mat file in 2 steps"
						c3d_affine_tool -ref ${intact_prepro1}/${functional}_rdsmf_mean.nii.gz -src ${FS_core}/T1_brain.nii.gz $funcreg/${functional}"_struc2func.mat" -fsl2ras -oitk $funcreg/${functional}"_struc2func_PRE.tfm"
						sed -e "s|MatrixOffsetTransformBase_double_3_3|"AffineTransform_double_3_3"|g" $funcreg/${functional}"_struc2func_PRE.tfm" > $funcreg/${functional}"_struc2func.tfm"
					fi


		            if [ ! -f ${native_funclabel}/T1_brain_EPI_mask.nii.gz ]; then
		                   #THIS IS DONE HERE SINCE IT USES BBR TRANSFORM
		                   echo "creating T1_brain_EPI_mask"
		                   raw_x=`fslhd ${intact_prepro1}/${functional}_r.nii.gz | grep pixdim1 | awk '{print $2}'`
		                   raw_y=`fslhd ${intact_prepro1}/${functional}_r.nii.gz | grep pixdim2 | awk '{print $2}'`
		                   raw_z=`fslhd ${intact_prepro1}/${functional}_r.nii.gz | grep pixdim3 | awk '{print $2}'`

		                   3dcalc -a ${intact_prepro1}/${functional}_r.nii.gz[$bestvolume] -expr 'a' -prefix ${intact_prepro1}/${functional}_r_bestvol_${bestvolume}.nii.gz
		                   ls ${intact_prepro1}/${functional}_r_bestvol_${bestvolume}.nii.gz
		                   if [ ! -f ${native_prep_labels}/T1_brain_mask_filled.nii.gz ]; then 
		                   		3dmask_tool -input ${native_prep_labels}/T1_brain_mask.nii.gz -prefix ${native_prep_labels}/T1_brain_mask_filled.nii.gz -fill_holes; 
		            		fi
		                   . $scriptsdir/ANTs_clean_29_10_2014.sh ${intact_prepro1}/${functional}_r_bestvol_${bestvolume}.nii.gz ${native_prep_labels}/T1_brain_mask_filled.nii.gz ${strucreg} "apply_inverse_to_label" ${native_funclabel}/T1_brain_EPI_mask.nii.gz
		                       3drefit -xdel ${raw_x} -ydel ${raw_y} -zdel ${raw_z} ${native_funclabel}/T1_brain_EPI_mask.nii.gz
		           
		          	fi

					if [ ! -f ${intact_prepro1}/${functional}_r_T1masked_modecorr.nii.gz ]; then
						echo "fork for mode correcting brain"
						dvarspath=${intact_raw_dvars}
						fslmaths ${intact_prepro1}/${functional}_r.nii.gz -mul ${native_funclabel}/T1_brain_EPI_mask.nii.gz ${intact_prepro1}/${functional}_r_T1masked.nii.gz
						3dTstat -mean -prefix ${intact_prepro1}/${functional}_r_mean.nii.gz ${intact_prepro1}/${functional}_r_T1masked.nii.gz
						3dBrickStat -mask ${native_funclabel}/T1_brain_EPI_mask.nii.gz -median ${intact_prepro1}/${functional}_r_mean.nii.gz > ${dvarspath}/gms.1D
						gms=`cat ${dvarspath}/gms.1D`; gmsa=($gms); p50=${gmsa[1]}
						echo "p50" $p50
						3dcalc -a ${intact_prepro1}/${functional}_r_T1masked.nii.gz -expr "a*1000/${p50}" -prefix ${intact_prepro1}/${functional}_r_T1masked_modecorr.nii.gz
					fi
					if [ ! -f ${intact_raw_dvars}/mean_sigma_DVARS.1D ]; then
						echo "calculating raw DVARS"
						dvarspath=${intact_raw_dvars}
						3dcalc -a ${intact_prepro1}/${functional}_r_T1masked_modecorr.nii.gz -b "a[0,0,0,-1]" -expr "(a - b)^2" -prefix ${dvarspath}/${functional}_r_T1masked_m_deriv_squared.nii.gz
						fslmeants -i ${dvarspath}/${functional}_r_T1masked_m_deriv_squared.nii.gz -m ${native_funclabel}/T1_brain_EPI_mask.nii.gz > ${dvarspath}/deriv_squared.1D
						1deval -a  ${dvarspath}/deriv_squared.1D -expr '(sqrt(a))/10'  >  ${dvarspath}/DVARS.1D
						3dmaskave -sigma -quiet ${dvarspath}/DVARS.1D >  ${dvarspath}/mean_sigma_DVARS.1D
						rm ${dvarspath}/${functional}_r_T1masked_m_deriv_squared.nii.gz
					fi

					dvarspath=${intact_raw_dvars}
					if [ ! -f ${dvarspath}/global_signal.1D ]; then
						fslmeants -i ${intact_prepro1}/${functional}_r_T1masked_modecorr.nii.gz -m ${native_funclabel}/T1_brain_EPI_mask.nii.gz -o ${dvarspath}/global_signal.1D
					fi



					if [ ! -f ${intact_prepro2}/${functional}_rdsmf.nii.gz ]; then
						echo "calculating ANTs transform"
						. $scriptsdir/ANTs_clean_29_10_2014.sh ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz ${intact_prepro1}/${functional}_rdsmf.nii.gz ${strucreg} apply_to_functional ${intact_prepro2}/${functional}_rdsmf.nii.gz 
							3drefit -xdel 2.0 -ydel 2.0 -zdel 2.0 ${intact_prepro2}/${functional}_rdsmf.nii.gz
						echo "=================================================="
						fslstats ${intact_prepro2}/${functional}_rdsmf.nii.gz -R >> $methods
						echo "=================================================="
					fi

					if [ ! -f ${intact_prepro2}/${functional}_rdsmffm.nii.gz ]; then
						dvarspath=${intact_prescrub_dvars}
						fslmaths ${intact_prepro2}/${functional}_rdsmf.nii.gz -mul ${MNI152_prep_labels}/T1_brain_mask_filled.nii.gz ${intact_prepro2}/${functional}_rdsmff.nii.gz
						3dTstat -mean -prefix ${intact_prepro2}/${functional}_rdsmff_mean.nii.gz ${intact_prepro2}/${functional}_rdsmff.nii.gz
						3dBrickStat -mask ${MNI152_prep_labels}/T1_brain_mask_filled.nii.gz -median ${intact_prepro2}/${functional}_rdsmff_mean.nii.gz > ${dvarspath}/gms.1D
						gms=`cat ${dvarspath}/gms.1D`; gmsa=($gms); p50=${gmsa[1]}
						echo "p50" $p50
						3dcalc -a ${intact_prepro2}/${functional}_rdsmff.nii.gz -expr "a*1000/${p50}" -prefix ${intact_prepro2}/${functional}_rdsmffm.nii.gz
					fi


					if [ ! -f ${intact_prescrub_dvars}/mean_sigma_DVARS.1D ]; then
						echo "calculating prebandpass DVARS"
						dvarspath=${intact_prescrub_dvars}
						3dcalc -a ${intact_prepro2}/${functional}_rdsmffm.nii.gz -b "a[0,0,0,-1]" -expr "(a - b)^2" -prefix ${dvarspath}/${functional}_rsmffm_deriv_squared.nii.gz
						fslmeants -i ${dvarspath}/${functional}_rsmffm_deriv_squared.nii.gz -m ${MNI152_prep_labels}/T1_brain_mask_filled.nii.gz > ${dvarspath}/deriv_squared.1D
						1deval -a  ${dvarspath}/deriv_squared.1D -expr '(sqrt(a))/10'  >  ${dvarspath}/DVARS.1D
						3dmaskave -sigma -quiet ${dvarspath}/DVARS.1D >  ${dvarspath}/mean_sigma_DVARS.1D
						rm ${dvarspath}/${functional}_rsmffm_deriv_squared.nii.gz
					fi

					dvarspath=${intact_prescrub_dvars}
					if [ ! -f ${dvarspath}/global_signal.1D ]; then
						fslmeants -i ${intact_prepro2}/${functional}_rdsmffm.nii.gz -m ${MNI152_prep_labels}/T1_brain_mask_filled.nii.gz -o ${dvarspath}/global_signal.1D
					fi

					if [ ! -f ${scrubindex}/DVARS_090.1D ]; then
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.20 -overwrite -write ${scrubindex}/FD_020.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.25 -overwrite -write ${scrubindex}/FD_025.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.30 -overwrite -write ${scrubindex}/FD_030.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.35 -overwrite -write ${scrubindex}/FD_035.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.40 -overwrite -write ${scrubindex}/FD_040.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.45 -overwrite -write ${scrubindex}/FD_045.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.50 -overwrite -write ${scrubindex}/FD_050.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.55 -overwrite -write ${scrubindex}/FD_055.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.60 -overwrite -write ${scrubindex}/FD_060.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.65 -overwrite -write ${scrubindex}/FD_065.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.70 -overwrite -write ${scrubindex}/FD_070.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.75 -overwrite -write ${scrubindex}/FD_075.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.80 -overwrite -write ${scrubindex}/FD_080.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.85 -overwrite -write ${scrubindex}/FD_085.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.90 -overwrite -write ${scrubindex}/FD_090.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 0.95 -overwrite -write ${scrubindex}/FD_095.1D
						1d_tool.py -infile ${intact_motion}/FD.1D -extreme_mask -1 1.00 -overwrite -write ${scrubindex}/FD_100.1D
						1d_tool.py -infile ${intact_prescrub_dvars}/DVARS.1D -extreme_mask -1 -0.30 -overwrite -write ${scrubindex}/DVARS_030.1D
						1d_tool.py -infile ${intact_prescrub_dvars}/DVARS.1D -extreme_mask -1 -0.50 -overwrite -write ${scrubindex}/DVARS_050.1D
						1d_tool.py -infile ${intact_prescrub_dvars}/DVARS.1D -extreme_mask -1 -0.70 -overwrite -write ${scrubindex}/DVARS_070.1D
						1d_tool.py -infile ${intact_prescrub_dvars}/DVARS.1D -extreme_mask -1 -0.90 -overwrite -write ${scrubindex}/DVARS_090.1D
					fi


					if [[ $scrub == "1" ]]; then
						total_TR_scrub=`3dmaskave -sum ${scrubindex}/${scrub_criterion}.1D | awk '{print $1}'`
						if [[ $total_TR_scrub == 0 ]]; then
							echo ""
							echo "there are no volumes to scrub at ${scrub_criterion}"
							if [ ! -f ${intact_prepro2}/${functional}_rdsmffms.nii.gz ]; then
								cp ${intact_prepro2}/${functional}_rdsmffm.nii.gz ${intact_prepro2}/${functional}_rdsmffms.nii.gz
							fi
							echo ""
							MNI152_funclabel="$EPIpreprodir/$session/$run/MNI152/intact/funclabel/$subject";mkdir -p $MNI152_funclabel
							prepro2="$EPIpreprodir/$session/$run/MNI152/intact/prepro/$subject";mkdir -p $prepro2
							unsmoothed2="$EPIpreprodir/$session/$run/MNI152/intact/unsmoothed/$subject";mkdir -p $unsmoothed2
							nuisance="$EPIpreprodir/$session/$run/MNI152/intact/nuisance/$subject";mkdir -p $nuisance
							motion="$diagnostics/intact/motion/$subject";mkdir -p ${motion}
							clean="$EPIpreprodir/$session/$run/MNI152/intact/clean/$subject";mkdir -p $clean
							final_dvars="$diagnostics/intact/dvars/${model}_WMlocal${WMlocal}/$subject";mkdir -p ${final_dvars}
							echo "0" > ${intact_prepro2}/scrubdone_${scrub_criterion}
						else
							MNI152_funclabel="$EPIpreprodir/$session/$run/MNI152/$scrubbing/funclabel/$subject";mkdir -p $MNI152_funclabel
							prepro2="$EPIpreprodir/$session/$run/MNI152/$scrubbing/prepro/$subject";mkdir -p $prepro2
							unsmoothed2="$EPIpreprodir/$session/$run/MNI152/$scrubbing/unsmoothed/$subject";mkdir -p $unsmoothed2
							nuisance="$EPIpreprodir/$session/$run/MNI152/$scrubbing/nuisance/$subject";mkdir -p $nuisance
							motion="$diagnostics/$scrubbing/motion/$subject";mkdir -p ${motion}
							clean="$EPIpreprodir/$session/$run/MNI152/$scrubbing/clean/$subject";mkdir -p $clean
							postscrub_dvars="$diagnostics/$scrubbing/dvars/postscrub/$subject";mkdir -p ${postscrub_dvars}
							final_dvars="$diagnostics/$scrubbing/dvars/${model}_WMlocal${WMlocal}/$subject";mkdir -p ${final_dvars}
							
							if [ ! -f ${prepro2}/scrubdone_${scrub_criterion} ]; then
								echo "Replacing all volumes with ${scrub_criterion} with the mean of the surrounding volumes"
									cp ${intact_prepro2}/${functional}_rdsmffm.nii.gz ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz
									cp ${intact_motion}/motion_predt_prebp.1D ${motion}/motion_predt_prebp_scrubbing.1D
								
								timepoints=`3dinfo ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz 2>&1 | grep time | awk '{print $6}'`
								for num in `awk '/1/{ print NR }' ${scrubindex}/${scrub_criterion}.1D`
								do
									#num and timepoints are order rank, not index-based
									#badin is an index number
									maxindex=`echo $timepoints '-1' | bc`
									badin=`echo $num '- 1' | bc`
									echo $badin >> ${motion}/badins
									if [ $badin == '0' ]; then
										echo 'first timepoint bad, replacing with second timepoint for volume' $badin
										3dTcat -prefix ${prepro2}/${functional}_rdsmffm_scrubbing_temp.nii.gz ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz[1] ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz[1..$maxindex]; mv ${prepro2}/${functional}_rdsmffm_scrubbing_temp.nii.gz ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz
									elif [ $badin == $maxindex ]; then
										echo 'last timepoint bad, replacing with penultimate timepoint for volume' $badin
										penult=`echo $maxindex '-1' | bc`
										echo "penult" $penult
										3dTcat -prefix ${prepro2}/${functional}_rdsmffm_scrubbing_temp.nii.gz ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz[0..$penult] ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz[$penult]; mv ${prepro2}/${functional}_rdsmffm_scrubbing_temp.nii.gz ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz
									else echo 'interpolating timepoint by average of two neighbouring volumes for volume' $badin
										onebefore=`echo $badin '-1' | bc`
										oneafter=`echo $badin '+1' | bc`
										3dMean -prefix ${prepro2}/${functional}_${onebefore}${oneafter}_rdsmffm_scrubbing_mean.nii.gz ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz[$onebefore] ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz[$oneafter]
										3dTcat -prefix ${prepro2}/${functional}_rdsmffm_scrubbing_temp.nii.gz ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz[0..$onebefore] ${prepro2}/${functional}_${onebefore}${oneafter}_rdsmffm_scrubbing_mean.nii.gz ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz[$oneafter..$maxindex]; mv ${prepro2}/${functional}_rdsmffm_scrubbing_temp.nii.gz ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz
									fi
									echo $python $scriptsdir/moscrub.py ${motion}/motion_predt_prebp_scrubbing.1D $badin
									$python $scriptsdir/moscrub.py ${motion}/motion_predt_prebp_scrubbing.1D $badin > ${motion}/motion_predt_prebp_scrubbing_PRE.1D
									sed -e 's/ $//' ${motion}/motion_predt_prebp_scrubbing_PRE.1D > ${motion}/motion_predt_prebp_scrubbing.1D
									echo "changing volume $badin"
									cat ${intact_motion}/motion_predt_prebp.1D | awk 'NR==line' line=$num
									echo "to..."
									cat ${motion}/motion_predt_prebp_scrubbing.1D | awk 'NR==line' line=$num
								done
								echo "1" > ${prepro2}/scrubdone_${scrub_criterion}
								cp ${motion}/motion_predt_prebp_scrubbing.1D ${motion}/motion_predt_prebp.1D
								cp ${prepro2}/${functional}_rdsmffm_scrubbing.nii.gz ${prepro2}/${functional}_rdsmffms_prenorm.nii.gz

									if [ ! -f ${prepro2}/${functional}_rdsmffms.nii.gz ]; then
										dvarspath=${postscrub_dvars}
										fslmaths ${prepro2}/${functional}_rdsmffms_prenorm.nii.gz -mul ${MNI152_prep_labels}/T1_brain_mask_filled.nii.gz ${prepro2}/${functional}_rdsmffms_prenorm_masked.nii.gz
										3dTstat -mean -prefix ${prepro2}/${functional}_rdsmffms_prenorm_mean.nii.gz ${prepro2}/${functional}_rdsmffms_prenorm_masked.nii.gz
										3dBrickStat -mask ${MNI152_prep_labels}/T1_brain_mask_filled.nii.gz -median ${prepro2}/${functional}_rdsmffms_prenorm_mean.nii.gz > ${dvarspath}/gms.1D
										gms=`cat ${dvarspath}/gms.1D`; gmsa=($gms); p50=${gmsa[1]}
										echo "p50" $p50
										3dcalc -a ${prepro2}/${functional}_rdsmffms_prenorm_masked.nii.gz -expr "a*1000/${p50}" -prefix ${prepro2}/${functional}_rdsmffms.nii.gz
									fi
									if [ ! -f ${postscrub_dvars}/mean_sigma_DVARS.1D ]; then
										echo "calculating postscrub DVARS"
										dvarspath=${postscrub_dvars}
										3dcalc -a ${prepro2}/${functional}_rdsmffms.nii.gz -b "a[0,0,0,-1]" -expr "(a - b)^2" -prefix ${dvarspath}/${functional}_rdsmffms_deriv_squared.nii.gz
										fslmeants -i ${dvarspath}/${functional}_rdsmffms_deriv_squared.nii.gz -m ${MNI152_prep_labels}/T1_brain_mask_filled.nii.gz > ${dvarspath}/deriv_squared.1D
										1deval -a  ${dvarspath}/deriv_squared.1D -expr '(sqrt(a))/10'  >  ${dvarspath}/DVARS.1D
										3dmaskave -sigma -quiet ${dvarspath}/DVARS.1D >  ${dvarspath}/mean_sigma_DVARS.1D
										rm ${dvarspath}/${functional}_rdsmffms_deriv_squared.nii.gz
									fi

									dvarspath=${postscrub_dvars}
									if [ ! -f ${dvarspath}/global_signal.1D ]; then
										fslmeants -i ${prepro2}/${functional}_rdsmffms.nii.gz -m ${MNI152_prep_labels}/T1_brain_mask_filled.nii.gz -o ${dvarspath}/global_signal.1D
									fi
							fi #end of scrub
						fi 
					else
						
						MNI152_funclabel="$EPIpreprodir/$session/$run/MNI152/intact/funclabel/$subject";mkdir -p $MNI152_funclabel
						prepro2="$EPIpreprodir/$session/$run/MNI152/intact/prepro/$subject";mkdir -p $prepro2
						unsmoothed2="$EPIpreprodir/$session/$run/MNI152/intact/unsmoothed/$subject";mkdir -p $unsmoothed2
						nuisance="$EPIpreprodir/$session/$run/MNI152/intact/nuisance/$subject";mkdir -p $nuisance
						motion="$diagnostics/intact/motion/$subject";mkdir -p ${motion}
						clean="$EPIpreprodir/$session/$run/MNI152/intact/clean/$subject";mkdir -p $clean
						final_dvars="$diagnostics/intact/dvars/${model}_WMlocal${WMlocal}/$subject";mkdir -p ${final_dvars}

						
						if [ ! -f ${intact_prepro2}/${functional}_rdsmffms.nii.gz ]; then
							echo "No scrubbing"
							cp ${intact_prepro2}/${functional}_rdsmffm.nii.gz ${intact_prepro2}/${functional}_rdsmffms.nii.gz
						fi
					fi

					if [[ $dofilter == "1" ]]; then
						echo "Bandpassing applied - highpass $highpass, lowpass $lowpass" >> $methods
						if [ ! -f ${unsmoothed2}/${functional}_rdsmffmsbd.nii.gz ]; then
							3dFourier -lowpass $lowpass -highpass $highpass -retrend -prefix ${unsmoothed2}/${functional}_rdsmffmsb.nii.gz ${prepro2}/${functional}_rdsmffms.nii.gz
							3dTstat -mean -prefix ${unsmoothed2}/${functional}_rdsmffmsb_mean.nii.gz ${unsmoothed2}/${functional}_rdsmffmsb.nii.gz
							3dDetrend -polort ${polort} -prefix ${unsmoothed2}/${functional}_rdsmffmsbd_demeaned.nii.gz ${unsmoothed2}/${functional}_rdsmffmsb.nii.gz
							fslmaths ${unsmoothed2}/${functional}_rdsmffmsbd_demeaned.nii.gz -add ${unsmoothed2}/${functional}_rdsmffmsb_mean.nii.gz ${unsmoothed2}/${functional}_rdsmffmsbd.nii.gz
						fi
					else
						cp ${prepro2}/${functional}_rdsmffms.nii.gz ${unsmoothed2}/${functional}_rdsmffmsbd.nii.gz
					fi


					if [ ! -f ${MNI152_funclabel}/G.nii.gz ]; then
						fslmaths ${intact_prepro2}/${functional}_rdsmff_mean.nii.gz -bin ${MNI152_funclabel}/${functional}_rdsmff_mean_mask.nii.gz
						3dcalc -a ${MNI152_prep_labels}/WM_ero_1mm.nii.gz -b ${MNI152_funclabel}/${functional}_rdsmff_mean_mask.nii.gz -expr 'ispositive(b)*ispositive(a-0.50)' -prefix ${MNI152_funclabel}/WM_ero_1mm.nii.gz
						3dcalc -a ${MNI152_prep_labels}/WM_ero_2mm.nii.gz -b ${MNI152_funclabel}/${functional}_rdsmff_mean_mask.nii.gz -expr 'ispositive(b)*ispositive(a-0.50)' -prefix ${MNI152_funclabel}/WM.nii.gz
						3dcalc -a ${MNI152_RS_labels}/DV.nii.gz -b ${MNI152_funclabel}/${functional}_rdsmff_mean_mask.nii.gz -expr 'ispositive(b)*ispositive(a-0.50)' -prefix ${MNI152_funclabel}/DV.nii.gz
						3dcalc -a ${MNI152_RS_labels}/V.nii.gz -b ${MNI152_funclabel}/${functional}_rdsmff_mean_mask.nii.gz -expr 'ispositive(b)*ispositive(a-0.50)' -prefix ${MNI152_funclabel}/V.nii.gz
						3dcalc -a ${MNI152_RS_labels}/G.nii.gz -b ${MNI152_funclabel}/${functional}_rdsmff_mean_mask.nii.gz -expr 'ispositive(b)*ispositive(a-0.50)' -prefix ${MNI152_funclabel}/G.nii.gz
					fi


					if [[ $WMlocal == '1' && ! -f ${MNI152_funclabel}/WMlocal1_25.nii.gz ]]; then 
						3dresample -input ${MNI152_funclabel}/WM.nii.gz -prefix ${MNI152_funclabel}/WM_3mm.nii.gz -rmode NN -dxyz 3 3 3
						3dresample -input ${unsmoothed2}/${functional}_rdsmffmsbd.nii.gz -prefix ${unsmoothed2}/${functional}_rdsmffmsbd_3mm.nii.gz -rmode Linear -dxyz 3 3 3
						3dLocalstat -prefix ${MNI152_funclabel}/WMlocal1_25_3mm.nii.gz -nbhd 'SPHERE(25)' -stat mean -mask ${MNI152_funclabel}/WM_3mm.nii.gz -use_nonmask ${unsmoothed2}/${functional}_rdsmffmsbd_3mm.nii.gz
						3dresample -input ${MNI152_funclabel}/WMlocal1_25_3mm.nii.gz -prefix ${MNI152_funclabel}/WMlocal1_25.nii.gz -rmode Linear -dxyz 2 2 2
					elif [[ $WMlocal == '2' && ! -f ${MNI152_funclabel}/WMlocal2_25.nii.gz ]]; then
						3dLocalstat -prefix ${MNI152_funclabel}/WMlocal2_25.nii.gz -nbhd 'SPHERE(25)' -stat mean -mask ${MNI152_funclabel}/WM.nii.gz -use_nonmask ${unsmoothed2}/${functional}_rdsmffmsbd.nii.gz
					fi


					if [ ! -f ${motion}/motion_dt_bp.1D ]; then
						if [[ $dofilter == "1" ]]; then	
							for mc in 1 2 3 4 5 6
							do
								if [ ! -f ${motion}/motion_mc${mc}_dt_bp.1D ]; then
									awk -v col=$mc '{print $col}' ${motion}/motion_predt_prebp.1D > ${motion}/motion_mc${mc}_predt_prebp.1D
									echo "1"
									$python $scriptsdir/1d.py ${motion}/motion_mc${mc}_predt_prebp.1D
									echo "2"
									3drefit -TR $TR ${motion}/motion_mc${mc}_predt_prebp.1D.nii.gz
									echo "3"								
									3dFourier -retrend -prefix ${motion}/motion_mc${mc}_predt_bp.1D.nii.gz -lowpass $lowpass -highpass $highpass ${motion}/motion_mc${mc}_predt_prebp.1D.nii.gz
									echo "4"
									3dDetrend -polort ${polortM} -prefix ${motion}/motion_mc${mc}_dt_bp.1D.nii.gz ${motion}/motion_mc${mc}_predt_bp.1D.nii.gz
									echo "5"
									3dmaskave -quiet ${motion}/motion_mc${mc}_dt_bp.1D.nii.gz > ${motion}/motion_mc${mc}_dt_bp.1D
									echo "6"
								fi
							done
							paste -d " " ${motion}/motion_mc1_dt_bp.1D ${motion}/motion_mc2_dt_bp.1D ${motion}/motion_mc3_dt_bp.1D ${motion}/motion_mc4_dt_bp.1D ${motion}/motion_mc5_dt_bp.1D ${motion}/motion_mc6_dt_bp.1D > ${motion}/motion_dt_bp.1D 
							#rm ${motion}/motion_mc*.nii.gz
						else
							cp ${motion}/motion_predt_prebp.1D ${motion}/motion_dt_bp.1D
						fi
						echo "calculating motion derivative"
						1d_tool.py -infile ${motion}/motion_dt_bp.1D -derivative -write ${motion}/motion_dt_bp_deriv.1D
					fi

					if [ ! -f ${nuisance}/M_V_DV.1D ]; then
						for mask in WM DV V G
						do
							3dmaskave -mask ${MNI152_funclabel}/${mask}.nii.gz -quiet ${unsmoothed2}/${functional}_rdsmffmsbd.nii.gz > ${nuisance}/${mask}.1D
						done
						paste -d " " $motion/motion_dt_bp.1D > ${nuisance}/M.1D
						paste -d " " $motion/motion_dt_bp.1D ${nuisance}/V.1D > ${nuisance}/M_V.1D
						paste -d " " ${nuisance}/V.1D ${nuisance}/DV.1D > ${nuisance}/V_DV.1D
						paste -d " " $motion/motion_dt_bp.1D ${nuisance}/V.1D ${nuisance}/DV.1D > ${nuisance}/M_V_DV.1D
						paste -d " " $motion/motion_dt_bp.1D ${nuisance}/V.1D ${nuisance}/DV.1D ${nuisance}/WM.1D > ${nuisance}/M_V_DV_WM.1D
						paste -d " " $motion/motion_dt_bp_deriv.1D ${nuisance}/V.1D ${nuisance}/DV.1D > ${nuisance}/MD_V_DV.1D #with motion derivative instead of motion

						paste -d " " $motion/motion_dt_bp_deriv.1D > ${nuisance}/MD.1D #with motion derivative instead of motion
						paste -d " " $motion/motion_dt_bp_deriv.1D ${nuisance}/V.1D ${nuisance}/DV.1D ${nuisance}/WM.1D > ${nuisance}/MD_V_DV_WM.1D

						#Use noise regressors from other ROIs - hard coded
						#paste -d " " $motion/motion_dt_bp_deriv.1D ${nuisance}/V.1D ${nuisance}/DV.1D /Users/lr912/analysis/data/PSILO/FEAT/RS_NOhighpass_motionDeriv_noDetrend/FD_040/$session/2nd_half_3min/$subject/ISC_PSILO_topDV/EV/txt/ISC_PSILO_topDV.txt /Users/lr912/analysis/data/PSILO/FEAT/RS_NOhighpass_motionDeriv_noDetrend/FD_040/$session/2nd_half_3min/$subject/ISC_PSILO_midCSF/EV/txt/ISC_PSILO_midCSF.txt > ${nuisance}/MD_V_DV_Ex.1D #with motion derivative instead of motion

						#For DMT rating, add hard coded regressor for giving ratings
						paste -d " " $motion/motion_dt_bp_deriv.1D ${nuisance}/V.1D ${nuisance}/DV.1D /Users/lr912/analysis/data/DMT/preprocessing/rating_regressor.txt > ${nuisance}/MD_V_DV_ratReg.1D #with motion derivative instead of motion


					fi

					if [ ! -f $prepro2/${functional}_rdsmffms${FWHM}FWHM.nii.gz ]; then
						if [[ "$FWHM" == 0 ]]; then
							cp $prepro2/${functional}_rdsmffms.nii.gz $prepro2/${functional}_rdsmffms${FWHM}FWHM.nii.gz
						else
							pushd ${prepro2}
							a="`fslstats ${functional}_rdsmffms.nii.gz -p 2 -p 98`"
							thrA=$(printf %.7f $(echo "scale=8;(`echo $a | awk '{ print $2 }'` / 10)" | bc))
							fslmaths ${functional}_rdsmffms.nii.gz -thr $thrA -Tmin -bin mask_pre_dilF.nii.gz -odt char
							bt_pre=`fslstats ${functional}_rdsmffms.nii.gz -k mask_pre_dilF -p 50`
							bt=$(printf %.8f $(echo "scale=9;(${bt_pre} * 0.75)" | bc))
							fslmaths mask_pre_dilF.nii.gz -dilF mask_dilF.nii.gz
							3dmask_tool -input $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz -prefix MNI152_T1_2mm_brain_mask_filled.nii.gz -fill_holes
							3dcalc -a mask_dilF.nii.gz -b MNI152_T1_2mm_brain_mask_filled.nii.gz -expr 'a*b' -prefix mask_pretight.nii.gz
							3dcalc -a ${functional}_rdsmffms.nii.gz[0] -b mask_pretight.nii.gz -expr 'ispositive(a)*b' -prefix mask_tight.nii.gz
							3dBlurInMask -input ${functional}_rdsmffms.nii.gz -prefix ${functional}_rdsmffms${FWHM}FWHM.nii.gz -FWHM ${FWHM} -mask mask_tight.nii.gz
							popd
						fi
					fi

					if [ ! -f ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd.nii.gz ];then 
						if [[ $dofilter == "1" ]]; then
							3dFourier -lowpass $lowpass -highpass $highpass -retrend -prefix ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_b.nii.gz ${prepro2}/${functional}_rdsmffms${FWHM}FWHM.nii.gz
							3dTstat -mean -prefix ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_b_mean.nii.gz ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_b.nii.gz
							3dDetrend -polort ${polort} -prefix ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd_demeaned.nii.gz ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_b.nii.gz
							3dcalc -a ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd_demeaned.nii.gz -b ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_b_mean.nii.gz -expr 'a+b' -prefix ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd.nii.gz
						else
							cp ${prepro2}/${functional}_rdsmffms${FWHM}FWHM.nii.gz ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_b.nii.gz
							3dTstat -mean -prefix ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_b_mean.nii.gz ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_b.nii.gz
							cp ${prepro2}/${functional}_rdsmffms${FWHM}FWHM.nii.gz ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd.nii.gz
						fi
					fi

					for model in ${model}
					do
						if [[ ${WMlocal} == '1' || ${WMlocal} == '2' ]]; then
							if [ ! -f ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}.nii.gz ]; then
								echo "3dBandpass removing $model and local_WM_regressor"
								3dBandpass -prefix ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_demeaned.nii.gz -dsort ${MNI152_funclabel}/WMlocal${WMlocal}_25.nii.gz  -ort ${nuisance}/${model}.1D 0 99999 ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd.nii.gz
								fslmaths ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_demeaned.nii.gz -add ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_b_mean.nii.gz ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}.nii.gz
							fi
						else
							if [ ! -f ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}.nii.gz ]; then 
								if [[ ! $model == "noRegress" ]]; then
									echo "3dBandpass removing $model"
									3dBandpass -prefix ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_demeaned.nii.gz -ort ${nuisance}/${model}.1D 0 99999 ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd.nii.gz
									fslmaths ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_demeaned.nii.gz -add ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_b_mean.nii.gz ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}.nii.gz
								else
									echo "no nuisance model was regressed out "
									cp ${prepro2}/${functional}_rdsmffms${FWHM}FWHM_bd.nii.gz ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}.nii.gz
								fi
							fi
						fi
					done

					for model in ${model}
					do
						dvarspath=${final_dvars}
						if [ ! -f ${dvarspath}/mean_sigma_DVARS.1D ]; then 
							3dTstat -mean -prefix ${prepro2}/${functional}_final_mean.nii.gz ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}.nii.gz
							3dBrickStat -mask ${MNI152_prep_labels}/T1_brain_mask_filled.nii.gz -median ${prepro2}/${functional}_final_mean.nii.gz > ${dvarspath}/gms_FINAL.1D
							gms_FINAL=`cat ${dvarspath}/gms_FINAL.1D`; gmsa_FINAL=($gms_FINAL); p50_FINAL=${gmsa_FINAL[1]}
							echo "p50" $p50_FINAL
							3dcalc -a ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}.nii.gz -expr "a*1000/${p50_FINAL}" -prefix ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz
							echo "calculating final DVARS"
							3dcalc -a ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz -b "a[0,0,0,-1]" -expr "(a - b)^2" -prefix ${dvarspath}/${functional}_rsmffm_deriv_squared.nii.gz
							fslmeants -i ${dvarspath}/${functional}_rsmffm_deriv_squared.nii.gz -m ${MNI152_prep_labels}/T1_brain_mask_filled.nii.gz > ${dvarspath}/deriv_squared.1D
							1deval -a  ${dvarspath}/deriv_squared.1D -expr '(sqrt(a))/10'  >  ${dvarspath}/DVARS.1D
							3dmaskave -sigma -quiet ${dvarspath}/DVARS.1D >  ${dvarspath}/mean_sigma_DVARS.1D
							rm  ${dvarspath}/${functional}_rsmffm_deriv_squared.nii.gz
						fi

						dvarspath=${final_dvars}
						if [ ! -f ${dvarspath}/global_signal.1D ]; then
							fslmeants -i ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz -m ${MNI152_prep_labels}/T1_brain_mask_filled.nii.gz -o ${dvarspath}/global_signal.1D
						fi
					done

					#for model in ${model}
					#do
					#	MNI152_funclabel="$EPIpreprodir/$session/$run/MNI152/intact/funclabel/$subject"
					#	clean="$EPIpreprodir/$session/$run/MNI152/intact/clean/$subject"
					#	if [ ! -f ${MNI152_funclabel}/cloud_funcmask_${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz ]; then
					#		stdev=`fslstats ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz -s`
					#		half_stdev=`bc <<< "scale = 5;(($stdev / 3))"`
					#		echo "thresholding image at third of stdev ($half_stdev) and binarising to create cloud_funcmask"
					#		fslmaths ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz -thr $half_stdev -bin ${MNI152_funclabel}/cloud_funcmask_PRE_${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}.nii.gz
					#		fslmaths ${MNI152_funclabel}/cloud_funcmask_PRE_${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}.nii.gz -Tmin ${MNI152_funclabel}/cloud_funcmask_${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz
					#	fi
					#done


					#MNI152_funclabel="$EPIpreprodir/$session/$run/MNI152/intact/funclabel/$subject"
					#clean="$EPIpreprodir/$session/$run/MNI152/intact/clean/$subject"
					#if [ ! -f ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr_mean.nii.gz ]; then
					#	echo "FINAL mean for subject $subject"
					#	3dTstat -mean -prefix ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr_mean.nii.gz ${clean}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz
					#fi


					##To combine scrubbed and intact in the same folder
					if [[ $scrub == "1" ]]; then
						MNI_dir="$EPIpreprodir/$session/$run/MNI152"
						clean_with_intact_dir="$MNI_dir/$scrubbing/clean_with_intact/$subject"; mkdir -p $clean_with_intact_dir
						clean_with_intact_mean_dir="$MNI_dir/$scrubbing/clean_with_intact_mean"; mkdir -p $clean_with_intact_mean_dir 
						clean_intact_dir="$MNI_dir/intact/clean/$subject"
						clean_scrub_dir="$MNI_dir/$scrubbing/clean/$subject"

						if [ ! -f $clean_with_intact_dir/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz ]; then 
							if [ -f ${clean_scrub_dir}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz ]; then
								echo "moving scrubbed, $session $run $subject"
								cp ${clean_scrub_dir}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz $clean_with_intact_dir/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz
							elif [ -f ${clean_intact_dir}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz ]; then
								echo "moving intact, $session $run $subject"
								cp ${clean_intact_dir}/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz $clean_with_intact_dir/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz
							else
								echo "something is wrong"
								exit
							fi
						fi	
						#create mean functional nifti
						if [ ! -f $clean_with_intact_mean_dir/${subject}_${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr_mean.nii.gz ]; then
							fslmaths $clean_with_intact_dir/${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr.nii.gz -Tmean $clean_with_intact_mean_dir/${subject}_${functional}_rdsmffms${FWHM}FWHM_bd_${model}_WMlocal${WMlocal}_modecorr_mean.nii.gz
						fi
					fi

					##To combine nuisance scrubbed and intact in the same folder
					if [[ $scrub == "1" ]]; then
						MNI_dir="$EPIpreprodir/$session/$run/MNI152"
						nuisance_with_intact_dir="$MNI_dir/$scrubbing/nuisance_with_intact/$subject"; mkdir -p $nuisance_with_intact_dir
						nuisance_intact_dir="$MNI_dir/intact/nuisance/$subject"
						nuisance_scrub_dir="$MNI_dir/$scrubbing/nuisance/$subject"
						if [ ! -f ${nuisance_with_intact_dir}/DV.1D ]; then
							if [ -f ${nuisance_scrub_dir}/DV.1D ]; then
								echo "moving scrubbed, $session $run $subject"
								cp ${nuisance_scrub_dir}/*.1D $nuisance_with_intact_dir
							elif [ -f ${nuisance_intact_dir}/DV.1D ]; then
								echo "moving intact, $session $run $subject"
								cp ${nuisance_intact_dir}/*.1D $nuisance_with_intact_dir
							fi
						fi
					fi

				 # continue from here if finished_subjects=2  (add "else" if needed)
				fi


				echo "path at end of susan:"
				pwd
				echo "================================================================================================================================="
				echo ""
				duration=$(( SECONDS - start ))
				minutes=$(( duration / 60 ))
				echo "functional preprocessing took ~${minutes} minutes for $subject"
				echo ""
				echo "================================================================================================================================="
			done
		done
	done
fi




