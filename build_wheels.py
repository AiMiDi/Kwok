#!/usr/bin/env python

import os
import subprocess
import sys

def build_wheels():
    print("Building wheel...")
    subprocess.check_call([sys.executable, "-m", "pip", "wheel", ".", "-w", "dist/"])

def build_sdist():
    print("Building source distribution...")
    subprocess.check_call([sys.executable, "setup.py", "sdist"])

if __name__ == "__main__":
    os.makedirs("dist", exist_ok=True)
    
    build_wheels()
    build_sdist()
    
    print("\nBuild completed. Wheel and sdist packages are in the 'dist' directory.")
