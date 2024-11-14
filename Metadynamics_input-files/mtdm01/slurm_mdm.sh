#!/bin/bash
#SBATCH --job-name=metadynamics
#SBATCH --output=logfile.metadynamics.%A.log
#SBATCH --partition=GPU
#SBATCH --nodes=1
#SBATCH --tasks-per-node=40
#SBATCH --mem=300G
#SBATCH --gres=gpu:3

module load NAMD/2.14_cuda


export SLURM_SUBMIT_DIR=~/MTD_GA1-TCmplx/mtdm01
export RESULTS_DIR=$SLURM_SUBMIT_DIR/results

export OUTPUT_NAME=mtdm01

export PARAMETERSDIR=~/toppar
export DATADIR=~/MTD_GA1-TCmplx/buildsystem/

export INIT_DATADIR=~/MTD_GA1-TCmplx/equilibrate10/eq10
export INIT_COLVARS_NAME=""

export WORKDIR=/tmp/pmhernandez/$OUTPUT_NAME

export FIRSTTIMESTEP=153789000
export ENDTIMESTEP=2147483640
export DELTASTEPS=20000000



#########################################################################
#########################################################################


mkdir -p $WORKDIR; 
##cp * $WORKDIR
cp *.conf $WORKDIR
cp *.sh $WORKDIR
cd $WORKDIR


if [[ -e $WORKDIR/start_parms.sh ]]; then
    source start_parms.sh
fi

echo $SLURM_JOB_ID > SLURM_JOB_ID.txt

export NUMSTEPS=$ENDTIMESTEP

while true; do
	NUMSTEPS=$((FIRSTTIMESTEP + DELTASTEPS))
	if ((NUMSTEPS > ENDTIMESTEP)); then
		break
	fi

###	namd2 +p 40  +setcpuaffinity +isomalloc_sync +idlepoll +devices 0,1,2 ${OUTPUT_NAME}.conf > {$OUTPUT_NAME}.log

        if ! namd2 +p 40  +setcpuaffinity +isomalloc_sync +idlepoll +devices 0,1,2 ${OUTPUT_NAME}.conf > ${OUTPUT_NAME}.log; then
            break;
        fi

	RESULTS_PARTIAL=$RESULTS_DIR/${FIRSTTIMESTEP}_${NUMSTEPS}
	mkdir -p $RESULTS_PARTIAL
	cp -r * $RESULTS_PARTIAL

        for archivo in $(ls | grep -v ".conf" | grep -v ".sh"); do
            rm $archivo
        done

	FIRSTTIMESTEP=$NUMSTEPS
	INIT_DATADIR=$RESULTS_PARTIAL/$OUTPUT_NAME
	INIT_COLVARS_NAME=$OUTPUT_NAME


        echo "export INIT_DATADIR=$INIT_DATADIR" > start_parms.sh
        echo "export INIT_COLVARS_NAME=$OUTPUT_NAME" >> start_parms.sh
        echo "export FIRSTTIMESTEP=$NUMSTEPS" >> start_parms.sh

        cp start_parms.sh $RESULTS_PARTIAL
done
