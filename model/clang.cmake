#
# Copyright (c) 2020-2026 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the License); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an AS IS BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set(TARGET_CPU
    "cortex-m55"
    CACHE STRING "Target CPU"
)
string(TOLOWER ${TARGET_CPU} CMAKE_SYSTEM_PROCESSOR)

set(CMAKE_SYSTEM_NAME Generic)

# Check for ARM toolchain in ExecuTorch installation path
set(CLANG_TOOLCHAIN_PATH "/workspace/executorch/examples/arm/ethos-u-scratch/ATfE-21.1.1/bin")
if(EXISTS "${CLANG_TOOLCHAIN_PATH}/clang" AND EXISTS "${CLANG_TOOLCHAIN_PATH}/clang++")
    message(STATUS "Found ARM toolchain in ExecuTorch path: ${CLANG_TOOLCHAIN_PATH}")
    set(CMAKE_C_COMPILER "${CLANG_TOOLCHAIN_PATH}/clang")
    set(CMAKE_CXX_COMPILER "${CLANG_TOOLCHAIN_PATH}/clang++")
    set(CMAKE_ASM_COMPILER "${CLANG_TOOLCHAIN_PATH}/clang")
    set(CMAKE_LINKER "${CLANG_TOOLCHAIN_PATH}/lld")
else()
    message(STATUS "ExecuTorch ARM toolchain not found, using system PATH")
    set(CMAKE_C_COMPILER "clang")
    set(CMAKE_CXX_COMPILER "clang++")
    set(CMAKE_ASM_COMPILER "clang")
    set(CMAKE_LINKER "lld")
endif()

set(CMAKE_EXECUTABLE_SUFFIX ".elf")
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Select C/C++ version
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

set(CLANG_CPU ${CMAKE_SYSTEM_PROCESSOR})

# Compile options
add_compile_options(
  -mcpu=${CLANG_CPU} -mthumb "$<$<CONFIG:DEBUG>:-gdwarf-3>"
  "$<$<COMPILE_LANGUAGE:CXX>:-fno-unwind-tables;-fno-rtti;-fno-exceptions>"
  -fdata-sections -ffunction-sections
)

# Compile defines
add_compile_definitions("$<$<NOT:$<CONFIG:DEBUG>>:NDEBUG>")

# Link options
add_link_options(-mcpu=${CLANG_CPU} -mthumb)

if(SEMIHOSTING)
  add_link_options(-lsemihost)
endif()

# Set floating point unit
if(CMAKE_SYSTEM_PROCESSOR MATCHES "\\+fp")
  set(FLOAT hard)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "\\+nofp")
  set(FLOAT soft)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "cortex-m33(\\+|$)"
  OR CMAKE_SYSTEM_PROCESSOR MATCHES "cortex-m55(\\+|$)"
  OR CMAKE_SYSTEM_PROCESSOR MATCHES "cortex-m85(\\+|$)")
  set(FLOAT hard)
else()
  set(FLOAT soft)
endif()

if(FLOAT)
  add_compile_options(-mfloat-abi=${FLOAT})
  add_link_options(-mfloat-abi=${FLOAT})
endif()

if(CMAKE_SYSTEM_PROCESSOR MATCHES "cortex-m33(\\+|$)")
  set(CLANG_ARCH "armv8m.main")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "cortex-m55(\\+|$)"
  OR CMAKE_SYSTEM_PROCESSOR MATCHES "cortex-m85(\\+|$)")
  set(CLANG_ARCH "armv8.1m.main")
else()
  error("Unsupported CPU: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

if(FLOAT STREQUAL "hard")
  set(CLANG_TARGET "${CLANG_ARCH}-none-eabihf")
else()
  set(CLANG_TARGET "${CLANG_ARCH}-none-eabi")
endif()

set(CMAKE_CXX_COMPILER_TARGET "${CLANG_TARGET}")
set(CMAKE_C_COMPILER_TARGET "${CLANG_TARGET}")

add_link_options(LINKER:--nmagic,--gc-sections)

# Compilation warnings
add_compile_options(
  # -Wall -Wextra -Wcast-align -Wdouble-promotion -Wformat
  # -Wmissing-field-initializers -Wnull-dereference -Wredundant-decls -Wshadow
  # -Wswitch -Wswitch-default -Wunused -Wno-redundant-decls
  -Wno-error=deprecated-declarations -Wno-error=shift-overflow
)

# Temporary workaround for missing steady_clock and RNG seed in libc++
set(CMAKE_CXX_COMPILER_TARGET "arm-none-eabi")
set(CMAKE_C_COMPILER_TARGET "arm-none-eabi")
set(GCC_TOOLCHAIN_PATH "/workspace/executorch/examples/arm/ethos-u-scratch/arm-gnu-toolchain-13.3.rel1-arm-none-eabi")
add_compile_options("$<$<COMPILE_LANGUAGE:CXX>:--gcc-toolchain=${GCC_TOOLCHAIN_PATH};-stdlib=libstdc++;-Wno-multilib-not-found>")
add_link_options("$<$<COMPILE_LANGUAGE:CXX>:--gcc-toolchain=${GCC_TOOLCHAIN_PATH};-stdlib=libstdc++;-Wno-multilib-not-found>")
