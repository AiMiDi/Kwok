from setuptools import setup, find_packages, Extension
from setuptools.command.build_ext import build_ext
import os

# Check if Cython is available, use it if available
try:
    from Cython.Build import cythonize
    USE_CYTHON = True
except ImportError:
    USE_CYTHON = False

# Extension setting (.pyx for Cython, .cpp for pre-compiled C++ files if Cython is not available)
ext = '.pyx' if USE_CYTHON else '.cpp'

# Define extension modules
extensions = [
    Extension(
        "kwok", 
        ["kwok" + ext],
        include_dirs=[],  # Add C header files here if needed
        libraries=[],     # Add libraries to link against if needed
        library_dirs=[],  # Path to library files
        language="c++",   # Specify C++ as the language
    ),
]

# If Cython is available, process extension modules with cythonize
if USE_CYTHON:
    extensions = cythonize(
        extensions,
        compiler_directives={
            'language_level': '3',
            'boundscheck': False,
            'wraparound': False,
            'cdivision': True,
        }
    )

# Custom build_ext command to handle compiler flags
class BuildExt(build_ext):
    def build_extensions(self):
        compiler = self.compiler.compiler_type
        
        # Set compiler flags based on compiler type
        if compiler == 'msvc':  # Windows (Visual Studio)
            for e in self.extensions:
                e.extra_compile_args = ['/O2', '/std:c++14']
        elif compiler == 'unix':  # Assuming GCC/Clang (Linux, macOS)
            for e in self.extensions:
                e.extra_compile_args = ['-O3', '-std=c++14', '-ffast-math']
               
        build_ext.build_extensions(self)

long_description = """
# Kwok

A fast implementation of "A Faster Algorithm for Maximum Weight Matching on Unrestricted Bipartite Graphs" 
(https://arxiv.org/abs/2502.20889).
"""

if os.path.exists("README.md"):
    with open("README.md", "r", encoding="utf-8") as f:
        long_description = f.read()

setup(
    name="kwok",
    version="1.1.5",
    author="Shawxing Kwok",
    author_email="shawxingkwok@126.com",
    description="A fast maximum weight bipartite matching algorithm from 'A Faster Algorithm for Maximum Weight Matching on Unrestricted Bipartite Graphs'",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/aimidi/kwok",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Science/Research",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8", 
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
        "Programming Language :: C++",
        "Operating System :: OS Independent",
    ],
    ext_modules=extensions,
    cmdclass={'build_ext': BuildExt},
    python_requires='>=3.6',
    zip_safe=False,  # Cython modules are not zip safe
    include_package_data=True,
    package_data={
        '': ['*.pyx', '*.pxd', '*.cpp', '*.h'],
    },
)
