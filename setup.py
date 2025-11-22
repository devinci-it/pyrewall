from setuptools import setup, find_packages

setup(
    name="pyrewall",
    version="0.1.0",
    author="devinci-it",
    description="IPTables rule builder CLI",
    packages=find_packages(),  # automatically finds your pyrewall/ package
    install_requires=[
        "textual>=0.10", 
    ],
    entry_points={
        'console_scripts': [
            'pyrewall = pyrewall.app:main',
        ],
    },
    python_requires='>=3.8',
)
