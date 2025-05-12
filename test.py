from kwok import kwok
from scipy.sparse import csr_matrix
from scipy.optimize import linear_sum_assignment
from scipy.sparse.csgraph import min_weight_full_bipartite_matching
import numpy as np
import random
import time

def generate_test_data(t: int, use_float=False):
    L_size = R_size = 3000
    log_L = int(t * int(np.log2(L_size)))
    
    p = np.random.permutation(R_size)
    adj = []
    for i in range(L_size):
        matched_j = p[i]
        if use_float:
            edges = [(matched_j, random.uniform(1.0, L_size))]
            others = random.sample([j for j in range(R_size) if j != matched_j], log_L - 1)
            adj.append([(j, random.uniform(1.0, L_size)) for j in [matched_j] + others])
        else:
            edges = [(matched_j, random.randint(1, L_size))]
            others = random.sample([j for j in range(R_size) if j != matched_j], log_L - 1)
            adj.append([(j, random.randint(1, L_size)) for j in [matched_j] + others])
    return L_size, R_size, adj

def main():
    # Integer weight testing
    print("===== Integer Weight Testing =====")
    for t in {0.33, 1, 3, 9, 27, 81}: 
      print(f"t={t}")
      print(f"{'Run':<4} | {'Kwok':<15} | {'LAPJVSP':<15} | {'LAPJV':<15} |")
      num_runs = 10  # For complete testing, 10 runs are recommended
      print("-" * 70)
      
      total_times = {"Kwok": 0, "LAPJVSP": 0, "LAPJV": 0}
      total_weights = {"Kwok": 0, "LAPJVSP": 0, "LAPJV": 0}

      for run in range(1, num_runs+1):
          L, R, adj = generate_test_data(t, use_float=False)
          edge_cnt = sum(len(edges) for edges in adj)
          run_weights = {}
          
          # Kwok algorithm
          start = time.time()
          kwok_result = kwok(L, R, adj)
          kwok_time = time.time() - start
          run_weights["Kwok"] = kwok_result.total_weight
          total_times["Kwok"] += kwok_time

          # LAPJVSP algorithm (Sparse min weight)
          try:
              graph = csr_matrix(([-w for i in adj for j, w in i], 
                                ([x for x in range(L) for _ in adj[x]], 
                                [j for i in adj for j, _ in i])), 
                              shape=(L, R))
              start = time.time()
              row_ind, col_ind = min_weight_full_bipartite_matching(graph)
              lapjvsp_time = time.time() - start
              lapjvsp_weight = sum(-graph[i,j] for i,j in zip(row_ind, col_ind))
              run_weights["LAPJVSP"] = lapjvsp_weight
              total_times["LAPJVSP"] += lapjvsp_time
          except Exception as e:
              run_weights["LAPJVSP"] = f"Error: {str(e)[:15]}"

          # LAPJV algorithm (Complete graph)
          try:
              # Build fully connected matrix (non-existent edges have weight 0)
              cost = np.zeros((L, R), dtype=np.int32)
              for i in range(L):
                  for j, w in adj[i]:
                      cost[i, j] = w  # Existing edges keep original weight
              
              start = time.time()
              row_ind, col_ind = linear_sum_assignment(cost, maximize=True)
              lapjv_time = time.time() - start
              lapjv_weight = cost[row_ind, col_ind].sum()
              run_weights["LAPJV"] = lapjv_weight
              total_times["LAPJV"] += lapjv_time
          except Exception as e:
              run_weights["LAPJV"] = f"Error: {str(e)[:15]}"

          # Print current round results
          print(f"{run:<4} | {run_weights['Kwok']:<15,} | "
                f"{run_weights.get('LAPJVSP', 'N/A'):<15} | "
                f"{run_weights.get('LAPJV', 'N/A'):<15} | ")

          # Accumulate weights
          for algo in ["Kwok", "LAPJVSP", "LAPJV"]:
              if isinstance(run_weights.get(algo, 0), (int, float)):
                  total_weights[algo] += run_weights[algo]

      # Print final statistics
      print("\nFinal statistics with edge count: " + str(edge_cnt))
      print(f"| {'Algorithm':<8} | {'Total time(s)':<12} |")
      print("|----------|-------------|")
      for algo in ["Kwok", "LAPJVSP", "LAPJV"]:
          avg_weight = total_weights[algo]/num_runs if algo in total_weights else "N/A"
          print(f"| {algo:<8} | {total_times[algo]:<11.1f}")

    # Floating point weight testing
    print("\n\n===== Floating Point Weight Testing =====")
    for t in {0.33, 1, 3}: 
      print(f"t={t}")
      print(f"{'Run':<4} | {'Kwok':<15} | {'LAPJVSP':<15} | {'LAPJV':<15} |")
      num_runs = 5  # Fewer runs for floating point tests
      print("-" * 70)
      
      total_times = {"Kwok": 0, "LAPJVSP": 0, "LAPJV": 0}
      total_weights = {"Kwok": 0, "LAPJVSP": 0, "LAPJV": 0}

      for run in range(1, num_runs+1):
          L, R, adj = generate_test_data(t, use_float=True)
          edge_cnt = sum(len(edges) for edges in adj)
          run_weights = {}
          
          # Kwok algorithm
          start = time.time()
          kwok_result = kwok(L, R, adj)
          kwok_time = time.time() - start
          run_weights["Kwok"] = kwok_result.total_weight
          total_times["Kwok"] += kwok_time

          # LAPJVSP algorithm (Sparse min weight)
          try:
              graph = csr_matrix(([-w for i in adj for j, w in i], 
                                ([x for x in range(L) for _ in adj[x]], 
                                [j for i in adj for j, _ in i])), 
                              shape=(L, R))
              start = time.time()
              row_ind, col_ind = min_weight_full_bipartite_matching(graph)
              lapjvsp_time = time.time() - start
              lapjvsp_weight = sum(-graph[i,j] for i,j in zip(row_ind, col_ind))
              run_weights["LAPJVSP"] = lapjvsp_weight
              total_times["LAPJVSP"] += lapjvsp_time
          except Exception as e:
              run_weights["LAPJVSP"] = f"Error: {str(e)[:15]}"

          # LAPJV algorithm (Complete graph)
          try:
              # Build fully connected matrix (non-existent edges have weight 0)
              cost = np.zeros((L, R), dtype=np.float64)
              for i in range(L):
                  for j, w in adj[i]:
                      cost[i, j] = w
              
              start = time.time()
              row_ind, col_ind = linear_sum_assignment(cost, maximize=True)
              lapjv_time = time.time() - start
              lapjv_weight = cost[row_ind, col_ind].sum()
              run_weights["LAPJV"] = lapjv_weight
              total_times["LAPJV"] += lapjv_time
          except Exception as e:
              run_weights["LAPJV"] = f"Error: {str(e)[:15]}"

          # Print current round results
          print(f"{run:<4} | {run_weights['Kwok']:<15.2f} | "
                f"{run_weights.get('LAPJVSP', 'N/A'):<15} | "
                f"{run_weights.get('LAPJV', 'N/A'):<15} | ")

          # Accumulate weights
          for algo in ["Kwok", "LAPJVSP", "LAPJV"]:
              if isinstance(run_weights.get(algo, 0), (int, float)):
                  total_weights[algo] += run_weights[algo]

      # Print final statistics
      print("\nFinal statistics with edge count: " + str(edge_cnt))
      print(f"| {'Algorithm':<8} | {'Total time(s)':<12} |")
      print("|----------|-------------|")
      for algo in ["Kwok", "LAPJVSP", "LAPJV"]:
          avg_weight = total_weights[algo]/num_runs if algo in total_weights else "N/A"
          print(f"| {algo:<8} | {total_times[algo]:<11.1f}")

if __name__ == "__main__":
    main()