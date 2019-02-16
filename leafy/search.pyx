"""Graph search algorithms.

This module contains graph search algorithms, mainly:
- DFS: Depth First Search
- BFS: Breadth First Search

Each search algorithm is specific to finding certain attributes about the graph
structure like: Cycles, Bridges, Colourability, etc. These attributes are documented
under each algorithm.
"""

cimport numpy
import numpy as np
cimport cython

from cgraph cimport GraphBase
from data_structure cimport AdjacencyList

cdef class DFS:
    """Depth First Search of a graph starting from a defined node.

    Run a depth first search on a graph recording its structural attributes. By running DFS
    we can find out:
    - Tree links: These are edges from nodes to other unvisited nodes.
    - Back links: These are edges from nodes to visited ancentors.
    - Down links: These are edges from nodes to visited decendents.
    - Parent Links: These are edges from nodes back to their parents.
    - Simple Path: A simple path from the start node to a sink node.
    - Two Colourability: Can the graph be two colourable? Can we give each node a colour
        that is different to it's neighbours.
    - Bridges: All the edges that if removed would split the graph.
    - Articulation Points: All the nodes that if removed would split the graph.
    - Visited nodes: All the nodes reachable from the start node.
    - Unvisited nodes: All the nodes not reachable from the start node.

    Parameters
    ----------
    graph : GraphBase
        An instance of either Graph or SparseGraph.
    start_node : int
        The node index to start from.
    sink_node : int, optional
        The node to stop searching at.

    Examples
    --------
    Before you're able to interogate the graph structure you have to run the DFS.

    >>> g = Graph(200)
    >>> g.add(1, 0)
    >>> dfs = DFS(g, 0)
    >>> dfs.run()

    Once the algorithm has run you can then as the dfs for it's attributes:
    >>> dfs.two_colourability
    False

    """

    def __cinit__(self, GraphBase graph not None, int start_node, int sink_node=-1):
        assert -1 < start_node < graph.length, "DFS start node must be on the graph."
        assert -1 <= sink_node < graph.length, "DFS sink node mush be on the graph."

        self._graph = graph
        self._start_node = start_node
        self._sink_node = sink_node

        self._pre = np.full(self._graph.length, -1, dtype=np.intc)  # Pre search counter
        self._st = np.full(self._graph.length, -1, dtype=np.intc)  # Structural parent
        self._post = np.full(self._graph.length, -1, dtype=np.intc) # Post search counter
        self._lows = np.full(self._graph.length, -1, dtype=np.intc) # Used to find bridges
        self._cycle = np.full(self._graph.length, -1, dtype=np.intc)
        self._colour = np.full(self._graph.length, -1, dtype=np.intc) # Colour index for
        self._art = np.full(self._graph.length, -1, dtype=np.intc)

        self._bridges = AdjacencyList(self._graph.length)
        self._tree_links = AdjacencyList(self._graph.length)
        self._back_links = AdjacencyList(self._graph.length)
        self._down_links = AdjacencyList(self._graph.length)
        self._parent_links = AdjacencyList(self._graph.length)

        self._pre_counter = 0
        self._post_counter = 0
        self._edge_count = 0
        self._dfs_run = 0

    @property
    def tree_links(self):
        """dict of int to list of int: All the nodes visited for the first time from each node."""
        assert self._dfs_run != 0, "Run the DFS before calling results."
        return self._tree_links.as_py_dict()

    @property
    def back_links(self):
        """dict of int to list of int: All the ancestor nodes visited for the from each node."""
        assert self._dfs_run != 0, "Run the DFS before calling results."
        return self._back_links.as_py_dict()

    @property
    def down_links(self):
        """dict of int to list of int: All the decendent nodes visited for the from each node."""
        assert self._dfs_run != 0, "Run the DFS before calling results."
        return self._down_links.as_py_dict()

    @property
    def parent_links(self):
        """dict of int to list of int: All the nodes that link back to their parents."""
        assert self._dfs_run != 0, "Run the DFS before calling results."
        return self._parent_links.as_py_dict()

    @property
    def bridges(self):
        """tuple of (int, int): All the links that if removed would split the graph."""
        assert self._dfs_run != 0, "Run the DFS before calling results."
        return self._bridges.as_py_dict()

    @property
    def articulation_points(self):
        """list of int: All the nodes that if removed would split the graph."""
        assert self._dfs_run != 0, "Run the DFS before calling results."

    @property
    def colours(self):
        """dict of int to list of int: List of nodes by colour index."""
        assert self._dfs_run != 0, "Run the DFS before calling results."

    @property
    def two_colourable(self):
        """bool: True if the graph is two colourable."""
        assert self._dfs_run != 0, "Run the DFS before calling results."

    @property
    def visited(self):
        """List of ints: All the nodes visited by the DFS run."""
        assert self._dfs_run != 0, "Run the DFS before calling results."

    @property
    def unvisited(self):
        """List of ints: All the nodes unvisited by the DFS"""
        assert self._dfs_run != 0, "Run the DFS before calling results."

    @property
    def visited_edge_count(self):
        """int: Number of visited edges during the DFS"""
        assert self._dfs_run != 0, "Run the DFS before calling results."

    cpdef list simple_path(self, int sink_node):
        """Display the simple path to get from the start node to a sink node
        
        Parameters
        ----------
        sink_node : int
            The destination node of the path.
            
        Returns
        -------
        list
            all the nodes on the path from (inc.) the start node to (inc.) the sink node.
        """
        assert self._dfs_run != 0, "Run the DFS before calling results."
        cdef list path = []
        st = self._st[sink_node]
        path.append(sink_node)
        while st != -1:
            path.insert(0, st)
            st = self._st[st]
        return path

    cpdef void run(self):
        self._dfs_run = 1
        if self._graph.dense == 1:
            self._run_dense(self._start_node, -1, 0)
        else:
            self._run_sparse(self._start_node, -1, 0)

    cdef void _run_sparse(self, int v, int st, int colour):
        pass

    @cython.boundscheck(False)
    @cython.initializedcheck(False)
    @cython.wraparound(False)
    cdef void _run_dense(self, int v, int st, int colour):
        if v == self._sink_node:
            return

        cdef int w

        self._st[v] = st
        self._colour[v] = colour
        self._pre[v] = self._pre_counter
        self._lows[v] = self._pre_counter
        self._pre_counter += 1

        for w in range(self._graph.length):
            if self._graph.adj_matrix[v][w] == 0:
                continue

            self._edge_count += 1
            if self._pre[w] == -1:
                self._tree_links.append(v, w)
                self._run_dense(w, v, abs(colour - 1))
                self._lows[v] = min(self._lows[v], self._lows[w])

                if self._lows[w] >= self._pre[v]:
                    self._art[v] = 1

            else:

                if self._pre[v] < self._pre[w]:
                    self._down_links.append(v, w)
                else:
                    self._back_links.append(v, w)

                if w != st:
                    self._lows[v] = min(self._lows[v], self._pre[w])
                else:
                    self._parent_links.append(v, w)

        # if self._pre[v] == 0 and self._tree_links.keys_length():
        #     self._art[v] = 1

        if self._pre[v] == self._lows[v] and st != -1:
            self._bridges.append(st, v)

        self._post[v] = self._post_counter
        self._post_counter += 1