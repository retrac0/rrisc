int flag=0;
int set_flag(){flag=1;return 1;}
int main(){1||set_flag();return flag;}
