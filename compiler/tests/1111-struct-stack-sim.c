struct S{int top;int data[8];};
int main(){struct S s;s.top=0;s.data[0]=99;s.top=s.top+1;s.top=s.top-1;return s.data[s.top];}
