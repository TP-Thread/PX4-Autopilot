############################################################################
#
# Copyright (c) 2017 - 2019 PX4 Development Team. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
# 3. Neither the name PX4 nor the names of its contributors may be
#    used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
############################################################################

#=============================================================================
# CMAKE CODING STANDARD FOR PX4
#
# Structure
# ---------------------------------------------------------------------------
#
# * Common functions should be included in px_base.cmake.
#
# * OS/ board specific fucntions should be include in
#	px_impl_${PX4_PLATFORM}.cmake or px4_impl_${PX4_PLATFORM}_${PX4_BOARD}.cmake.
#
# Formatting
# ---------------------------------------------------------------------------
#
# * Use hard indents to match the px4 source code.
#
# * All function and script arguments are upper case.
#
# * All local variables are lower case.
#
# * All cmake functions are lowercase.
#
# * For else, endif, endfunction, etc, never put the name of the statement
#
# Functions/Macros
# ---------------------------------------------------------------------------
#
# * Use px4_parse_function_args to parse functions and check for required
#   arguments. Unless there is only one argument in the function and it is clear.
#
# * Never use macros. They allow overwriting global variables and this
#	makes variable declarations hard to locate.
#
# * If a target from add_custom_* is set in a function, explicitly pass it
#	as an output argument so that the target name is clear to the user.
#
# * Avoid use of global variables in functions. Functions in a nested
#	scope may use global variables, but this makes it difficult to
#	reuse functions.
#
# Included CMake Files
# ---------------------------------------------------------------------------
#
# * All variables in config files must have the prefix "config_".
#
# * Never set global variables in an included cmake file,
#	you may only define functions. This excludes config and Toolchain files.
#	This makes it clear to the user when variables are being set or targets
#	are being created.
#
# * Setting a global variable in a CMakeLists.txt file is ok, because
#	each CMakeLists.txt file has scope in the current directory and all
#	subdirectories, so it is not truly global.
#
# * All toolchain files should be included in the cmake
#	directory and named Toolchain-"name".cmake.
#
# Misc
# ---------------------------------------------------------------------------
#
# * If referencing a string variable, don't put it in quotes.
#	Don't do "${PX4_PLATFORM}" STREQUAL "posix",
#	instead type ${PX4_PLATFORM} STREQUAL "posix". This will throw an
#	error when ${PX4_PLATFORM} is not defined instead of silently
#	evaluating to false.
#
#=============================================================================
# 设置CMake最低版本要求为 3.2
cmake_minimum_required(VERSION 3.2 FATAL_ERROR)

# 设置PX4源目录和二进制目录的变量
set(PX4_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(PX4_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")

# 添加PX4源目录下的CMake目录到CMake模块搜索路径
list(APPEND CMAKE_MODULE_PATH ${PX4_SOURCE_DIR}/cmake)
# 包含一个名为 px4_parse_function_args 的 CMake 模块文件到当前的 CMakeLists.txt 文件中
include(px4_parse_function_args)

#=============================================================================
# git
#
# 包含一个名为 px4_git 的 CMake 模块文件到当前的 CMakeLists.txt 文件中
include(px4_git)

# 使用execute_process命令调用git命令获取当前版本号放到 PX4_GIT_TAG 中
execute_process(
	COMMAND git describe --exclude ext/* --always --tags	# 命令获取项目的版本标签信息
	OUTPUT_VARIABLE PX4_GIT_TAG	# 将命令的输出存储在名为 PX4_GIT_TAG 的变量中
	OUTPUT_STRIP_TRAILING_WHITESPACE	# 在将命令输出存储在变量中时，去除输出的尾随空白字符
	WORKING_DIRECTORY ${PX4_SOURCE_DIR}	# 定命令在 ${PX4_SOURCE_DIR} 目录中执行
	)
message(STATUS "PX4 version: ${PX4_GIT_TAG}")	# 打印PX4的版本号

# 定义全局属性，用于存储PX4模块库
define_property(GLOBAL PROPERTY PX4_MODULE_LIBRARIES
                 BRIEF_DOCS "PX4 module libs"
                 FULL_DOCS "List of all PX4 module libraries"
                 )

# 定义全局属性，用于存储PX4模块路径
define_property(GLOBAL PROPERTY PX4_MODULE_PATHS
                 BRIEF_DOCS "PX4 module paths"
                 FULL_DOCS "List of paths to all PX4 modules"
                 )

#=============================================================================
# configuration
#
# 设置 CONFIG 的值为px4_sitl_default, 这个值在执行make targets_default 是会被设置成targets_default
# 设置 CONFIG 为缓存变量，类型是字符串。缓存变量是一种特殊类型的变量，可以用于在 CMake 配置期间与用户交互，用户可以设置其值
set(CONFIG "px4_sitl_default" CACHE STRING "desired configuration")

# 包含 px4_add_module.cmake 文件到当前的 CMakeLists.txt 文件中
# px4_add_module 函数用来添加对不同平台的一些编译选项
include(px4_add_module)
set(config_module_list)	# 创建config_module_list变量

# 包含 px4_config.cmake 文件到当前的 CMakeLists.txt 文件中，用于配置PX4项目
# boards 文件夹下所有子文件包括的cmake 文件中查找CONFIG 对应的 .cmake 文件, 比如当 CONFIG 的值为px4_sitl_default 是查找的文件为px4/sitl/default.cmake. 对于每个通配符匹配到的.cmake 文件,把文件路径切分为三部分分别放入vendor, model和label 变量中, 然后通过不同的拼接组合和CONFIG 的值进行比较, 如果相等则设置 PX4_CONFIG_FILE 的值为当前的cmake 文件
include(px4_config)
include(px4_add_board)	# 包含px4_add_board模块，该函数设置了 PX4_CONFIG 和 PX4_PLATFORM 两个变量
include(${PX4_CONFIG_FILE})	# 包含目标飞控板的 .cmake 配置信息
# 打印PX4的配置和平台信息
message(STATUS "PX4 config: ${PX4_CONFIG}")
message(STATUS "PX4 platform: ${PX4_PLATFORM}")

# 如果平台为 "posix"，则检查是否启用了锁步调度器
if(${PX4_PLATFORM} STREQUAL "posix")
	if(ENABLE_LOCKSTEP_SCHEDULER)
		add_definitions(-DENABLE_LOCKSTEP_SCHEDULER)
		message(STATUS "PX4 lockstep: enabled")
	else()
		message(STATUS "PX4 lockstep: disabled")
	endif()
endif()

# 外部模块位置
set(EXTERNAL_MODULES_LOCATION "" CACHE STRING "External modules source location")
# 如果指定了EXTERNAL_MODULES_LOCATION，则获取其绝对路径
if(NOT EXTERNAL_MODULES_LOCATION STREQUAL "")
	get_filename_component(EXTERNAL_MODULES_LOCATION "${EXTERNAL_MODULES_LOCATION}" ABSOLUTE)
endif()

# 定义全局属性，用于存储PX4模块配置文件
set_property(GLOBAL PROPERTY PX4_MODULE_CONFIG_FILES)

# 包含特定平台的CMake配置文件
include(platforms/${PX4_PLATFORM}/cmake/px4_impl_os.cmake)
# 将平台特定的CMake模块路径添加到CMake模块路径中
list(APPEND CMAKE_MODULE_PATH ${PX4_SOURCE_DIR}/platforms/${PX4_PLATFORM}/cmake)

# 如果存在平台特定的初始化脚本 init.cmake，则包含它
if(EXISTS "${PX4_SOURCE_DIR}/platforms/${PX4_PLATFORM}/cmake/init.cmake")
	include(init)
endif()

# CMake 构建类型 (Debug Release RelWithDebInfo MinSizeRel Coverage)
# 如果未指定CMAKE_BUILD_TYPE，则设置默认值
if(NOT CMAKE_BUILD_TYPE)
	if(${PX4_PLATFORM} STREQUAL "nuttx")
		set(PX4_BUILD_TYPE "MinSizeRel")
	else()
		set(PX4_BUILD_TYPE "RelWithDebInfo")
	endif()

	set(CMAKE_BUILD_TYPE ${PX4_BUILD_TYPE} CACHE STRING "Build type" FORCE)
endif()

# 根据构建类型设置最大优化级别
if((CMAKE_BUILD_TYPE STREQUAL "Debug") OR (CMAKE_BUILD_TYPE STREQUAL "Coverage"))
	set(MAX_CUSTOM_OPT_LEVEL -O0)
elseif(CMAKE_BUILD_TYPE MATCHES "Sanitizer")
	set(MAX_CUSTOM_OPT_LEVEL -O1)
elseif(CMAKE_BUILD_TYPE MATCHES "Release")
	set(MAX_CUSTOM_OPT_LEVEL -O3)
else()
	if(px4_constrained_flash_build)
		set(MAX_CUSTOM_OPT_LEVEL -Os)
	else()
		set(MAX_CUSTOM_OPT_LEVEL -O2)
	endif()
endif()

# 设置CMAKE_BUILD_TYPE支持的选项
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug;Release;RelWithDebInfo;MinSizeRel;Coverage;AddressSanitizer;UndefinedBehaviorSanitizer")
message(STATUS "cmake build type: ${CMAKE_BUILD_TYPE}")	# 打印CMake的构建类型

#=============================================================================
# project definition
#
# 创建一个名为 "px4" 的项目，主要是一个C++项目，但也包括一些C和汇编的源代码
project(px4 CXX C ASM)
# 设置package-contact变量，用于联系PX4维护团队
set(package-contact "px4users@googlegroups.com")

# 指定C/C++标准
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# For the catkin build process, unset build of dynamically-linked binaries
# and do not change CMAKE_RUNTIME_OUTPUT_DIRECTORY
if (NOT CATKIN_DEVEL_PREFIX)
	set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PX4_BINARY_DIR})
	set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${PX4_BINARY_DIR})
	set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${PX4_BINARY_DIR})
else()
	SET(BUILD_SHARED_LIBS OFF)
endif()

#=============================================================================

# 如果可用，启用gold链接器（目前仅支持posix平台）
if(${PX4_PLATFORM} STREQUAL "posix")
	include(CMakeDependentOption)
	CMAKE_DEPENDENT_OPTION(USE_LD_GOLD
			"Use GNU gold linker" ON
			"NOT WIN32;NOT APPLE" OFF
	)

	if(USE_LD_GOLD)
		execute_process(COMMAND ${CMAKE_C_COMPILER} -fuse-ld=gold -Wl,--version ERROR_QUIET OUTPUT_VARIABLE LD_VERSION)
		if("${LD_VERSION}" MATCHES "GNU gold")
			set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=gold")
			set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fuse-ld=gold")
		else()
			set(USE_LD_GOLD OFF)
		endif()
	endif()
endif()

#=============================================================================

# 设置安装路径
if(${PX4_PLATFORM} STREQUAL "posix")
	# This makes it possible to dynamically load code which depends on symbols
	# inside the px4 executable.
	set(CMAKE_POSITION_INDEPENDENT_CODE ON)
	set(CMAKE_ENABLE_EXPORTS ON)

	include(coverage)
	include(sanitizers)

	# Define GNU standard installation directories
	include(GNUInstallDirs)

	if (NOT CMAKE_INSTALL_PREFIX)
		set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "Install path prefix" FORCE)
	endif()
endif()

include(ccache)

#=============================================================================
# find programs and packages
#

# 查看是否通过catkin构建项目
if (CATKIN_DEVEL_PREFIX)
	message(STATUS "catkin ENABLED")
	find_package(catkin REQUIRED)
	if (catkin_FOUND)
		catkin_package()
	else()
		message(FATAL_ERROR "catkin not found")
	endif()
endif()

# Python
# 如果使用catkin，将找到Python 2，因为它指向与ROS发行版一起安装的Python库
if (NOT CATKIN_DEVEL_PREFIX)
	find_package(PythonInterp 3)
	# We have a custom error message to tell users how to install python3.
	if (NOT PYTHONINTERP_FOUND)
		message(FATAL_ERROR "Python 3 not found. Please install Python 3:\n"
			"    Ubuntu: sudo apt install python3 python3-dev python3-pip\n"
			"    macOS: brew install python")
	endif()
else()
	find_package(PythonInterp REQUIRED)
endif()

# 可选项：启用Python代码覆盖率，未开启
option(PYTHON_COVERAGE "Python code coverage" OFF)
if(PYTHON_COVERAGE)
	message(STATUS "python coverage enabled")
	set(PYTHON_EXECUTABLE coverage run -p)
endif()

#=============================================================================
# 获取芯片和芯片制造商信息
#
px4_os_determine_build_chip()
if(NOT PX4_CHIP_MANUFACTURER)
	message(FATAL_ERROR "px4_os_determine_build_chip() needs to set PX4_CHIP_MANUFACTURER")
endif()
if(NOT PX4_CHIP)
	message(FATAL_ERROR "px4_os_determine_build_chip() needs to set PX4_CHIP")
endif()

#=============================================================================
# 构建标志设置
#
include(px4_add_common_flags)
px4_add_common_flags()
px4_os_add_flags()

#=============================================================================
# board cmake init (optional)
#
if(EXISTS ${PX4_BOARD_DIR}/cmake/init.cmake)
	include(${PX4_BOARD_DIR}/cmake/init.cmake)
endif()

#=============================================================================
# message, and airframe generation
#
# 包含px4_metadata模块，用于生成PX4飞行器信息
include(px4_metadata)

add_subdirectory(msg EXCLUDE_FROM_ALL)	# 生成uORB消息定义

px4_generate_airframes_xml(BOARD ${PX4_BOARD})# 根据PX4板信息生成PX4飞行器XML定义

#=============================================================================
# external projects
#
set(ep_base ${PX4_BINARY_DIR}/external)
set_property(DIRECTORY PROPERTY EP_BASE ${ep_base})

# 将外部项目的安装目录添加到构建中
# 添加这些目录以防止CMake生成警告
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${ep_base})
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${ep_base}/Install)
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${ep_base}/Install/lib)
link_directories(${ep_base}/Install/lib)
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${ep_base}/Install/include)
include_directories(${ep_base}/Install/include)

#=============================================================================
# external modules
#
set(external_module_paths)
if (NOT EXTERNAL_MODULES_LOCATION STREQUAL "")
	message(STATUS "External modules: ${EXTERNAL_MODULES_LOCATION}")
	add_subdirectory("${EXTERNAL_MODULES_LOCATION}/src" external_modules)

	foreach(external_module ${config_module_list_external})
		add_subdirectory(${EXTERNAL_MODULES_LOCATION}/src/${external_module} external_modules/${external_module})
		list(APPEND external_module_paths ${EXTERNAL_MODULES_LOCATION}/src/${external_module})
	endforeach()
endif()

#=============================================================================
# Testing - Automatic unit and integration testing with CTest
#
# 测试 - 使用CTest进行自动单元测试和集成测试
# 可选项：配置CMake测试（仅支持posix）
option(CMAKE_TESTING "Configure test targets" OFF)
if(${PX4_CONFIG} STREQUAL "px4_sitl_test")
	set(CMAKE_TESTING ON)
endif()
if(CMAKE_TESTING)
	include(CTest) # sets BUILD_TESTING variable
endif()

# 启用测试筛选，以仅运行具有ctest -R正则表达式功能的特定测试
set(TESTFILTER "" CACHE STRING "Filter string for ctest to selectively only run specific tests (ctest -R)")

# 如果启用了测试，则下载和配置gtest
list(APPEND CMAKE_MODULE_PATH ${PX4_SOURCE_DIR}/cmake/gtest/)
include(px4_add_gtest)
if(BUILD_TESTING)
	include(gtest)

	add_custom_target(test_results
			COMMAND GTEST_COLOR=1 ${CMAKE_CTEST_COMMAND} --output-on-failure -T Test -R ${TESTFILTER} USES_TERMINAL
			DEPENDS
				px4
				examples__dyn_hello
				test_mixer_multirotor
			USES_TERMINAL
			COMMENT "Running tests"
			WORKING_DIRECTORY ${PX4_BINARY_DIR})
	set_target_properties(test_results PROPERTIES EXCLUDE_FROM_ALL TRUE)
endif()


#=============================================================================
# subdirectories
#
# 创建一个名为parameters_interface的接口库
add_library(parameters_interface INTERFACE)

include(px4_add_library)	# 包含px4_add_library模块
add_subdirectory(src/lib EXCLUDE_FROM_ALL)	# 添加lib目录的子目录

add_subdirectory(platforms/${PX4_PLATFORM}/src/px4)	# 添加platforms/${PX4_PLATFORM}/src/px4目录
add_subdirectory(platforms EXCLUDE_FROM_ALL)		# 添加platforms目录的子目录（不包括所有子目录）

# 如果PX4_BOARD_DIR目录存在，则添加PX4_BOARD_DIR目录
if(EXISTS "${PX4_BOARD_DIR}/CMakeLists.txt")
	add_subdirectory(${PX4_BOARD_DIR})
endif()

# 添加src目录下各个模块的子目录
foreach(module ${config_module_list})
	add_subdirectory(src/${module})
endforeach()

# 必须是固件之前的最后一个模块，以生成已包含模块的内置模块
# 添加src/lib/parameters目录
add_subdirectory(src/lib/parameters EXCLUDE_FROM_ALL)
target_link_libraries(parameters_interface INTERFACE parameters)

# 最后，添加platforms/${PX4_PLATFORM}目录
# 这里包括构建PX4固件的最后一步
add_subdirectory(platforms/${PX4_PLATFORM})

#=============================================================================
# uORB graph generation: add a custom target 'uorb_graph'
#
# 生成uORB图：添加名为'uorb_graph'的自定义目标
set(uorb_graph_config ${PX4_BOARD})

set(graph_module_list "")
foreach(module ${config_module_list})
	set(graph_module_list "${graph_module_list}" "--src-path" "src/${module}")
endforeach()

add_custom_command(OUTPUT ${uorb_graph_config}
	COMMAND ${PYTHON_EXECUTABLE} ${PX4_SOURCE_DIR}/Tools/uorb_graph/create.py
		${graph_module_list}
		--exclude-path src/examples
		--file ${PX4_SOURCE_DIR}/Tools/uorb_graph/graph_${uorb_graph_config}
	WORKING_DIRECTORY ${PX4_SOURCE_DIR}
	COMMENT "Generating uORB graph"
)
add_custom_target(uorb_graph DEPENDS ${uorb_graph_config})


include(doxygen)	# 包含doxygen模块
include(metadata)	# 包含metadata模块
include(package)	# 包含package模块

# 打印目标文件的大小
add_custom_target(size
	COMMAND size $<TARGET_FILE:px4>
	DEPENDS px4
	WORKING_DIRECTORY ${PX4_BINARY_DIR}
	USES_TERMINAL
	)

# install python requirements using configured python
add_custom_target(install_python_requirements
	COMMAND ${PYTHON_EXECUTABLE} -m pip install --requirement ${PX4_SOURCE_DIR}/Tools/setup/requirements.txt
	DEPENDS ${PX4_SOURCE_DIR}/Tools/setup/requirements.txt
	USES_TERMINAL
)
