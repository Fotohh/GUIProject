#ifndef TASKS_H_
#define TASKS_H_

#include <iostream>
#include <cstdint>
#include <list>

#define ExampleTask {"Example", "1", "0", false}

struct Task {
    std::string taskName;
    int taskID;
    uint64_t timestamp;
    bool hasTimestamp;
};

//not sure what kind of tasks would exist...

class Tasks{

private:
    static std::list<Task> taskList;

public:
    Task createTask(std::string taskName, bool timestamp);
    bool deleteTask(int taskID);
    Task getTask(int taskID);
    static std::list<Task> getTasks();
    bool addTask(Task task);
};

#endif