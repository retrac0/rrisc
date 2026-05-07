int main(){
  int a[5];int *p=a;
  for(int i=0;i<5;i=i+1){*p=i*i;p=p+1;}
  return a[3];
}
