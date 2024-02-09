GPP = g++

OBJ = out/main.o 
OBJ += out/imgui/imgui_demo.o out/imgui/imgui_draw.o out/imgui/imgui_tables.o out/imgui/imgui_widgets.o out/imgui/imgui.o
OBJ += out/glad/glad.o

INCLUDES = -I submodules/imgui -I submodules/glfw -I submodules
LIBS = -L submodules/glfw -lglfw3 -lgdi32

FLAGS = -Wall -std=c++17 -O0

APP_TITLE = TWITTER2

all: $(OBJ)
	$(GPP) -o out/$(APP_TITLE).exe $(OBJ) $(FLAGS) $(LIBS)

out/%.o: src/%.cc
	$(GPP) -c $< $(INCLUDES) -o $@

out/imgui/%.o: submodules/imgui/%.cpp
	$(GPP) -c $< $(INCLUDES) -o $@

out/glad/%.o: src/%.c
	$(GPP) -c $< $(INCLUDES) -o $@

.PHONY: clean run

run:
	out/$(APP_TITLE).exe

clean:
	cd out
	del *.o *.exe
	cd out/glfw
	del *.o
	cd ../
	cd out/glad
	del *.o

