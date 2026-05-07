int vals[5];
int nexts[5];
int main(){
  vals[0]=10;nexts[0]=1;
  vals[1]=20;nexts[1]=2;
  vals[2]=30;nexts[2]=3;
  vals[3]=40;nexts[3]=4;
  vals[4]=50;nexts[4]=-1;
  int s=0;int i=0;
  while(i>=0){s+=vals[i];i=nexts[i];}
  return s;
}
