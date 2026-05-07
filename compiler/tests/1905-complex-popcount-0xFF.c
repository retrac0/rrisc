int popcount(int x){int c=0;while(x){c+=x&1;x>>=1;}return c;}
int main(){return popcount(0xFF);}
