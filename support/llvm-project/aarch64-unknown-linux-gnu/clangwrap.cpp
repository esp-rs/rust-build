#include <cstring>
#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stdlib.h>
#include <memory>
#include <stdexcept>

using namespace std;

int main(int argc, char *argv[]) {
  string opt_clang_pre;
  string opt_gcc;
  string opt_clang;
  bool is_c = true;
  bool is_cc1 = false;
  bool is_gcc = false;

  if (argc < 2) {
    printf("ERROR: You need at least one argument.\n");
    return 1;
  }

  for (int i = 1; argv[i] != nullptr; i++) {
    string option(argv[i]);

    size_t start_pos = 0;
    while ((start_pos = option.find("\"", start_pos)) != std::string::npos) {
      option.replace(start_pos, 1, "\\\"");
      start_pos += 2;
    }

    opt_gcc.append(" ");
    opt_gcc.append(option);

    if (std::strcmp("-dumpversion", argv[i]) == 0) {
      cout << "8.4.0" << "\n";
      return 0;
    }
    if (std::strcmp("--version", argv[i]) == 0) {
      cout << "xtensa-esp32-elf-gcc (crosstool-NG esp-2021r1) 8.4.0" << "\n";
      return 0;
    }
    if (std::strcmp("-mlongcalls", argv[i]) == 0) {
      continue;
    }
    if (strcmp("-fstrict-volatile-bitfields", argv[i]) == 0) {
      continue;
    }
    if (strcmp("-fno-test-coverage", argv[i]) == 0) {
      continue;
    }
    if (strcmp("-freorder-blocks", argv[i]) == 0) {
      continue;
    }
    if (strcmp("-fno-tree-switch-conversion", argv[i]) == 0) {
      continue;
    }
    if (strcmp("-Wextra", argv[i]) == 0) {
      continue;
    }
    if (strcmp("-Werror=all", argv[i]) == 0) {
      continue;
    }
    if (strcmp("-Wno-frame-address", argv[i]) == 0) {
      continue;
    }
    if (strcmp("-Wno-old-style-declaration", argv[i]) == 0) {
      continue;
    }
    if (strcmp("-Wno-error=unused-but-set-variable", argv[i]) == 0) {
      continue;
    }
    if (strcmp("-Wa,--compress-debug-sections", argv[i]) == 0) {
      continue;
    }
    if (strcmp("-cc1", argv[i]) == 0) {
      is_cc1 = true;
      continue;
    }

    if (strcmp("-x", argv[i]) == 0) {
      if (strcmp("c++", argv[i+1]) == 0)
        is_c = false;

      opt_clang.append(" ");
      opt_clang.append(option);
      continue;
    }
    opt_clang.append(" ");
    opt_clang.append(option);
  }

  if (is_cc1) {
    opt_clang_pre =" -cc1 -nobuiltininc -nostdsysteminc -nostdinc++";
    opt_clang_pre += " -isystem../lib/clang/12.0.1/include";

    if (is_c) {
      opt_clang_pre += " -isystem../lib/gcc/xtensa-esp32-elf/8.4.0/include";
      opt_clang_pre += " -isystem../lib/gcc/xtensa-esp32-elf/8.4.0/include-fixed";
      opt_clang_pre += " -isystem../xtensa-esp32-elf/sys-include";
      opt_clang_pre += " -isystem../xtensa-esp32-elf/include";
    }

    opt_clang_pre += " -stdlib++-isystem../xtensa-esp32-elf/include/c++/8.4.0";
    opt_clang_pre += " -stdlib++-isystem../xtensa-esp32-elf/include/c++/8.4.0/xtensa-esp32-elf";
    opt_clang_pre += " -stdlib++-isystem../xtensa-esp32-elf/include/c++/8.4.0/backward";
    opt_clang_pre += " -std=gnu11 -Os  -Wtypedef-redefinition -ffreestanding";
  } else {
    opt_clang_pre = " -target xtensa -mcpu=esp32  -fomit-frame-pointer -Wtypedef-redefinition -ffreestanding -fcommon -fno-use-cxa-atexit ";
  }

  string cmd = "clang " + opt_clang_pre + opt_clang;


  if (is_gcc) {
   if (!is_c)
    cmd = "xtensa-esp32-elf-c++ " + opt_gcc;
   else
    cmd = "xtensa-esp32-elf-gcc " + opt_gcc;
  }

  int result = system(cmd.c_str());
  
  return result;
}
