int even_(int n);
int odd_(int n){if(n==0){return 0;}return even_(n-1);}
int even_(int n){if(n==0){return 1;}return odd_(n-1);}
int main(){return even_(4);}
