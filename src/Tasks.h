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
    static std::vector<Task> taskList;

public:
    int createTask(std::string taskName, bool timestamp);
    void deleteTask(int taskID);
    Task* getTask(int taskID);
    static std::vector<Task>& getTasks();
    void addTask(Task task);
};

#endif