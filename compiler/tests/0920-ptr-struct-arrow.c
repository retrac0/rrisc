struct P{int x;int y;};
int main(){struct P p;p.x=3;p.y=4;struct P *q=&p;return q->x+q->y;}
