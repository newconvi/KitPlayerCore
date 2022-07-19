# This file may optionally do:
#
# 1. Check for dependencies of exported targets. Example:
#
# include(CMakeFindDependencyMacro)
# find_dependency(MYDEP REQUIRED)
#
# find_dependency() has the same syntax as find_package()
#
# 2. Capture values from configuration. Example:
#
# set(my-config-var )
#
# 3. Other required setup when importing targets from another project
#
# See also:
# https://cliutils.gitlab.io/modern-cmake/chapters/install.html
#
include("${CMAKE_CURRENT_LIST_DIR}/uchardet-targets.cmake")
