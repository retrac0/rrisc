int main(){
  int a[10];a[0]=1;a[1]=1;a[2]=1;a[3]=2;a[4]=2;
  a[5]=3;a[6]=3;a[7]=3;a[8]=3;a[9]=1;
  int best=1;
  int cur=1;
  for(int i=1;i<10;i=i+1){
    if(a[i]==a[i-1]){cur++;if(cur>best){best=cur;}}
    else{cur=1;}
  }
  return best;
}
