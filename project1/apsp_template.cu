//to compile: nvcc  apsp_template.cu  -I /usr/local/cuda/samples/common/inc/ -o apsp
//to run (e.g.): ./apsp 

#include <cassert>
#include <stdio.h>
#include <map>
#include <algorithm>
#include <fstream>
#include <math.h>
#include <cuda.h>
#include <helper_cuda.h>
#define TILE_WIDTH 16
static void HandleError( cudaError_t err,
                         const char *file,
                         int line ) {
    if (err != cudaSuccess) {
        printf( "%s in %s at line %d\n", cudaGetErrorString( err ),
                file, line );
        exit( EXIT_FAILURE );
    }
}
#define HANDLE_ERROR( err ) (HandleError( err, __FILE__, __LINE__ ))

class cuda_timer
{
private:
	cudaEvent_t start;
	cudaEvent_t end;
	cudaStream_t s;
	cudaError_t error;
public:	
	cuda_timer(cudaStream_t _s):s(_s)
	{
	    error =cudaEventCreate(&start); 
	    assert(error==cudaSuccess);
	    error =cudaEventCreate(&end);
	    assert(error==cudaSuccess);
	    error = cudaEventRecord(start,s);
	    assert(error==cudaSuccess);
	}

	float display()
	{
	    float elapsed_time;
	    error=cudaEventRecord(end, s);
	    assert(error==cudaSuccess);
	    error=cudaEventSynchronize(end);
	    assert(error==cudaSuccess);
	    error=cudaEventElapsedTime(&elapsed_time, start, end);
	    assert(error==cudaSuccess);
	    return elapsed_time;
	  }
	  ~cuda_timer()
	  {

	     cudaEventDestroy( end );	  
	  }
};

__global__ void InitMatrixKernel(float* Md, float val,int size)
{
    int tidx = threadIdx.x + blockDim.x * blockIdx.x;
    int stride = blockDim.x * gridDim.x;
    for(; tidx < size; tidx += stride)
        Md[tidx] = val;	
}


__global__ void MatrixMulKernel(float* Md, float* Nd, float* Pd, int Width)
{
	__shared__ float Mds[TILE_WIDTH][TILE_WIDTH];
	__shared__ float Nds[TILE_WIDTH][TILE_WIDTH];

	int bx = blockIdx.x;  int by = blockIdx.y;
	int tx = threadIdx.x; int ty = threadIdx.y;

	// Identify the row and column of the Pd element to work on
	int Row = by * TILE_WIDTH + ty;
	int Col = bx * TILE_WIDTH + tx;

	float Pvalue = Pd[Row*Width + Col];
	// Loop over the Md and Nd tiles required to compute the Pd element
	for (int m = 0; m < Width / TILE_WIDTH; ++m)
	{	
		Mds[ty][tx] = Md[Row * Width + (m*TILE_WIDTH + tx)];
		Nds[ty][tx] = Nd[Col + (m*TILE_WIDTH + ty) * Width];
		__syncthreads();
		// Coolaborative loading of Md and Nd tiles into shared memory
		for (int k = 0; k < TILE_WIDTH; ++k)
		{
			if (Pvalue > Mds[ty][k] + Nds[k][tx])
				Pvalue = Mds[ty][k] + Nds[k][tx];
		}

		
		// your code for task2 goes here
		__syncthreads();
	}
	Pd[Row*Width + Col] = Pvalue;
}

int main( int argc,char **argv ) 
{
        if(argc!=2)
        {
        	printf("%s weight-file\n",argv[0]);
        	exit(-1);
        }
 	
 	//your code for task 1 goes here
      	std:: map<std::string,int> nodemap;
        std::fstream datafile(argv[1]);
                assert(datafile!=NULL);
        std::string line,from,to,str;
        double w;
        int len=0,seq=0;
        while(!datafile.eof())
        {
                getline(datafile,from,',');
                if(from.length()==0) break;
                getline(datafile,to,',');
                getline(datafile,str);
                //cout<<from<<","<<to<<","<<str<<endl;
                if(nodemap.find(from)==nodemap.end())
                        nodemap[from]=(seq++);
                if(nodemap.find(to)==nodemap.end())
                        nodemap[to]=(seq++);
	 len++;
        }

	int Level=ceil(log(seq)/log(2));
        int Width=pow(2,Level);
 	 
	//determine size 
	int size = Width * Width;

	// allocate the memory on the CPU        
        float* Mh=new float[size];
        float* Nh=new float[size];
	for(int i=0;i<size;i++){
              Mh[i]=1e+5;
	}
        assert(Mh!=NULL&&Nh!=NULL);
        datafile.close(); 
	datafile.open(argv[1]);
                for(int i=0;i<len;i++)
                {
                        getline(datafile,from,',');
                        getline(datafile,to,',');
                        getline(datafile,str);
                        w=atof(str.c_str());
                        //cout<<from<<","<<to<<","<<w<<endl;
                        int fi=nodemap[from];
                        int ti=nodemap[to];
                        if(fi>=Width||ti>=Width) continue;
                        //printf("fi=%d ti=%d\n",fi,ti);
                        Mh[fi*Width+ti]=w;
                        Mh[fi*Width+fi]=0;
                        Mh[ti*Width+ti]=0;
                }
  /*   
	for(int x = 0; x < 1000; x++){
		if(Mh[x] != 1e+5) {
			printf("Index: %d :  Element: %f\n", x, Mh[x]);
		}
	}
*/
  // allocate the memory on the GPU
    float* Md=NULL;
    float* Nd=NULL;
    HANDLE_ERROR( cudaMalloc( (void**)&Md,size* sizeof(float) ) );
    HANDLE_ERROR( cudaMalloc( (void**)&Nd, size* sizeof(float) ) );

     // copy the arrays 'Mh' and 'Nh' to the GPU
    HANDLE_ERROR( cudaMemcpy( Md, Mh, size * sizeof(float),
                              cudaMemcpyHostToDevice ) );
    
    //your code on calculating Level goes here (task 2); note that Level=1 is a placeholder in order to compile
    Width=pow(2,Level);	    
    printf("Width=%d\n",Width);
    cuda_timer timer(0);;
    InitMatrixKernel<<<size/1024,1024>>>(Nd,1e+5,size);
    getLastCudaError("InitMatrixKernel() execution failed.\n");
    dim3   DimGrid(Width/TILE_WIDTH,Width/TILE_WIDTH);  
    dim3   DimBlock(TILE_WIDTH,TILE_WIDTH); 
    
    for(int i=0;i<Level;i++)
    {
    	printf("i=%d\n",i);
    	MatrixMulKernel<<<DimGrid,DimBlock>>>( Md, Md, Nd, Width);
    	cudaDeviceSynchronize();
    	getLastCudaError("MatrixMulKernel() execution failed.\n");
	HANDLE_ERROR(cudaMemcpy(Md, Nd, size* sizeof(float),
		cudaMemcpyDeviceToDevice));  
    } 

    float msecPerMatrixMul=timer.display()/Level;
    double flopsPerMatrixMul = 2.0 * (double)Width * (double)Width * (double)Width;
    double gigaFlops = (flopsPerMatrixMul * 1.0e-9f) / (msecPerMatrixMul / 1000.0f);
    printf(
        "Performance= %.2f GFlop/s, Time= %.3f msec, Size= %.0f Ops\n",
         gigaFlops,
         msecPerMatrixMul,
         flopsPerMatrixMul);   
    // copy the array 'Nd' back from the GPU to the CPU
    HANDLE_ERROR( cudaMemcpy( Nh, Nd, size* sizeof(float),
                              cudaMemcpyDeviceToHost ) );
    printf("All pair shortest paths.....................\n");	  	
    for(int i=0;i<10;i++)
    {
    	for(int j=0;j<10;j++)
    	{
		if(Nh[i*Width+j]!=1e+5) 
			printf("%8.0f",Nh[i*Width+j]);
		else
			printf("        ");    
	}
	printf("\n");
    }

/*
    printf("%8.0f",Nh[1*Width+1]);
    printf("\n");
    printf("%8.0f",Nh[2*Width+3]);
    printf("\n"); */
    // free the memory allocated on the GPU
    HANDLE_ERROR( cudaFree( Md ) );
    HANDLE_ERROR( cudaFree( Nd ) );
    
    delete[] Mh;
    delete[] Nh;

    return 0;
}
