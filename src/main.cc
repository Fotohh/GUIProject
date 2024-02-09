#include <iostream>

#include <glad/glad.h>
#include <GLFW/glfw3.h>

int main(void) {

    if (!glfwInit()) {
        std::cerr << "Unable to initialize GLFW!" << std::endl;
        return -1;
    }

    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);

    GLFWwindow* window = glfwCreateWindow(800, 600, "GUI Project", nullptr, nullptr);

    if (!window) {
        std::cerr << "Unable to create window" << std::endl;
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);

    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
        std::cerr << "Unable to create OpenGL context" << std::endl;
        glfwTerminate();
        return -1;
    }

    glViewport(0, 0, 800, 600);

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();
        glClear(GL_COLOR_BUFFER_BIT);

        glClearColor(0.6, 0.3, 0.3, 1.0);

        glfwSwapBuffers(window);
    }

    glfwTerminate();

    std::cout << "App closed." << std::endl;
    std::cin.get();

    return 0;
}