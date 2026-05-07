int a[8];
int bsrch(int *arr,int n,int v){
  int lo=0;int hi=n-1;
  while(lo<=hi){int mid=(lo+hi)/2;if(arr[mid]==v){return mid;}if(arr[mid]<v){lo=mid+1;}else{hi=mid-1;}}
  return -1;
}
int main(){
  a[0]=1;a[1]=3;a[2]=5;a[3]=7;a[4]=9;a[5]=11;a[6]=13;a[7]=15;
  return bsrch(a,8,7);
}
