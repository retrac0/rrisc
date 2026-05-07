int main(){
  int a[4];a[0]=1;a[1]=2;a[2]=3;a[3]=4;
  int l=0;int r=3;
  while(l<r){int t=a[l];a[l]=a[r];a[r]=t;l=l+1;r=r-1;}
  return a[0];
}
