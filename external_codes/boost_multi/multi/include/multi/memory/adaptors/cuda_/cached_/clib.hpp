// -*-indent-tabs-mode:t;c-basic-offset:4;tab-width:4;autowrap:nil;-*-
// Copyright 2019-2022 Alfredo A. Correa

#ifndef MULTI_MEMORY_ADAPTOR_CUDA_CACHED_CLIB_HPP_
#define MULTI_MEMORY_ADAPTOR_CUDA_CACHED_CLIB_HPP_

#include<cuda_runtime.h> // cudaMallocCached

#include "../../../adaptors/cuda/clib.hpp" // Cuda::free
#include "../../../adaptors/cuda/error.hpp"

namespace Cuda {
	namespace Cached {
		inline error Malloc(void** p, size_t bytes){return static_cast<error>(cudaMallocManaged(p, bytes/*, cudaMemAttachGlobal*/));}
		inline void* malloc(size_t bytes){
			void* ret;
			switch(auto e = Malloc(&ret, bytes)){
				case success           : return ret;
				case memory_allocation : return nullptr;
				default                : 
					throw std::system_error{e, "cannot allocate "+std::to_string(bytes)+" bytes in '"+__PRETTY_FUNCTION__+"'"};
			}
		}
		inline void free(void* p){return Cuda::free(p);}
	}
}


//#ifdef _TEST_MULTI_MEMORY_ADAPTOR_CUDA_CACHED_MALLOC

//#include "../../cuda/cached/ptr.hpp"

//#include<iostream>

//namespace multi = boost::multi;
//namespace cuda = multi::memory::cuda;

//using std::cout;

//int main(){
//	void* p = Cuda::Cached::malloc(100);
//	Cuda::Cached::free(p);
//}
//#endif
#endif  // MULTI_MEMORY_ADAPTOR_CUDA_CACHED_CLIB_HPP_
