#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "uchardet::libuchardet" for configuration "Release"
set_property(TARGET uchardet::libuchardet APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(uchardet::libuchardet PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libuchardet.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS uchardet::libuchardet )
list(APPEND _IMPORT_CHECK_FILES_FOR_uchardet::libuchardet "${_IMPORT_PREFIX}/lib/libuchardet.a" )

# Import target "uchardet::uchardet" for configuration "Release"
set_property(TARGET uchardet::uchardet APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(uchardet::uchardet PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/bin/uchardet"
  )

list(APPEND _IMPORT_CHECK_TARGETS uchardet::uchardet )
list(APPEND _IMPORT_CHECK_FILES_FOR_uchardet::uchardet "${_IMPORT_PREFIX}/bin/uchardet" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
