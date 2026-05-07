int flag=0;
int set_flag(){flag=1;return 1;}
int main(){0||set_flag();return flag;}
