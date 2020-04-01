# Copyright (c) 2020 Nordic Semiconductor ASA
#
# SPDX-License-Identifier: Apache-2.0

import argparse
from pathlib import Path
from shutil import which, rmtree
from subprocess import CalledProcessError

from west.commands import WestCommand
from west import log

from zcmake import run_cmake

EXPORT_DESCRIPTION = '''\
This command registers the current Zephyr installation as a CMake
config package in the CMake user package registry.

In Windows, the CMake user package registry is found in:
HKEY_CURRENT_USER\\Software\\Kitware\\CMake\\Packages\\

In Linux and MacOS, the CMake user package registry is found in:
~/.cmake/packages/'''


class ZephyrExport(WestCommand):

    def __init__(self):
        super().__init__(
            'zephyr-export',
            # Keep this in sync with the string in west-commands.yml.
            'export Zephyr installation as a CMake config package',
            EXPORT_DESCRIPTION,
            accepts_unknown_args=False)

    def do_add_parser(self, parser_adder):
        parser = parser_adder.add_parser(
            self.name,
            help=self.help,
            formatter_class=argparse.RawDescriptionHelpFormatter,
            description=self.description)
        return parser

    def do_run(self, args, unknown_args):
        # The 'share' subdirectory of the top level zephyr repository.
        share = Path(__file__).parents[2] / 'share'

        if which('ninja') is not None:
            generator = 'Ninja'
        elif which('make') is not None:
            generator = 'Unix Makefiles'
        else:
            log.die('neither ninja nor make is installed')

        run_cmake_and_clean_up(str(share / 'zephyr-package' / 'cmake'),
                               generator)
        run_cmake_and_clean_up(str(share / 'zephyrunittest-package' / 'cmake'),
                               generator)

def run_cmake_and_clean_up(path, generator):
    # Run a package installation script, cleaning up afterwards.
    #
    # Filtering out lines that start with -- ignores the normal
    # CMake status messages and instead only prints the important
    # information.

    try:
        lines = run_cmake(['-S', path, '-B', path, f'-G{generator}'],
                          capture_output=True)
    finally:
        msg = [line for line in lines if not line.startswith('-- ')]
        log.inf('\n'.join(msg))
        clean_up(path)

def clean_up(path):
    try:
        run_cmake(['--build', path, '--target', 'pristine'],
                  capture_output=True)
    except CalledProcessError:
        # Do our best to clean up even though CMake failed.
        log.wrn(f'Failed to make {path} pristine; '
                'removing known generated files...')
        for subpath in ['CMakeCache.txt', 'CMakeFiles', 'build.ninja',
                        'cmake_install.cmake', 'rules.ninja']:
            remove_if_exists(Path(path) / subpath)

def remove_if_exists(pathobj):
    if pathobj.is_file():
        log.inf(f'- removing: {pathobj}')
        pathobj.unlink()
    elif pathobj.is_dir():
        log.inf(f'- removing: {pathobj}')
        rmtree(pathobj)
