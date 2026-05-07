int stk[16];
int top=0;
void push(int v){stk[top]=v;top++;}
int pop(){top--;return stk[top];}
int main(){push(1);push(2);push(3);int a=pop();int b=pop();int c=pop();return a+b*10+c*100;}
