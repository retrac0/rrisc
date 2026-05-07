struct R{int w;int h;};
int area(struct R r){return r.w*r.h;}
int main(){struct R r;r.w=6;r.h=7;return area(r);}
