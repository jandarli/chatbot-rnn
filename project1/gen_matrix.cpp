#include <cassert>
#include <map>
#include <algorithm>
#include <fstream>
#include <math.h>
#include <stdio.h>

using namespace std;
int main( int argc,char **argv )
{
       if(argc!=2)
        {
        	printf("%s weight-file\n",argv[0]);
        	exit(-1);
        }
        map<string,int> nodemap;
        fstream datafile(argv[1]);
		assert(datafile!=NULL);
        string line,from,to,str;
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
        printf("len=%d seq=%d\n",len,seq);
		datafile.close();
        int Level=ceil(log(seq)/log(2));
        int Width=pow(2,Level);
        //if(Width>1024) Width=1024;
        printf("Using Width=%d\n",Width);
        int size = Width * Width;
		float* Mh=new float[size];
		assert(Mh!=NULL);
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
}