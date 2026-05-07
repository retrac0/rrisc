int pw(int b,int e){if(e==0){return 1;}return b*pw(b,e-1);}
int main(){return pw(2,8);}
