struct P{int x;int y;};
int main(){struct P a;a.x=1;a.y=2;struct P b;b=a;return b.x+b.y;}
