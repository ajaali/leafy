"""
Purpose:
*.
"""
from collections import defaultdict

from tabulate import tabulate


class Graph:

    def __init__(self):
        self._nodes = defaultdict(list)
        self._builders = {}
        self._values = {}

        self._index = {}
        self._ordered_nodes = None
        self._len = 0
        self._pre = []
        self._st = []
        self._post = []
        self._pre_counter = 0
        self._post_counter = 0
        self._edge_count = 0
        self._cycle = []
        self._colour = []

    def add(self, node_id, depends=None):
        self._index[node_id] = self._len
        self._len += 1

        if depends:
            current_depends = self._nodes.get(node_id, [])
            current_depends.extend(depends)
            self._nodes[node_id] = current_depends
            for depend in depends:
                self._nodes[depend].append(node_id)

    def add_edge(self, node_id_1, node_id_2):
        current_depends = self._nodes.get(node_id_1, [])
        current_depends.append(node_id_2)
        self._nodes[node_id_1] = current_depends

    def set_value(self, node_id, value):
        self._values[node_id] = value

    def simple_path(self, node_id_1, node_id_2):
        idx_n1 = self._index[node_id_1]
        idx_n2 = self._index[node_id_2]
        path = []

        self.dfs(node_id_1)

        st = self._st[idx_n2]
        path.append(idx_n2)
        while st != idx_n1:
            path.append(st)
            st = self._st[st]
        path.append(st)

        return [self.ordered_nodes[p][1] for p in reversed(path)]

    @property
    def ordered_nodes(self):
        if self._ordered_nodes is None:
            self._ordered_nodes = sorted((v, k) for k, v in self._index.items())
        return self._ordered_nodes

    def dfs(self, node_id, st=None, clr=0):
        if st is None:
            self._pre_counter = 0
            self._post_counter = 0
            self._edge_count = 0
            self._ordered_nodes = None
            self._pre = [None] * self._len
            self._st = [None] * self._len
            self._post = [None] * self._len
            self._colour = [None] * self._len

        idx = self._index[node_id]

        self._st[idx] = st
        self._colour[idx] = clr
        self._pre[idx] = self._pre_counter
        self._pre_counter += 1

        for depend in self._nodes[node_id]:
            depend_idx = self._index[depend]
            self._edge_count += 1
            if self._pre[depend_idx] is None:
                self.dfs(depend, idx, abs(clr - 1))
            elif depend_idx != st:
                if self._st[depend_idx] is None:
                    self._st[depend_idx] = idx
        self._post[idx] = self._post_counter
        self._post_counter += 1

    def pprint_dfs_results(self):

        table = [
            ['pre'] + self._pre,
            ['post'] + self._post,
            ['st'] + self._st,
            ['colour'] + self._colour
        ]
        print(tabulate(table, headers=[''] + self.ordered_nodes))
        print("Edge Count:", self._edge_count)

        two_colourability = True
        colour_edges = []
        for n in self._nodes:
            idx_n = self._index[n]
            clr_n = self._colour[idx_n]
            for d in self._nodes[n]:
                idx_d = self._index[d]
                clr_d = self._colour[idx_d]
                if clr_n == clr_d:
                    two_colourability = False
                colour_edges.append([f"{n}-{d}", clr_n, clr_d])

        # print(tabulate(colour_edges, headers=['Edge[w-v]', 'Colour[w]', 'Colour[v]']))
        print("Two Colourability:", two_colourability)