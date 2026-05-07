void swap(int *a,int *b){int t=*a;*a=*b;*b=t;}
int main(){int x=3;int y=7;swap(&x,&y);return x;}
