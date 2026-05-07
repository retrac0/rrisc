int main(){
  int a[5];a[0]=5;a[1]=3;a[2]=8;a[3]=1;a[4]=4;
  for(int i=0;i<4;i=i+1){for(int j=0;j<4-i;j=j+1){if(a[j]>a[j+1]){int t=a[j];a[j]=a[j+1];a[j+1]=t;}}}
  return a[4];
}
