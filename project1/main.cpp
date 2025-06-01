#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
using namespace std;

int main()
{
double testline;
	double DataMatrix[1544][3];

	ifstream Test("cd101.txt");

	if (!Test)
	{
		cout << "There was an error opening the file.\n";
		return 0;
	}
	//store numbers in array
	int x = 0, y = 0;
	while (Test >> testline)
	{
		DataMatrix[y][x] = testline;
		x++;
		if (testline == NULL)
			y++;
	}
	//output whole array with array position numbers for each entry
	cout<<"Array contents:\n";
	for (int y=0;y<1544;y++)
	{
        for (int x=0;x<3;x++)
        {
            cout<<DataMatrix[y][x]<<"("<<y<<","<<x<<")"<<"   ";
        }

      cout<<endl;
	}

	cout<<"=============================================================="<<endl;
    cout<<"=============================================================="<<endl;


	map< int, map <int, double> > testMap;

	for (int i = 0; i<1544; i++)
	{
		for (int j = 0; j<3; j++)
		{

		   testMap[DataMatrix[i][j]][DataMatrix[i][j + 1]] = DataMatrix[i][2];  //testMap[u][v]= w

		}
	}
		/*cout << "The Weight from Node "<< Two_D_Array[0][0]<<" to Node "<< Two_D_Array[0][1]<<" = "<< testMap[Two_D_Array[0][0]][Two_D_Array[0][1]] << endl; //testMap[12245][64133] = 441.028
		*/
    for (int i = 0; i < 1544; i++ )
    {
        for (int j = 0; j < 3; j++)
         {
            cout << "The distance from Node " << DataMatrix[i][j] << " to Node " << DataMatrix[i][j + 1] << " = " << testMap[DataMatrix[i][j]][DataMatrix[i][j + 1]] << endl;
            j = 3;
         }
    }



    return 0;
}
