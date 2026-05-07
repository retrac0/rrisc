int main(){
  int msg[5];msg[0]=72;msg[1]=101;msg[2]=108;msg[3]=108;msg[4]=111;
  int shift=3;
  int s=0;
  for(int i=0;i<5;i=i+1){s+=(msg[i]+shift)%128;}
  return s%256;
}
