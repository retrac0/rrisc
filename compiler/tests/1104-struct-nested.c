struct I{int x;};
struct O{struct I i;int y;};
int main(){struct O o;o.i.x=5;o.y=10;return o.i.x+o.y;}
