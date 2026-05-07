void mcpy(int *dst,int *src,int n){for(int i=0;i<n;i=i+1){dst[i]=src[i];}}
int main(){
  int src[4];src[0]=1;src[1]=2;src[2]=3;src[3]=4;
  int dst[4];
  mcpy(dst,src,4);
  return dst[2];
}
