############################################################################
#
#   Copyright (c) 2019 PX4 Development Team. All rights reserved.
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

# find PX4 config
#  look for in tree board config that matches CONFIG input
# 这段CMake代码的主要作用是从PX4项目的板载配置文件（通常以.cmake文件形式存在）中选择一个与给定的CONFIG参数匹配的配置文件
# 并将其路径存储在PX4_CONFIG_FILE变量中。
if(NOT PX4_CONFIG_FILE)
	# 在PX4项目的boards目录中递归搜索所有.cmake文件，并将它们的相对路径存储在board_configs列表中
	file(GLOB_RECURSE board_configs
		RELATIVE "${PX4_SOURCE_DIR}/boards"
		"boards/*.cmake"
		)

	# 将PX4_CONFIGS变量设置为board_configs列表的值，并将其类型设置为CACHE STRING，并强制存储。
	set(PX4_CONFIGS ${board_configs} CACHE STRING "PX4 board configs" FORCE)

	# foreach循环，用于遍历列表中的元素。在这里，${board_configs}是一个包含文件名的列表，filename是循环中的迭代变量，
	# 每次循环时会将列表中的一个文件名赋值给filename，然后执行循环体中的操作。
	foreach(filename ${board_configs})
		# parse input CONFIG into components to match with existing in tree configs
		#  the platform prefix (eg nuttx_) is historical, and removed if present
		# 将变量 filename 中的 ".cmake" 替换为空字符串 ""，并将结果存储到变量 filename_stripped 中
		string(REPLACE ".cmake" "" filename_stripped ${filename})
		# 将变量 filename_stripped 中的 "/" 替换为 ";"，并将结果存储到变量 config 中
		string(REPLACE "/" ";" config ${filename_stripped})
		# 计算列表变量config中的元素数量，并将结果存储在变量config_len中
		list(LENGTH config config_len)

		if(${config_len} EQUAL 3)
			# 获取列表中的元素，索引从0开始
			list(GET config 0 vendor)
			list(GET config 1 model)
			list(GET config 2 label)

			set(board "${vendor}${model}")

			# <VENDOR>_<MODEL>_<LABEL> (eg px4_fmu-v2_default)
			# <VENDOR>_<MODEL>_default (eg px4_fmu-v2) # allow skipping label if "default"
			if ((${CONFIG} MATCHES "${vendor}_${model}_${label}") OR # match full vendor, model, label
			    ((${label} STREQUAL "default") AND (${CONFIG} STREQUAL "${vendor}_${model}")) # default label can be omitted
			)
				set(PX4_CONFIG_FILE "${PX4_SOURCE_DIR}/boards/${filename}" CACHE FILEPATH "path to PX4 CONFIG file" FORCE)
				break()
			endif()

			# <BOARD>_<LABEL> (eg px4_fmu-v2_default)
			# <BOARD>_default (eg px4_fmu-v2) # allow skipping label if "default"
			if ((${CONFIG} MATCHES "${board}_${label}") OR # match full board, label
			    ((${label} STREQUAL "default") AND (${CONFIG} STREQUAL "${board}")) # default label can be omitted
			)
				set(PX4_CONFIG_FILE "${PX4_SOURCE_DIR}/boards/${filename}" CACHE FILEPATH "path to PX4 CONFIG file" FORCE)
				break()
			endif()
		endif()
	endforeach()
endif()

if(NOT PX4_CONFIG_FILE)
	message(FATAL_ERROR "PX4 config file not set, try one of ${PX4_CONFIGS}")
endif()

message(STATUS "PX4 config file: ${PX4_CONFIG_FILE}")
