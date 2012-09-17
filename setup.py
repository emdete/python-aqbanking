#!/usr/bin/env python
#
# python-aqbanking setup script
# Setup.py for python-aqbanking
#
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
	name = "python-aqbanking",
	version = "1.0.0",
	description = "aqbanking bindings for Python",
	long_description='''
''',
	cmdclass = {'build_ext': build_ext},
	ext_modules = [Extension('aqbanking', ['aqbanking.pyx', ],
		libraries=['aqbanking', ],
		include_dirs=['/usr/include', ],
		extra_compile_args=[
			'-Wno-unused-but-set-variable',
			'-Wno-cast-qual',
			],
		)],
	author = "M. Dietrich",
	author_email = "mdt@pyneo.org",
	url = "http://pyneo.org/python-aqbanking/",
	)
