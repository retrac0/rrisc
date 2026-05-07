struct P{int x;};
void setx(struct P *p,int v){p->x=v;}
int main(){struct P p;p.x=0;setx(&p,42);return p.x;}
