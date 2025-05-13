cimport cython
from libcpp.limits cimport numeric_limits
from libcpp.vector cimport vector
from libcpp.queue cimport queue
from libcpp cimport bool
from dataclasses import dataclass
from typing import List

@dataclass
class Matching:
    left_pairs: List[int] # Maps L vertices to their matched R vertices (-1 if unmatched)
    right_pairs: List[int]  # Maps R vertices to their matched L vertices (-1 if unmatched)
    total_weight: int|double  # Total weight of the matching

ctypedef struct Edge_int:
    int vertex
    int weight  

ctypedef struct Edge_double:
    int vertex
    double weight  

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
cdef bool kwok_advance(int r, vector[int]& right_pairs, vector[int]& left_pairs, vector[bool]& right_on_edge, 
                 vector[bool]& right_visited, vector[int]& visited_rights,
                 vector[int]& visited_lefts, queue[int]& q,
                 vector[int]& right_parents, int L_size) noexcept nogil:
    right_on_edge[r] = False
    right_visited[r] = True
    visited_rights.push_back(r)
    
    cdef int l = right_pairs[r]    
    if l != -1:
        # Add to queue
        q.push(l)
        visited_lefts.push_back(l)
        return False
      # Apply found augmenting path
    cdef int current_r = r
    cdef int prev_r
    while current_r != -1:
        l = right_parents[current_r]
        prev_r = left_pairs[l]
        left_pairs[l] = current_r
        right_pairs[current_r] = l
        current_r = prev_r
    return True

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
cdef void kwok_bfs_int(int first_unmatched_r, vector[int]& right_parents, vector[int]& left_pairs, 
                                        vector[int]& right_pairs, vector[bool]& right_on_edge, vector[bool]& right_visited,
                                        vector[int]& visited_rights,
                                        vector[int]& visited_lefts,
                                        vector[int]& on_edge_rights,
                                        queue[int]& q, vector[int]& left_labels, vector[int]& right_labels, vector[int]& slacks,
                                        vector[vector[Edge_int]]& adj_cpp, int L_size) noexcept nogil:
    cdef int l, r, diff, delta
    cdef int w
    cdef Edge_int edge
    
    while True:
        # Process queue
        while not q.empty():
            l = q.front()
            q.pop()
            
            if left_labels[l] == 0:
                right_parents[first_unmatched_r] = l
                if kwok_advance(first_unmatched_r, right_pairs, left_pairs, right_on_edge, right_visited,
                          visited_rights, visited_lefts, q, right_parents, L_size):
                    return
            if slacks[first_unmatched_r] > left_labels[l]:
                slacks[first_unmatched_r] = left_labels[l]
                right_parents[first_unmatched_r] = l
                
                if not right_on_edge[first_unmatched_r]:
                    on_edge_rights.push_back(first_unmatched_r)
                    right_on_edge[first_unmatched_r] = True
            
            # Process adjacent edges
            for i in range(adj_cpp[l].size()):
                edge = adj_cpp[l][i]
                r = edge.vertex
                w = edge.weight
                
                if right_visited[r]:
                    continue
                diff = left_labels[l] + right_labels[r] - <int>w
                if diff == 0:
                    right_parents[r] = l
                    if kwok_advance(r, right_pairs, left_pairs, right_on_edge, right_visited,
                              visited_rights, visited_lefts, q, right_parents, L_size):
                        return
                elif slacks[r] > diff:
                    right_parents[r] = l
                    slacks[r] = diff
                    if not right_on_edge[r]:
                        on_edge_rights.push_back(r)
                        right_on_edge[r] = True
        
        # Calculate delta
        delta = numeric_limits[int].max()
        for i in range(on_edge_rights.size()):
            r = on_edge_rights[i]
            if right_on_edge[r]:
                if slacks[r] < delta:
                    delta = slacks[r]
        
        # Update labels
        for i in range(visited_lefts.size()):
            l = visited_lefts[i]
            left_labels[l] -= delta
        
        for i in range(visited_rights.size()):
            r = visited_rights[i]
            right_labels[r] += delta
        
        # Check if slack is zero
        for i in range(on_edge_rights.size()):
            r = on_edge_rights[i]
            if right_on_edge[r]:
                slacks[r] -= delta
                if slacks[r] == 0 and kwok_advance(r, right_pairs, left_pairs, right_on_edge, right_visited,
                                             visited_rights, visited_lefts, q, right_parents, L_size):
                    return

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
cdef void kwok_bfs_double(int first_unmatched_r, vector[int]& right_parents, vector[int]& left_pairs, 
                                        vector[int]& right_pairs, vector[bool]& right_on_edge, vector[bool]& right_visited,
                                        vector[int]& visited_rights,
                                        vector[int]& visited_lefts,
                                        vector[int]& on_edge_rights,
                                        queue[int]& q, vector[double]& left_labels, vector[double]& right_labels, vector[double]& slacks,
                                        vector[vector[Edge_double]]& adj_cpp, int L_size) noexcept nogil:
    cdef int l, r
    cdef double w, diff, delta
    cdef Edge_double edge
    
    while True:
        # Process queue
        while not q.empty():
            l = q.front()
            q.pop()
            
            if abs(left_labels[l]) < 1e-10:
                right_parents[first_unmatched_r] = l
                if kwok_advance(first_unmatched_r, right_pairs, left_pairs, right_on_edge, right_visited,
                          visited_rights, visited_lefts, q, right_parents, L_size):
                    return
            if slacks[first_unmatched_r] > left_labels[l]:
                slacks[first_unmatched_r] = left_labels[l]
                right_parents[first_unmatched_r] = l
                
                if not right_on_edge[first_unmatched_r]:
                    on_edge_rights.push_back(first_unmatched_r)
                    right_on_edge[first_unmatched_r] = True
            
            # Process adjacent edges
            for i in range(adj_cpp[l].size()):
                edge = adj_cpp[l][i]
                r = edge.vertex
                w = edge.weight
                
                if right_visited[r]:
                    continue
                diff = left_labels[l] + right_labels[r] - w
                if abs(diff) < 1e-10:
                    right_parents[r] = l
                    if kwok_advance(r, right_pairs, left_pairs, right_on_edge, right_visited,
                              visited_rights, visited_lefts, q, right_parents, L_size):
                        return
                elif slacks[r] > diff:
                    right_parents[r] = l
                    slacks[r] = diff
                    if not right_on_edge[r]:
                        on_edge_rights.push_back(r)
                        right_on_edge[r] = True
        
        # Calculate delta
        delta = numeric_limits[double].max()
        for i in range(on_edge_rights.size()):
            r = on_edge_rights[i]
            if right_on_edge[r]:
                if slacks[r] < delta:
                    delta = slacks[r]
        
        # Update labels
        for i in range(visited_lefts.size()):
            l = visited_lefts[i]
            left_labels[l] -= delta
        
        for i in range(visited_rights.size()):
            r = visited_rights[i]
            right_labels[r] += delta
        
        # Check if slack is zero
        for i in range(on_edge_rights.size()):
            r = on_edge_rights[i]
            if right_on_edge[r]:
                slacks[r] -= delta
                if abs(slacks[r]) < 1e-10 and kwok_advance(r, right_pairs, left_pairs, right_on_edge, right_visited,
                                             visited_rights, visited_lefts, q, right_parents, L_size):
                    return

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef void kwok_int(int L_size, int R_size, list adj, bool keeps_virtual_matching, vector[int]& left_pairs, vector[int]& right_pairs, int& total) noexcept nogil:
    cdef vector[int] right_parents
    cdef vector[bool] right_visited
    cdef vector[bool] right_on_edge
    cdef vector[int] left_labels
    cdef vector[int] right_labels
    cdef vector[int] slacks

    right_parents.resize(R_size, -1)
    right_visited.resize(R_size, False)
    right_on_edge.resize(R_size, False)
    left_labels.resize(L_size, 0)
    right_labels.resize(R_size, 0)
    slacks.resize(R_size, numeric_limits[int].max())
    
    # Use C++ vectors instead of Python lists
    cdef vector[int] visited_lefts
    cdef vector[int] visited_rights
    cdef vector[int] on_edge_rights
    cdef queue[int] q
    
    # Convert Python adjacency list to C++ vector container
    cdef vector[vector[Edge_int]] adj_cpp
    adj_cpp.resize(L_size)
    
    # Pre-allocate container sizes to reduce memory reallocation
    visited_lefts.reserve(L_size)
    visited_rights.reserve(R_size)
    on_edge_rights.reserve(R_size)
    
    # Initialize arrays
    cdef int i, l, r, max_weight
    cdef int w
    cdef Edge_int edge
    
    with gil:
        # GIL needed to handle Python objects
        for l in range(L_size):
            adj_cpp[l].reserve(len(adj[l]))
            for edge_item in adj[l]:
                edge.vertex = edge_item[0]
                edge.weight = edge_item[1]
                adj_cpp[l].push_back(edge)
    
    # Initialize left_labels values as maximum edge weight
    for l in range(L_size):
        max_weight = 0
        for i in range(adj_cpp[l].size()):
            w = adj_cpp[l][i].weight
            if <int>w > max_weight:
                max_weight = <int>w
        left_labels[l] = max_weight
    
    # Initial greedy matching
    for l in range(L_size):
        for i in range(adj_cpp[l].size()):
            r = adj_cpp[l][i].vertex
            w = adj_cpp[l][i].weight
            if right_pairs[r] == -1 and left_labels[l] + right_labels[r] == <int>w:
                left_pairs[l] = r
                right_pairs[r] = l
                break
    
    # Main loop
    cdef int first_unmatched_r
    for l in range(L_size):
        if left_pairs[l] != -1:
            continue
        
        # Reset queue and states
        while not q.empty():
            q.pop()
        
        # Reset visit status
        for i in range(visited_rights.size()):
            r = visited_rights[i]
            right_visited[r] = False
        
        for i in range(on_edge_rights.size()):
            r = on_edge_rights[i]
            right_on_edge[r] = False
            slacks[r] = numeric_limits[int].max()
        
        visited_lefts.clear()
        visited_rights.clear()
        on_edge_rights.clear()
        
        visited_lefts.push_back(l)
        q.push(l)
        
        # Find the first unmatched right node
        first_unmatched_r = -1
        for r in range(R_size):
            if right_pairs[r] == -1:
                first_unmatched_r = r
                break
        
        kwok_bfs_int(first_unmatched_r, right_parents, left_pairs, 
                                      right_pairs, right_on_edge, right_visited,
                                      visited_rights, visited_lefts,
                                      on_edge_rights, q, left_labels, right_labels, slacks,
                                      adj_cpp, L_size)
    
    # Calculate total weight
    total = 0    
    cdef bool matched
    
    for l in range(L_size):
        matched = False
        r = left_pairs[l]
        if r != -1:
            for i in range(adj_cpp[l].size()):
                if adj_cpp[l][i].vertex == r:
                    total += adj_cpp[l][i].weight
                    matched = True
                    break
            
            # Remove virtual matching
            if not keeps_virtual_matching and matched:
                left_pairs[l] = -1
                right_pairs[r] = -1

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef void kwok_double(int L_size, int R_size, list adj, bool keeps_virtual_matching, vector[int]& left_pairs, vector[int]& right_pairs, double& total) noexcept nogil:
    cdef vector[int] right_parents
    cdef vector[bool] right_visited
    cdef vector[bool] right_on_edge
    cdef vector[double] left_labels
    cdef vector[double] right_labels
    cdef vector[double] slacks
    
    right_parents.resize(R_size, -1)
    right_visited.resize(R_size, False)
    right_on_edge.resize(R_size, False)
    left_labels.resize(L_size, 0)
    right_labels.resize(R_size, 0)
    slacks.resize(R_size, numeric_limits[double].max())
    
    # Use C++ vectors instead of Python lists
    cdef vector[int] visited_lefts
    cdef vector[int] visited_rights
    cdef vector[int] on_edge_rights
    cdef queue[int] q
    
    # Convert Python adjacency list to C++ vector container
    cdef vector[vector[Edge_double]] adj_cpp
    adj_cpp.resize(L_size)
    
    # Pre-allocate container sizes to reduce memory reallocation
    visited_lefts.reserve(L_size)
    visited_rights.reserve(R_size)
    on_edge_rights.reserve(R_size)
    
    # Initialize arrays
    cdef int i, l, r
    cdef double w, max_weight
    cdef Edge_double edge
    
    with gil:
        for l in range(L_size):
            adj_cpp[l].reserve(len(adj[l]))
            for edge_item in adj[l]:
                edge.vertex = edge_item[0]
                edge.weight = edge_item[1]
                adj_cpp[l].push_back(edge)
    
    # Initialize left_labels values as maximum edge weight
    for l in range(L_size):
        max_weight = 0.0
        for i in range(adj_cpp[l].size()):
            w = adj_cpp[l][i].weight
            if w > max_weight:
                max_weight = w
        left_labels[l] = max_weight
    
    # Initial greedy matching
    for l in range(L_size):
        for i in range(adj_cpp[l].size()):
            r = adj_cpp[l][i].vertex
            w = adj_cpp[l][i].weight
            if right_pairs[r] == -1 and abs(left_labels[l] + right_labels[r] - w) < 1e-10:  # Using epsilon comparison for doubles
                left_pairs[l] = r
                right_pairs[r] = l
                break
    
    # Main loop
    cdef int first_unmatched_r
    for l in range(L_size):
        if left_pairs[l] != -1:
            continue
        
        # Reset queue and states
        while not q.empty():
            q.pop()
        
        # Reset visit status
        for i in range(visited_rights.size()):
            r = visited_rights[i]
            right_visited[r] = False
        
        for i in range(on_edge_rights.size()):
            r = on_edge_rights[i]
            right_on_edge[r] = False
            slacks[r] = numeric_limits[double].max()
        
        visited_lefts.clear()
        visited_rights.clear()
        on_edge_rights.clear()
        
        visited_lefts.push_back(l)
        q.push(l)
        
        # Find the first unmatched right node
        first_unmatched_r = -1
        for r in range(R_size):
            if right_pairs[r] == -1:
                first_unmatched_r = r
                break
                
        kwok_bfs_double(first_unmatched_r, right_parents, left_pairs, 
                                        right_pairs, right_on_edge, right_visited,
                                        visited_rights, visited_lefts,
                                        on_edge_rights, q, left_labels, right_labels, slacks,
                                        adj_cpp, L_size)
    
    # Calculate total weight
    total = 0.0
    cdef bool matched
    
    for l in range(L_size):
        matched = False
        r = left_pairs[l]
        if r != -1:
            for i in range(adj_cpp[l].size()):
                if adj_cpp[l][i].vertex == r:
                    total += adj_cpp[l][i].weight
                    matched = True
                    break
            
            # Remove virtual matching
            if not keeps_virtual_matching and matched:
                left_pairs[l] = -1
                right_pairs[r] = -1

# Python wrapper function
def kwok(int l_size, int r_size, list adj, bool keeps_virtual_matching = False):
    """
    Implements "A Faster Algorithm for Maximum Weight Matching on Unrestricted Bipartite Graphs"
    with runtime O(E^1.4 + LR) estimated from experimental tests on random graphs where |L| <= |R|.
    For more details, see https://arxiv.org/abs/2502.20889.

    Args:
        l_size: Number of vertices in left partition (L)
        r_size: Number of vertices in right partition (R)
        adj: Adjacency list where each element is a list of (vertex, weight) tuples representing 
             edges from a vertex in L to vertices in R.
        keeps_virtual_matching(default = false): The algorithm's output is mathematically equivalent to the solution obtained by computing matches on a complete bipartite graph augmented with zero-weight virtual edges. However, for computational efficiency, the implementation operates directly on the original sparse graph structure. When the keeps_virtual_matching parameter is disabled (false), the algorithm automatically filters out any zero-weight matches from the final results.

    Note that integer weights are not required, whereas it could probably accelerate the algorithm.
    """
    cdef bool is_double = False
    
    if l_size > 0 and len(adj) > 0 and len(adj[0]) > 0:
        for edge in adj[0]:
            if isinstance(edge[1], float) and not edge[1].is_integer():
                is_double = True
                break
    
    cdef vector[int] left_pairs = vector[int](l_size, -1)
    cdef vector[int] right_pairs = vector[int](r_size, -1)
    cdef int total_int = 0
    cdef double total_double = 0.0
    
    if is_double:
        with nogil:
            kwok_double(l_size, r_size, adj, keeps_virtual_matching, left_pairs, right_pairs, total_double)
        
        # Convert C++ vectors to Python lists
        left_pairs_py = [left_pairs[i] for i in range(l_size)]
        right_pairs_py = [right_pairs[i] for i in range(r_size)]

        return Matching(
            left_pairs=left_pairs_py,
            right_pairs=right_pairs_py,
            total_weight=total_double
        )
    else:
        with nogil:
            kwok_int(l_size, r_size, adj, keeps_virtual_matching, left_pairs, right_pairs, total_int)
        
        # Convert C++ vectors to Python lists
        left_pairs_py = [left_pairs[i] for i in range(l_size)]
        right_pairs_py = [right_pairs[i] for i in range(r_size)]

        return Matching(
            left_pairs=left_pairs_py,
            right_pairs=right_pairs_py,
            total_weight=total_int
        )
