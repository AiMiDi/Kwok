from typing import List, Tuple

class Matching:
    left_pairs: List[int] # Maps L vertices to their matched R vertices (-1 if unmatched)
    right_pairs: List[int]  # Maps R vertices to their matched L vertices (-1 if unmatched)
    total_weight: int|float  # Total weight of the matching

def kwok(L: int, R: int, adj: List[List[Tuple[int, int|float]]]) -> Matching:
    """
    Computes the maximum weight matching with runtime O(E^1.4 + LR) estimated from experimental tests 
    on random graphs where |L| <= |R|. For more details, see https://arxiv.org/abs/2502.20889.

    Args:
        L_size: Number of vertices in left partition (L)
        R_size: Number of vertices in right partition (R)
        adj: Adjacency list where each element is a list of (vertex, weight) tuples representing 
             edges from a vertex in L to vertices in R.

    Note that integer weights are not required, whereas it could probably accelerate the algorithm.
    """
    ...
