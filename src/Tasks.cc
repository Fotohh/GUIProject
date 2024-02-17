#include "Tasks.h"

#include <iostream>
#include <list>
#include <windows.h>
#include <chrono>



std::list<Task> Tasks::taskList;

Task Tasks::createTask(std::string taskName, bool hasTimestamp) {
    using namespace std::chrono;
    u_int64 timestamp = 0;
    if(hasTimestamp) {
        timestamp = duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
    }
    return Task{taskName, std::rand(), timestamp, hasTimestamp};
}

bool Tasks::deleteTask(int taskID) {

}

Task Tasks::getTask(int taskID) {

} 

std::list<Task> Tasks::getTasks() {
    return taskList;
}

bool Tasks::addTask(Task task) {

}