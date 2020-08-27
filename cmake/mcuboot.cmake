# Copyright (c) 2020 Nordic Semiconductor ASA
# SPDX-License-Identifier: Apache-2.0

# This file includes extra build system logic that is enabled when
# CONFIG_BOOTLOADER_MCUBOOT=y.
#
# It builds signed binaries using imgtool as a post-processing step
# after zephyr/zephyr.elf is created in the build directory.
#
# Since this file is brought in via include(), we do the work in a
# function to avoid polluting the top-level scope.

function(zephyr_mcuboot_tasks)
  set(keyfile "${CONFIG_MCUBOOT_SIGNATURE_KEY_FILE}")

  # Check for misconfiguration.
  if("${keyfile}" STREQUAL "")
    # No signature key file, no signed binaries. No error, though:
    # this is the documented behavior.
    return()
  elseif(NOT EXISTS "${keyfile}")
    message(FATAL_ERROR "Can't sign images for MCUboot: CONFIG_MCUBOOT_SIGNATURE_KEY_FILE=\"${keyfile}\" does not exist.")
  elseif(NOT WEST)
    message(FATAL_ERROR "Can't sign images for MCUboot: west not found. To fix, install west and ensure it's on PATH.")
  elseif(NOT (CONFIG_BUILD_OUTPUT_BIN OR CONFIG_BUILD_OUTPUT_HEX))
    message(FATAL_ERROR "Can't sign images for MCUboot: Neither CONFIG_BUILD_OUTPUT_BIN nor CONFIG_BUILD_OUTPUT_HEX is enabled, so there's nothing to sign.")
  endif()

  # Find imgtool. Even though west is installed, imgtool might not be.
  # The user may also have a custom manifest which doesn't include
  # MCUboot.
  #
  # Therefore, go with an explicitly installed imgtool first, falling
  # back on mcuboot/scripts/imgtool.py.
  if(IMGTOOL)
    set(imgtool_path "${IMGTOOL}")
  elseif(DEFINED ZEPHYR_MCUBOOT_MODULE_DIR)
    set(IMGTOOL_PY "${ZEPHYR_MCUBOOT_MODULE_DIR}/scripts/imgtool.py")
    if(EXISTS "${IMGTOOL_PY}")
      set(imgtool_path "${IMGTOOL_PY}")
    endif()
  endif()

  # No imgtool, no signed binaries.
  if(NOT DEFINED imgtool_path)
    message(FATAL_ERROR "Can't sign images for MCUboot: can't find imgtool. To fix, install imgtool with pip3, or add the mcuboot repository to the west manifest and ensure it has a scripts/imgtool.py file.")
    return()
  endif()

  # Basic 'west sign' command and output format independent arguments.
  set(west_sign ${WEST} sign --quiet --tool imgtool
    --tool-path "${imgtool_path}"
    --build-dir "${APPLICATION_BINARY_DIR}")

  # Arguments to imgtool.
  if(NOT CONFIG_MCUBOOT_EXTRA_IMGTOOL_ARGS STREQUAL "")
    # Separate extra arguments into the proper format for adding to
    # extra_post_build_commands.
    #
    # Use UNIX_COMMAND syntax for uniform results across host
    # platforms.
    separate_arguments(imgtool_extra UNIX_COMMAND ${CONFIG_MCUBOOT_EXTRA_IMGTOOL_ARGS})
  else()
    set(imgtool_extra)
  endif()
  set(imgtool_args -- --key "${keyfile}" ${imgtool_extra})

  # Extensionless prefix of any output file.
  set(output ${ZEPHYR_BINARY_DIR}/${KERNEL_NAME})

  # List of additional build byproducts.
  set(byproducts)

  # 'west sign' arguments for confirmed and unconfirmed images.
  set(unconfirmed_args)
  set(confirmed_args)

  # Set up .bin outputs.
  if(CONFIG_BUILD_OUTPUT_BIN)
    list(APPEND unconfirmed_args --bin --sbin ${output}.signed.bin)
    list(APPEND byproducts ${output}.signed.bin)

    if(CONFIG_MCUBOOT_GENERATE_CONFIRMED_IMAGE)
      list(APPEND confirmed_args --bin --sbin ${output}.signed.confirmed.bin)
      list(APPEND byproducts ${output}.signed.confirmed.bin)
    endif()
  endif()

  # Set up .hex outputs.
  if(CONFIG_BUILD_OUTPUT_HEX)
    list(APPEND unconfirmed_args --hex --shex ${output}.signed.hex)
    list(APPEND byproducts ${output}.signed.hex)

    if(CONFIG_MCUBOOT_GENERATE_CONFIRMED_IMAGE)
      list(APPEND confirmed_args --hex --shex ${output}.signed.confirmed.hex)
      list(APPEND byproducts ${output}.signed.confirmed.hex)
    endif()
  endif()

  # Add the west sign calls and their byproducts to the post-processing
  # steps for zephyr.elf.
  #
  # CMake guarantees that multiple COMMANDs given to
  # add_custom_command() are run in order, so adding the 'west sign'
  # calls to the "extra_post_build_commands" property ensures they run
  # after the commands which generate the unsigned versions.
  set_property(GLOBAL APPEND PROPERTY extra_post_build_commands COMMAND
    ${west_sign} ${unconfirmed_args} ${imgtool_args})
  if(confirmed_args)
    set_property(GLOBAL APPEND PROPERTY extra_post_build_commands COMMAND
      ${west_sign} ${confirmed_args} ${imgtool_args} --confirm)
  endif()
  set_property(GLOBAL APPEND PROPERTY extra_post_build_byproducts ${byproducts})
endfunction()

zephyr_mcuboot_tasks()
