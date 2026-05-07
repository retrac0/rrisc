int sum(int *a,int n){int s=0;for(int i=0;i<n;i=i+1){s=s+a[i];}return s;}
int main(){int a[4];a[0]=1;a[1]=2;a[2]=3;a[3]=4;return sum(a,4);}
