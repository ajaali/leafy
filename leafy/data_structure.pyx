from cpython.mem cimport PyMem_Malloc, PyMem_Free


cdef link *create_link(int v, link *prev_link):
    cdef link *x = <link *> PyMem_Malloc(sizeof(link))
    x.val = v
    x.next = NULL
    if prev_link is not NULL:
        prev_link.next = x
        x.counter = prev_link.counter + 1
    else:
        x.counter = 0
    return x


cdef link ** linked_list(int length):
    cdef int i
    cdef link ** link_list = <link **> PyMem_Malloc(length * sizeof(link*))
    for i in range(length):
        link_list[i] = NULL
    return link_list


cdef class AdjacencyList:
    """Adjacency list data structure which is an array of linked lists."""
    def __cinit__(self, int length):
        self._array_length = length
        self._start = linked_list(length)
        self._end = linked_list(length)

    def __dealloc__(self):
        cdef link *al
        cdef link *next_al
        for i in range(self._array_length):
            al = self._start[i]
            while al is not NULL:
                next_al = al.next
                PyMem_Free(al)
                al = next_al

    cdef void append(self, int index, int value):
        assert 0 <= index < self._array_length
        if self._start[index] is NULL:
            self._start[index] = create_link(value, NULL)
            self._end[index] = self._start[index]
        else:
            self._end[index] = create_link(value, self._end[index])

    cdef int length(self, int index):
        assert 0 <= index < self._array_length
        return self._end[index].counter

    cdef list as_py_list(self):
        cdef link *al
        cdef int i
        ret_list = []
        for i in range(self._array_length):
            i_list = []
            al = self._start[i]
            while al is not NULL:
                i_list.append(al.val)
                al = al.next
            ret_list.append(i_list)
        return ret_list





