#include "Tasks.h"

#include <iostream>
#include <list>
#include <windows.h>
#include <chrono>



std::vector<Task> Tasks::taskList;

int Tasks::createTask(std::string taskName, bool hasTimestamp) {
    using namespace std::chrono;
    u_int64 timestamp = 0;
    if(hasTimestamp) {
        timestamp = duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
    }
    addTask(Task{taskName, std::rand(), timestamp, hasTimestamp});
    return taskList.size() -1;
}

void Tasks::deleteTask(int taskID) {
    taskList.erase(taskList.begin() + taskID);
}

Task* Tasks::getTask(int taskID) {
    for(Task &task : taskList){
        if(task.timestamp == taskID){
            return &task;
        }
        
    }
    return nullptr;
} 

std::vector<Task>& Tasks::getTasks() {
    return taskList;
}

void Tasks::addTask(Task task) {
    taskList.push_back(task);
}