int main(){
  int a[3];a[0]=1;a[1]=2;a[2]=3;
  int b[3];b[0]=4;b[1]=5;b[2]=6;
  int s=0;
  for(int i=0;i<3;i=i+1){s+=a[i]*b[i];}
  return s;
}
