echo "environment variables "

if [ -d "../build_scripts" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi


if [ -z $EDA_SRC ]; then
    export EDA_SRC=$(pwd)/src
fi
echo "EDA_SRC $EDA_SRC"

if [ -z $ACT_HOME ]; then
    export ACT_HOME=/opt/act
fi
echo "ACT_HOME $ACT_HOME"

if [ -z $ARCH_LEVEL ]; then
    export ARCH_LEVEL=x86-64-v3
fi
echo "ARCH_LEVEL $ARCH_LEVEL"

# baseline kernel/glibc ABI this image targets, used to pick frozen vs. current deps
if [ -z $ABI_LEVEL ]; then
    export ABI_LEVEL=5.14
fi
echo "ABI_LEVEL $ABI_LEVEL"

# guard: re-sourcing runs twice per job, don't stack PATH/flags
if [ -z $ACTFLOW_ENV_LOADED ]; then
    export PATH=${ACT_HOME}/bin:${PATH}
    # explicit -O3/-fPIC: CFLAGS overrides each tool's own default optimization/PIC flags
    export CFLAGS="-march=${ARCH_LEVEL} -O3 -fPIC ${CFLAGS}"
    export CXXFLAGS="-march=${ARCH_LEVEL} -O3 -fPIC ${CXXFLAGS}"
    export FFLAGS="-march=${ARCH_LEVEL} -O3 -fPIC ${FFLAGS}"
    export FCFLAGS="-march=${ARCH_LEVEL} -O3 -fPIC ${FCFLAGS}"
    export ACTFLOW_ENV_LOADED=1
fi

echo "loaded"
