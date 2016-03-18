ctypedef public double (*valuefunc)(double t, double *pars, double *q) nogil
ctypedef public double (*densityfunc)(double t, double *pars, double *q) nogil
ctypedef public void (*gradientfunc)(double t, double *pars, double *q, double *grad) nogil

cdef class _CPotential:
    cdef double *_parameters
    cdef valuefunc c_value
    cdef gradientfunc c_gradient
    cdef densityfunc c_density
    cdef double[::1] _parvec # need to maintain a reference to parameter array

    cpdef value(self, double[:,::1] q, double t=?)
    cdef public double _value(self, double t, double *q) nogil

    cpdef gradient(self, double[:,::1] q, double t=?)
    cdef public void _gradient(self, double t, double *q, double *grad) nogil

    cpdef density(self, double[:,::1] q, double t=?)
    cdef public double _density(self, double t, double *q) nogil

    cpdef hessian(self, double[:,::1] w)
    cdef public void _hessian(self, double *w, double *hess) nogil

    cpdef mass_enclosed(self, double[:,::1] q, double G, double t=?)
    cdef public double _mass_enclosed(self, double t, double *q, double *epsilon, double Gee) nogil

    cpdef d_dr(self, double[:,::1] q, double G, double t=?)
    cdef public double _d_dr(self, double t, double *q, double *epsilon, double Gee) nogil

    cpdef d2_dr2(self, double[:,::1] q, double G, double t=?)
    cdef public double _d2_dr2(self, double t, double *q, double *epsilon, double Gee) nogil

# cdef class _CCompositePotential: #[type _CPotentialType, object _CPotential]:

#     cdef public int n  # number of potential components
#     cdef public double G  # gravitational constant in proper units
#     cdef public _CPotential[::1] cpotentials
#     cdef int[::1] pointers # points to array of pointers to C instances
#     cdef int[::1] param_pointers # points to array of pointers to C instances
#     cdef int * _pointers # points to array of pointers to C instances
#     cdef int * _param_pointers # points to array of pointers to C instances

#     cpdef value(self, double[:,::1] q)
#     cdef public double _value(self, double *q) nogil

#     # cpdef gradient(self, double[:,::1] q)
#     # cdef public void _gradient(self, double *q, double *grad) nogil

#     # cpdef hessian(self, double[:,::1] w)
#     # cdef public void _hessian(self, double *w, double *hess) nogil

#     # cpdef mass_enclosed(self, double[:,::1] q, double G)
#     # cdef public double _mass_enclosed(self, double *q, double *epsilon, double Gee) nogil
