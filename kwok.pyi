from typing import List, Tuple, Any

class Matching:
    left_pairs: List[int] # Maps L vertices to their matched R vertices (-1 if unmatched)
    right_pairs: List[int]  # Maps R vertices to their matched L vertices (-1 if unmatched)
    total_weight: int|float  # Total weight of the matching

def kwok(L: int, R: int, adj: List[List[Tuple[int, int|float]]]) -> Matching:
    """
    Find maximum weight matching in a bipartite graph.
    
    Args:
        L: Number of vertices in the left part
        R: Number of vertices in the right part
        adj: Adjacency list where adj[i] contains edges (j, weight) for vertex i in left part
             and j in right part
             
    Returns:
        Matching object with total_weight and matching attributes
    """
    ...
