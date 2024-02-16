#pragma once
#include <iostream>

class UserProcess {

    UserProcess();
    
    ~UserProcess();

private:
    unsigned char UUID;

public:
    std::string username;
    
    const bool getUserStatus();
    
    

};