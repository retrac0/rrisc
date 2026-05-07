struct P{int v;};
int main(){struct P p;p.v=0;struct P *q=&p;q->v=99;return p.v;}
