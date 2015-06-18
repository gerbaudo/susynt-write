#!/bin/sh

# Script to setup an area where we compile the packages needed to run NtMaker
#
# Requirements:
# - access to the svn.cern.ch repositories
# - have 'setupATLAS' defined
# - have access to github
#
# davide.gerbaudo@gmail.com, Mar 2013


readonly SCRIPT_NAME=$(basename $0)
# see http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
readonly PROG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly PROD_DIR="${PROG_DIR}/../" # 'production' dir, where we checkout all of the packages

function print_usage {
    echo "Usage:"
    echo "setup_area.sh [--stable] [--help]"
    echo " --stable: checkout the latest stable packages, for production"
    echo "           (by default checkout the development branch)"
    echo " --help:   print this message"
}

function require_root {
    : ${ROOTSYS:?"Need to set up root."}
}
function echoerr() { echo "$@" 1>&2; }
function missing_kerberos {
    local missing_kerberos_ticket=$(klist 2>&1 | grep -c "No credentials cache found")
    if [[ "${missing_kerberos_ticket}" -eq "0" ]]
    then
        echo "missing kerberos ticket"
        return 1
    else
        return 0
    fi
}

function prepare_directories {
    cd ${PROD_DIR}
    mkdir -p ${PROD_DIR}/susynt_xaod_timing
}

function checkout_packages_external {
    local SVNOFF="svn+ssh://svn.cern.ch/reps/atlasoff/"
    local SVNPHYS="svn+ssh://svn.cern.ch/reps/atlasphys/"
    local SVNWEAK="svn+ssh://svn.cern.ch/reps/atlasphys/Physics/SUSY/Analyses/WeakProduction/"

    cd ${PROD_DIR}

    # base 2.3.14
    svn co ${SVNOFF}/PhysicsAnalysis/SUSYPhys/SUSYTools/tags/SUSYTools-00-06-10 SUSYTools
    
    # Additional packages needed on top of Base,2.3.14 (will not be needed for a future AnalysisBase/AnalysisSUSY release
    svn co ${SVNOFF}/Reconstruction/MET/METUtilities/tags/METUtilities-00-01-40 METUtilities

    # TrigEgammaMatchingTool
    svn co ${SVNOFF}/Trigger/TrigAnalysis/TrigEgammaMatchingTool/tags/TrigEgammaMatchingTool-00-00-03 TrigEgammaMatchingTool

    # SusyNtuple dependencies
    svn co ${SVNWEAK}/Mt2/tags/Mt2-00-00-01                                       Mt2
    svn co ${SVNWEAK}/TriggerMatch/tags/TriggerMatch-00-00-10                     TriggerMatch
    svn co ${SVNWEAK}/DGTriggerReweight/tags/DGTriggerReweight-00-00-29           DGTriggerReweight
    svn co ${SVNWEAK}/LeptonTruthTools/tags/LeptonTruthTools-00-01-07             LeptonTruthTools
    svn co ${SVNOFF}/Reconstruction/Jet/JetAnalysisTools/JVFUncertaintyTool/tags/JVFUncertaintyTool-00-00-04  JVFUncertaintyTool

    #todo : check that all packages are actually there
}

function checkout_packages_uci {
    local dev_or_stable="$1" # whether we should checkout the dev branch or the latest production tags
    cd ${PROD_DIR}
    git clone git@github.com:gerbaudo/SusyNtuple.git SusyNtuple
    cd SusyNtuple
    git checkout -b mc15 origin/mc15
   # if [ "${dev_or_stable}" = "--stable" ]
   # then
   #     git checkout SusyNtuple-00-02-02
   # else
   #     git checkout -b mc15 origin/mc15
   # fi
    cd -
    git clone git@github.com:gerbaudo/SusyCommon.git SusyCommon
    cd SusyCommon
    git checkout -b mc15 origin/mc15
   # if [ "${dev_or_stable}" = "--stable" ]
   # then
   #     git checkout SusyCommon-00-02-02
   # else
   #     git checkout -b xaod origin/xaod
   # fi
    cd -
}

function main {
    if [ $# -ge 2 ]; then
        print_usage
        return
    elif [ $# -eq 1 ] && [ "$1" == "--help" ]; then
        print_usage
        return
    fi
    echo "Starting                          -- `date`"
    # todo: sanity/env checks (probably better off in python)
    # if missing_kerberos
    # then
    #     echo "cannot continue"
    #     return 1
    # else
    #     echo "checkout and compile"
    # fi
    prepare_directories
    checkout_packages_external
    checkout_packages_uci $*
    echo "Done                              -- `date`"
    echo "You can now go ahead and compile with:"
    echo "rc find_packages"
    echo "rc compile 2>&1 | tee compile.log"
}

main $*
