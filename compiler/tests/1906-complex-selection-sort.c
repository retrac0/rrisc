int main(){
  int a[5];a[0]=4;a[1]=2;a[2]=5;a[3]=1;a[4]=3;
  for(int i=0;i<4;i=i+1){
    int m=i;
    for(int j=i+1;j<5;j=j+1){if(a[j]<a[m]){m=j;}}
    int t=a[i];a[i]=a[m];a[m]=t;
  }
  return a[0]+a[4];
}
