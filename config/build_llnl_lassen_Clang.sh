#!/bin/bash
# This recipe is intended for OLCF Summit https://www.olcf.ornl.gov/summit/
# It builds all the varaints of QMCPACK in the current directory
# last revision: Aug 29th 2022
#
# How to invoke this script?
# build_olcf_summit_Clang.sh # build all the variants assuming the current directory is the source directory.
# build_olcf_summit_Clang.sh <source_dir> # build all the variants with a given source directory <source_dir>
# build_alcf_polaris_Clang.sh <source_dir> <install_dir> # build all the variants with a given source directory <source_dir> and install to <install_dir>

echo "Loading QMCPACK dependency modules for summit"
module load git
module load cuda/11.8.0
module load essl
module load lapack
spack load hdf5
module load fftw
module load boost/1.70.0
module load cmake/3.23.1
module load gcc/12.2.1
echo $PATH
module list >& module_list.txt

TYPE=Release
Machine=lassen
Compiler=gcc12

if [[ $# -eq 0 ]]; then
  source_folder=`pwd`
elif [[ $# -eq 1 ]]; then
  source_folder=$1
else
  source_folder=$1
  install_folder=$2
fi

if [[ -f $source_folder/CMakeLists.txt ]]; then
  echo Using QMCPACK source directory $source_folder
else
  echo "Source directory $source_folder doesn't contain CMakeLists.txt. Pass QMCPACK source directory as the first argument."
  exit
fi

for name in offload_cuda_real_MP offload_cuda_real offload_cuda_cplx_MP offload_cuda_cplx \
            cpu_real_MP cpu_real cpu_cplx_MP cpu_cplx
do

CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=$TYPE -DCMAKE_LIBRARY_PATH=/usr/tce/packages/spectrum-mpi/spectrum-mpi-rolling-release-xl-2023.03.13/lib  -DQMC_MATH_VENDOR=IBM_MASS -DMASS_ROOT=/opt/ibm/xlmass/9.1.1 -DMPIEXEC_EXECUTABLE=`which jsrun` -DMPIEXEC_NUMPROC_FLAG='-n' -DMPIEXEC_PREFLAGS='-c;16;-g;1;-b;packed:16;--smpiargs=off'"

if [[ $name == *"cplx"* ]]; then
  CMAKE_FLAGS="$CMAKE_FLAGS -DQMC_COMPLEX=ON"
fi

if [[ $name == *"_MP"* ]]; then
  CMAKE_FLAGS="$CMAKE_FLAGS -DQMC_MIXED_PRECISION=ON"
fi

if [[ $name == *"offload"* ]]; then
  CMAKE_FLAGS="$CMAKE_FLAGS -DENABLE_OFFLOAD=ON -DOFFLOAD_ARCH=sm_70"
fi

if [[ $name == *"cuda"* ]]; then
  CMAKE_FLAGS="$CMAKE_FLAGS -DENABLE_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=70"
fi

folder=build_${Machine}_${Compiler}_${name}

if [[ -v install_folder ]]; then
  CMAKE_FLAGS="$CMAKE_FLAGS -DCMAKE_INSTALL_PREFIX=$install_folder/$folder"
fi

echo "**********************************"
echo "$folder"
echo "$CMAKE_FLAGS"
echo "**********************************"

mkdir $folder
cd $folder

if [ ! -f CMakeCache.txt ] ; then
  cmake $CMAKE_FLAGS -DCMAKE_C_COMPILER=/usr/tce/packages/spectrum-mpi/spectrum-mpi-rolling-release-gcc-12.2.1/bin/mpicc	 -DCMAKE_CXX_COMPILER=/usr/tce/packages/spectrum-mpi/spectrum-mpi-rolling-release-gcc-12.2.1/bin/mpicxx $source_folder
fi

if [[ -v install_folder ]]; then
  make -j16 install && chmod -R -w $install_folder/$folder
else
  make -j16
fi

cd ..

echo
done
