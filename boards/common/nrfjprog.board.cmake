# SPDX-License-Identifier: Apache-2.0

set(NRFJPROG_COMMON_RUNNER_ARGS)

if(CONFIG_SOC_SERIES_NRF51X)
  list(APPEND NRFJPROG_COMMON_RUNNER_ARGS "--nrf-family=NRF51")
elseif(CONFIG_SOC_SERIES_NRF52X)
  list(APPEND NRFJPROG_COMMON_RUNNER_ARGS "--nrf-family=NRF52")
elseif(CONFIG_SOC_SERIES_NRF53X)
  list(APPEND NRFJPROG_COMMON_RUNNER_ARGS "--nrf-family=NRF53")

  # As of now, we only have one SoC to support, so we get the
  # --coprocessor value by matching against nRF5340 specific Kconfig
  # symbols.
  if(CONFIG_SOC_NRF5340_CPUAPP)
    list(APPEND NRFJPROG_COMMON_RUNNER_ARGS "--tool-opt=--coprocessor CP_APPLICATION")
  elseif(CONFIG_SOC_NRF5340_CPUNET)
    list(APPEND NRFJPROG_COMMON_RUNNER_ARGS "--tool-opt=--coprocessor CP_NETWORK")
  else()
    message(WARNING "Unknown nRF53 SoC; please update nrfjprog.board.cmake")
  endif()
elseif(CONFIG_SOC_SERIES_NRF91X)
  list(APPEND NRFJPROG_COMMON_RUNNER_ARGS "--nrf-family=NRF91")
else()
  message(WARNING "Unknown nRF SoC series; please update nrfjprog.board.cmake")
endif()

board_set_flasher_ifnset(nrfjprog)
board_finalize_runner_args(nrfjprog ${NRFJPROG_COMMON_RUNNER_ARGS})
