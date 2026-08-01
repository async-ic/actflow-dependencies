echo "environment variables "
source scl_source enable devtoolset-11 || echo "devtoolset11"
echo "devtoolset-11 active"

if [ -d "../build_scripts" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi


if [ -z $EDA_SRC ]; then
    export EDA_SRC=$(pwd)/src
fi
echo "EDA_SRC $EDA_SRC"

if [ -z $ACT_HOME ]; then
    export ACT_HOME=/opt/act
fi
echo "ACT_HOME $ACT_HOME"

# gcc16 (from 007) must stay ahead in PATH, else deps build old-abi. no dup stacking.
case ":${PATH}:" in
    ":${ACT_HOME}/bin:"*) ;;
    *) export PATH="${ACT_HOME}/bin:${PATH}" ;;
esac

if [ -z $ARCH_LEVEL ]; then
    export ARCH_LEVEL=x86-64-v2
fi
echo "ARCH_LEVEL $ARCH_LEVEL"

# baseline kernel/glibc ABI this image targets, used to pick frozen vs. current deps
if [ -z $ABI_LEVEL ]; then
    export ABI_LEVEL=3.10
fi
echo "ABI_LEVEL $ABI_LEVEL"

# guard: re-sourcing runs twice per job, don't stack flags (PATH handled above)
if [ -z $ACTFLOW_ENV_LOADED ]; then
    # explicit -O3/-fPIC: CFLAGS overrides each tool's own default optimization/PIC flags
    export CFLAGS="-march=${ARCH_LEVEL} -O3 -fPIC ${CFLAGS}"
    export CXXFLAGS="-march=${ARCH_LEVEL} -O3 -fPIC ${CXXFLAGS}"
    export FFLAGS="-march=${ARCH_LEVEL} -O3 -fPIC ${FFLAGS}"
    export FCFLAGS="-march=${ARCH_LEVEL} -O3 -fPIC ${FCFLAGS}"
    export ACTFLOW_ENV_LOADED=1
fi

echo "loaded"
