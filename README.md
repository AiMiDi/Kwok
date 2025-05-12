# Kwok

A Cython-based implementation of "A Faster Algorithm for Maximum Weight Matching on Unrestricted Bipartite Graphs" that supports multiple Python versions and platforms.

## About

Kwok implements a fast maximum weight bipartite matching algorithm based on the paper "A Faster Algorithm for Maximum Weight Matching on Unrestricted Bipartite Graphs" (https://arxiv.org/abs/2502.20889). The algorithm achieves runtime O(E^1.4 + LR) estimated from experimental tests on random graphs where |L| <= |R|.

The algorithm is particularly efficient for dense graphs and outperforms traditional implementations of the Hungarian algorithm in many practical scenarios.

## Installation

```bash
pip install kwok
```

## Usage

```python
import kwok

# Example usage
L_size = 3  # Number of vertices in left partition
R_size = 3  # Number of vertices in right partition
adj = [
    [(0, 10), (1, 5), (2, 1)],  # Edges from left vertex 0
    [(0, 2), (1, 15), (2, 0)],  # Edges from left vertex 1
    [(0, 0), (1, 8), (2, 12)]   # Edges from left vertex 2
]

# Solve the matching problem
matching = kwok.kwok(L_size, R_size, adj)
print("Left pairs:", matching.left_pairs)
print("Right pairs:", matching.right_pairs)
print("Total weight:", matching.total_weight)
```

### API Reference

#### kwok(L_size, R_size, adj)

Computes the maximum weight matching in a bipartite graph.

**Parameters:**
- `L_size` (int): Number of vertices in left partition (L)
- `R_size` (int): Number of vertices in right partition (R)
- `adj` (list): Adjacency list where each element is a list of (vertex, weight) tuples representing edges from a vertex in L to vertices in R

**Returns:**
- `Matching`: A dataclass with the following attributes:
  - `left_pairs` (list): Maps L vertices to their matched R vertices (-1 if unmatched)
  - `right_pairs` (list): Maps R vertices to their matched L vertices (-1 if unmatched)
  - `total_weight` (int|float): Total weight of the matching

**Note:** Integer weights are not required, but using integers may improve performance.

## Development

To build the package locally:

```bash
pip install -e .
```

## Building wheels with cibuildwheel

To build wheels for multiple Python versions and platforms, we use [cibuildwheel](https://github.com/pypa/cibuildwheel).

cibuildwheel is a powerful tool that:
- Builds wheels for CPython and PyPy on Windows, macOS, and Linux
- Handles platform-specific wheels (including manylinux)
- Tests the built wheels in isolated environments
- Integrates with CI services like GitHub Actions

### Local testing with cibuildwheel

To test cibuildwheel locally:

```bash
pip install cibuildwheel
python -m cibuildwheel --platform linux
```

Available platforms are: `linux`, `windows`, and `macos`.

### CI integration

This project is configured to automatically build wheels using GitHub Actions.
See the `.github/workflows/build_wheels.yml` file for the configuration.
