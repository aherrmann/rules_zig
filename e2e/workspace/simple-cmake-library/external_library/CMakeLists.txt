cmake_minimum_required(VERSION 3.20)
project(hello)

add_library(hello SHARED hello.c)
target_include_directories(hello PRIVATE ".")


install(TARGETS hello EXPORT helloTargets
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)

install(FILES hello.h
  DESTINATION "hello/"
)

