struct I{int x;};
struct O{struct I i;int y;};
int main(){return sizeof(struct O);}
