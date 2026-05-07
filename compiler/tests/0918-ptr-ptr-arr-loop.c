int main(){
  int a[5];a[0]=1;a[1]=2;a[2]=3;a[3]=4;a[4]=5;
  int s=0;int *p=a;
  for(int i=0;i<5;i=i+1){s=s+*p;p=p+1;}
  return s;
}
