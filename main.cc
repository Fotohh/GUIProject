#include <iostream>
#include <imgui.h>

int main(void) {
    std::cout << "Initial commit looks great!" << std::endl;
    std::cout << "\nPress any key to continue... ";
    std::cin.get();

    ImGui::Begin("Hello");
    ImGui::NewFrame();
    ImGui::Button("Hello");
    return 0;
}