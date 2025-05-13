from typing import List, Tuple

class Matching:
    left_pairs: List[int] # Maps L vertices to their matched R vertices (-1 if unmatched)
    right_pairs: List[int]  # Maps R vertices to their matched L vertices (-1 if unmatched)
    total_weight: int|float  # Total weight of the matching

def kwok(l_size: int, r_size: int, adj: List[List[Tuple[int, int | float]]], keeps_virtual_matching: bool) -> Matching:
    """
    Implements "A Faster Algorithm for Maximum Weight Matching on Unrestricted Bipartite Graphs"
    with runtime O(E^1.4 + LR) estimated from experimental tests on random graphs where |L| <= |R|.
    For more details, see https://arxiv.org/abs/2502.20889.

    Args:
        l_size: Number of vertices in left partition (L)
        r_size: Number of vertices in right partition (R)
        adj: Adjacency list where each element is a list of (vertex, weight) tuples representing
             edges from a vertex in L to vertices in R.
        keeps_virtual_matching: The algorithm's output is mathematically equivalent to the solution obtained by computing matches on a complete bipartite graph augmented with zero-weight virtual edges. However, for computational efficiency, the implementation operates directly on the original sparse graph structure. When the keeps_virtual_matching parameter is disabled (false), the algorithm automatically filters out any zero-weight matches from the final results.

    Note that integer weights are not required, whereas it could probably accelerate the algorithm.
    """
    ...
