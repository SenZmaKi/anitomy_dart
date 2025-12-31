CXX = g++
CXXFLAGS = -std=c++14 -Wall -Wextra -I../anitomy
LDFLAGS =

# Source files
ANITOMY_SRC = ../anitomy/anitomy/anitomy.cpp \
              ../anitomy/anitomy/element.cpp \
              ../anitomy/anitomy/keyword.cpp \
              ../anitomy/anitomy/parser.cpp \
              ../anitomy/anitomy/parser_helper.cpp \
              ../anitomy/anitomy/parser_number.cpp \
              ../anitomy/anitomy/string.cpp \
              ../anitomy/anitomy/token.cpp \
              ../anitomy/anitomy/tokenizer.cpp

TEST_SRC = anitomy_test.cpp

# Object files
ANITOMY_OBJ = $(ANITOMY_SRC:.cpp=.o)
TEST_OBJ = $(TEST_SRC:.cpp=.o)

# Target executable
TARGET = anitomy_test

all: $(TARGET)

$(TARGET): $(ANITOMY_OBJ) $(TEST_OBJ)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(ANITOMY_OBJ) $(TEST_OBJ) $(TARGET)

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
