from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy as np
import sys

if sys.platform == "win32":
    extra_compile_args = ["/O2", "/fp:fast", "/Gy", "/Oi", "/GL"]
    extra_link_args = ["/LTCG"]
else:
    extra_compile_args = ["-O3", "-march=native", "-ffast-math", "-ftree-vectorize"]
    extra_link_args = ["-flto"]

ext_modules = [
    Extension(
        "kwok",
        ["kwok.pyx"],
        language="c++",
        include_dirs=[np.get_include()], 
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
        define_macros=[("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION")],
    )
]

cython_directives = {
    'binding': False,      
    'boundscheck': False, 
    'wraparound': False,   
    'cdivision': True,     
    'language_level': 3,  
    'infer_types': True,   
    'nonecheck': False,   
    'initializedcheck': False,  
    'optimize.use_switch': True,  
    'optimize.unpack_method_calls': True,  
}

setup(
    name="kwok",
    ext_modules=cythonize(ext_modules, compiler_directives=cython_directives)
)