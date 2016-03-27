# coding: utf-8
# cython: boundscheck=False
# cython: nonecheck=False
# cython: cdivision=True
# cython: wraparound=False
# cython: profile=False

""" Built-in potentials implemented in Cython """

from __future__ import division, print_function

__author__ = "adrn <adrn@astro.columbia.edu>"

# Standard library
from collections import OrderedDict

# Third-party
from astropy.coordinates.angles import rotation_matrix
from astropy.constants import G
import astropy.units as u
import numpy as np
cimport numpy as np
np.import_array()

# Project
from ..cpotential import CPotentialBase
from ..cpotential cimport CPotentialWrapper

cdef extern from "src/cpotential.h":
    enum:
        MAX_N_COMPONENTS = 16

    ctypedef double (*densityfunc)(double t, double *pars, double *q) nogil
    ctypedef double (*valuefunc)(double t, double *pars, double *q) nogil
    ctypedef void (*gradientfunc)(double t, double *pars, double *q, double *grad) nogil

    ctypedef struct CPotential:
        int n_components
        densityfunc density[MAX_N_COMPONENTS]
        valuefunc value[MAX_N_COMPONENTS]
        gradientfunc gradient[MAX_N_COMPONENTS]
        int n_params[MAX_N_COMPONENTS]
        double *parameters[MAX_N_COMPONENTS]

    double c_value(CPotential *p, double t, double *q) nogil
    double c_density(CPotential *p, double t, double *q) nogil
    void c_gradient(CPotential *p, double t, double *q, double *grad) nogil

cdef extern from "src/_cbuiltin.h":
    double nan_density(double t, double *pars, double *q) nogil

    double henon_heiles_value(double t, double *pars, double *q) nogil
    void henon_heiles_gradient(double t, double *pars, double *q, double *grad) nogil

    double kepler_value(double t, double *pars, double *q) nogil
    void kepler_gradient(double t, double *pars, double *q, double *grad) nogil

    # double isochrone_value(double t, double *pars, double *q) nogil
    # void isochrone_gradient(double t, double *pars, double *q, double *grad) nogil
    # double isochrone_density(double t, double *pars, double *q) nogil

    # double hernquist_value(double t, double *pars, double *q) nogil
    # void hernquist_gradient(double t, double *pars, double *q, double *grad) nogil
    # double hernquist_density(double t, double *pars, double *q) nogil

    # double plummer_value(double t, double *pars, double *q) nogil
    # void plummer_gradient(double t, double *pars, double *q, double *grad) nogil
    # double plummer_density(double t, double *pars, double *q) nogil

    # double jaffe_value(double t, double *pars, double *q) nogil
    # void jaffe_gradient(double t, double *pars, double *q, double *grad) nogil
    # double jaffe_density(double t, double *pars, double *q) nogil

    # double stone_value(double t, double *pars, double *q) nogil
    # void stone_gradient(double t, double *pars, double *q, double *grad) nogil
    # double stone_density(double t, double *pars, double *q) nogil

    # double sphericalnfw_value(double t, double *pars, double *q) nogil
    # void sphericalnfw_gradient(double t, double *pars, double *q, double *grad) nogil
    # double sphericalnfw_density(double t, double *pars, double *q) nogil

    # double flattenednfw_value(double t, double *pars, double *q) nogil
    # void flattenednfw_gradient(double t, double *pars, double *q, double *grad) nogil
    # double flattenednfw_density(double t, double *pars, double *q) nogil

    # double miyamotonagai_value(double t, double *pars, double *q) nogil
    # void miyamotonagai_gradient(double t, double *pars, double *q, double *grad) nogil
    # double miyamotonagai_density(double t, double *pars, double *q) nogil

    # double leesuto_value(double t, double *pars, double *q) nogil
    # void leesuto_gradient(double t, double *pars, double *q, double *grad) nogil
    # double leesuto_density(double t, double *pars, double *q) nogil

    # double logarithmic_value(double t, double *pars, double *q) nogil
    # void logarithmic_gradient(double t, double *pars, double *q, double *grad) nogil

    # double rotating_logarithmic_value(double t, double *pars, double *q) nogil
    # void rotating_logarithmic_gradient(double t, double *pars, double *q, double *grad) nogil

    # double lm10_value(double t, double *pars, double *q) nogil
    # void lm10_gradient(double t, double *pars, double *q, double *grad) nogil

__all__ = ['HenonHeilesPotential', 'KeplerPotential']

# __all__ = ['HenonHeilesPotential', 'KeplerPotential', 'HernquistPotential',
#            'PlummerPotential', 'MiyamotoNagaiPotential',
#            'SphericalNFWPotential', 'FlattenedNFWPotential',
#            'LeeSutoTriaxialNFWPotential',
#            'LogarithmicPotential', 'JaffePotential',
#            'StonePotential', 'IsochronePotential',
#            'RotatingLogarithmicPotential']

# ============================================================================
#    Hénon-Heiles potential
#
cdef class HenonHeilesWrapper(_CPotential):

    def __init__(self, G, *args):
        cdef CPotential cp

        # This is the only code that needs to change per-potential
        cp.value[0] = <valuefunc>(henon_heiles_value)
        cp.density[0] = <densityfunc>(nan_density)
        cp.gradient[0] = <gradientfunc>(henon_heiles_gradient)
        self._params = np.array([G], dtype=np.float64)

        cp.n_components = n_components
        self._n_params = np.array([len(self._params)], dtype=np.int32)
        cp.n_params = &(self._n_params[0])
        cp.parameters[0] = &(self._params[0])
        self.cpotential = cp

class HenonHeilesPotential(CPotentialBase):
    r"""
    HenonHeilesPotential(units=None)

    The Hénon-Heiles potential.

    .. math::

        \Phi(x,y) = \frac{1}{2}(x^2 + y^2 + 2x^2 y - \frac{2}{3}y^3)

    Parameters
    ----------
    units : `~gary.units.UnitSystem` (optional)
        Set of non-reducable units that specify (at minimum) the
        length, mass, time, and angle units.

    """
    def __init__(self, units=None):
        parameters = OrderedDict()
        super(HenonHeilesPotential, self).__init__(parameters=parameters,
                                                   units=units)
        self.c_instance = HenonHeilesWrapper(self.G, self.c_parameters)

# ============================================================================
#    Kepler potential
#
cdef class KeplerPotentialWrapper(CPotentialWrapper):

    def __init__(self, G, parameters):
        cdef CPotential cp

        # This is the only code that needs to change per-potential
        cp.value[0] = <valuefunc>(kepler_value)
        cp.density[0] = <densityfunc>(nan_density)
        cp.gradient[0] = <gradientfunc>(kepler_gradient)
        self._params = np.array([G] + list(parameters), dtype=np.float64)

        # --------------------------------------------------------------------
        cp.n_components = n_components
        self._n_params = np.array([len(self._params)], dtype=np.int32)
        cp.n_params = &(self._n_params[0])
        cp.parameters[0] = &(self._params[0])
        self.cpotential = cp

class KeplerPotential(CPotentialBase):
    r"""
    KeplerPotential(m, units)

    The Kepler potential for a point mass.

    .. math::

        \Phi(r) = -\frac{Gm}{r}

    Parameters
    ----------
    m : numeric
        Mass.

    Parameters
    ----------
    units : `~gary.units.UnitSystem` (optional)
        Set of non-reducable units that specify (at minimum) the
        length, mass, time, and angle units.

    """
    def __init__(self, m, units):
        parameters = OrderedDict()
        parameters['m'] = m
        super(KeplerPotential, self).__init__(parameters=parameters,
                                              units=units)
        self.c_instance = KeplerPotentialWrapper(self.G, self.c_parameters)

# # ============================================================================
# #    Isochrone potential
# #
# cdef class _IsochronePotential(_CPotential):

#     def __cinit__(self, double G, double m, double b):
#         self._parvec = np.array([G,m,b])
#         self._parameters = &(self._parvec)[0]
#         self.c_value = &isochrone_value
#         self.c_gradient = &isochrone_gradient
#         self.c_density = &isochrone_density

# class IsochronePotential(CPotentialBase):
#     r"""
#     IsochronePotential(m, units)

#     The Isochrone potential.

#     .. math::

#         \Phi = -\frac{GM}{\sqrt{r^2+b^2} + b}

#     Parameters
#     ----------
#     m : numeric
#         Mass.
#     b : numeric
#         Core concentration.
#     units : `~gary.units.UnitSystem` (optional)
#         Set of non-reducable units that specify (at minimum) the
#         length, mass, time, and angle units.

#     """
#     def __init__(self, m, b, units):
#         self.parameters = dict(m=m, b=b)
#         super(IsochronePotential, self).__init__(units=units)
#         self.G = G.decompose(units).value
#         self.c_instance = _IsochronePotential(G=self.G, **self._c_parameters)

#     def action_angle(self, w):
#         """
#         Transform the input cartesian position and velocity to action-angle
#         coordinates the Isochrone potential. See Section 3.5.2 in
#         Binney & Tremaine (2008), and be aware of the errata entry for
#         Eq. 3.225.

#         This transformation is analytic and can be used as a "toy potential"
#         in the Sanders & Binney 2014 formalism for computing action-angle
#         coordinates in _any_ potential.

#         Adapted from Jason Sanders' code
#         `here <https://github.com/jlsanders/genfunc>`_.

#         Parameters
#         ----------
#         w : :class:`gary.dynamics.CartesianPhaseSpacePosition`, :class:`gary.dynamics.CartesianOrbit`
#             The positions or orbit to compute the actions, angles, and frequencies at.
#         """
#         from ...dynamics.analyticactionangle import isochrone_to_aa
#         return isochrone_to_aa(w, self)

#     # def phase_space(self, actions, angles):
#     #     """
#     #     Transform the input actions and angles to ordinary phase space (position
#     #     and velocity) in cartesian coordinates. See Section 3.5.2 in
#     #     Binney & Tremaine (2008), and be aware of the errata entry for
#     #     Eq. 3.225.

#     #     Parameters
#     #     ----------
#     #     actions : array_like
#     #     angles : array_like
#     #     """
#     #     from ...dynamics.analyticactionangle import isochrone_aa_to_xv
#     #     return isochrone_aa_to_xv(actions, angles, self)

# # ============================================================================
# #    Hernquist Spheroid potential from Hernquist 1990
# #    http://adsabs.harvard.edu/abs/1990ApJ...356..359H
# #
# cdef class _HernquistPotential(_CPotential):

#     def __cinit__(self, double G, double m, double c):
#         self._parvec = np.array([G,m,c])
#         self._parameters = &(self._parvec)[0]
#         self.c_value = &hernquist_value
#         self.c_gradient = &hernquist_gradient
#         self.c_density = &hernquist_density

# class HernquistPotential(CPotentialBase):
#     r"""
#     HernquistPotential(m, c, units)

#     Hernquist potential for a spheroid.

#     .. math::

#         \Phi(r) = -\frac{G M}{r + c}

#     Parameters
#     ----------
#     m : numeric
#         Mass.
#     c : numeric
#         Core concentration.
#     units : `~gary.units.UnitSystem` (optional)
#         Set of non-reducable units that specify (at minimum) the
#         length, mass, time, and angle units.

#     """
#     def __init__(self, m, c, units):
#         self.parameters = dict(m=m, c=c)
#         super(HernquistPotential, self).__init__(units=units)
#         self.G = G.decompose(units).value
#         self.c_instance = _HernquistPotential(G=self.G, **self._c_parameters)

# # ============================================================================
# #    Plummer sphere potential
# #
# cdef class _PlummerPotential(_CPotential):

#     def __cinit__(self, double G, double m, double b):
#         self._parvec = np.array([G,m,b])
#         self._parameters = &(self._parvec)[0]
#         self.c_value = &plummer_value
#         self.c_gradient = &plummer_gradient
#         self.c_density = &plummer_density

# class PlummerPotential(CPotentialBase):
#     r"""
#     PlummerPotential(m, b, units)

#     Plummer potential for a spheroid.

#     .. math::

#         \Phi(r) = -\frac{G M}{\sqrt{r^2 + b^2}}

#     Parameters
#     ----------
#     m : numeric
#        Mass.
#     b : numeric
#         Core concentration.
#     units : `~gary.units.UnitSystem` (optional)
#         Set of non-reducable units that specify (at minimum) the
#         length, mass, time, and angle units.

#     """
#     def __init__(self, m, b, units):
#         self.parameters = dict(m=m, b=b)
#         super(PlummerPotential, self).__init__(units=units)
#         self.G = G.decompose(units).value
#         self.c_instance = _PlummerPotential(G=self.G, **self._c_parameters)

# # ============================================================================
# #    Jaffe spheroid potential
# #
# cdef class _JaffePotential(_CPotential):

#     def __cinit__(self, double G, double m, double c):
#         self._parvec = np.array([G,m,c])
#         self._parameters = &(self._parvec)[0]
#         self.c_value = &jaffe_value
#         self.c_gradient = &jaffe_gradient
#         self.c_density = &jaffe_density

# class JaffePotential(CPotentialBase):
#     r"""
#     JaffePotential(m, c, units)

#     Jaffe potential for a spheroid.

#     .. math::

#         \Phi(r) = \frac{G M}{c} \ln(\frac{r}{r + c})

#     Parameters
#     ----------
#     m : numeric
#         Mass.
#     c : numeric
#         Core concentration.
#     units : `~gary.units.UnitSystem` (optional)
#         Set of non-reducable units that specify (at minimum) the
#         length, mass, time, and angle units.

#     """
#     def __init__(self, m, c, units):
#         self.parameters = dict(m=m, c=c)
#         super(JaffePotential, self).__init__(units=units)
#         self.G = G.decompose(units).value
#         self.c_instance = _JaffePotential(G=self.G, **self._c_parameters)


# # ============================================================================
# #    Miyamoto-Nagai Disk potential from Miyamoto & Nagai 1975
# #    http://adsabs.harvard.edu/abs/1975PASJ...27..533M
# #
# cdef class _MiyamotoNagaiPotential(_CPotential):

#     def __cinit__(self, double G, double m, double a, double b):
#         self._parvec = np.array([G,m,a,b])
#         self._parameters = &(self._parvec)[0]
#         self.c_value = &miyamotonagai_value
#         self.c_gradient = &miyamotonagai_gradient
#         self.c_density = &miyamotonagai_density

# class MiyamotoNagaiPotential(CPotentialBase):
#     r"""
#     MiyamotoNagaiPotential(m, a, b, units)

#     Miyamoto-Nagai potential for a flattened mass distribution.

#     .. math::

#         \Phi(R,z) = -\frac{G M}{\sqrt{R^2 + (a + \sqrt{z^2 + b^2})^2}}

#     Parameters
#     ----------
#     m : numeric
#         Mass.
#     a : numeric
#         Scale length.
#     b : numeric
#         Scare height.
#     units : `~gary.units.UnitSystem` (optional)
#         Set of non-reducable units that specify (at minimum) the
#         length, mass, time, and angle units.

#     """
#     def __init__(self, m, a, b, units):
#         self.parameters = dict(m=m, a=a, b=b)
#         super(MiyamotoNagaiPotential, self).__init__(units=units)
#         self.G = G.decompose(units).value
#         self.c_instance = _MiyamotoNagaiPotential(G=self.G, **self._c_parameters)

# # ============================================================================
# #    Stone and Ostriker potential (2015)
# #
# cdef class _StonePotential(_CPotential):

#     def __cinit__(self, double G, double m, double r_c, double r_h):
#         self._parvec = np.array([G,m,r_c,r_h])
#         self._parameters = &(self._parvec)[0]
#         self.c_value = &stone_value
#         self.c_gradient = &stone_gradient
#         self.c_density = &stone_density

# class StonePotential(CPotentialBase):
#     r"""
#     StonePotential(m, r_c, r_h, units)

#     Stone potential from `Stone & Ostriker (2015) <http://dx.doi.org/10.1088/2041-8205/806/2/L28>`_.

#     .. math::

#         \Phi(r) = -\frac{2 G M}{\pi(r_h - r_c)}\left[ \frac{\arctan(r/r_h)}{r/r_h} - \frac{\arctan(r/r_c)}{r/r_c} + \frac{1}{2}\ln\left(\frac{r^2+r_h^2}{r^2+r_c^2}\right)\right]

#     Parameters
#     ----------
#     m_tot : numeric
#         Total mass.
#     r_c : numeric
#         Core radius.
#     r_h : numeric
#         Halo radius.
#     units : `~gary.units.UnitSystem` (optional)
#         Set of non-reducable units that specify (at minimum) the
#         length, mass, time, and angle units.

#     """
#     def __init__(self, m, r_c, r_h, units):
#         self.parameters = dict(m=m, r_c=r_c, r_h=r_h)
#         super(StonePotential, self).__init__(units=units)
#         self.G = G.decompose(units).value
#         self.c_instance = _StonePotential(G=self.G, **self._c_parameters)

# # ============================================================================
# #    Spherical NFW potential
# #
# cdef class _SphericalNFWPotential(_CPotential):

#     def __cinit__(self, double G, double v_c, double r_s):
#         self._parvec = np.array([G, v_c,r_s])
#         self._parameters = &(self._parvec)[0]
#         self.c_value = &sphericalnfw_value
#         self.c_gradient = &sphericalnfw_gradient
#         self.c_density = &sphericalnfw_density

# class SphericalNFWPotential(CPotentialBase):
#     r"""
#     SphericalNFWPotential(v_c, r_s, units)

#     Spherical NFW potential. Separate from the triaxial potential below to
#     optimize for speed. Much faster than computing the triaxial case.

#     .. math::

#         \Phi(r) = -\frac{v_h^2}{\sqrt{\ln 2 - \frac{1}{2}}} \frac{\ln(1 + r/r_s)}{r/r_s}

#     Parameters
#     ----------
#     v_c : numeric
#         Circular velocity at the scale radius.
#     r_s : numeric
#         Scale radius.
#     units : `~gary.units.UnitSystem` (optional)
#         Set of non-reducable units that specify (at minimum) the
#         length, mass, time, and angle units.

#     """
#     def __init__(self, v_c, r_s, units):
#         self.parameters = dict(v_c=v_c, r_s=r_s)
#         super(SphericalNFWPotential, self).__init__(units=units)
#         self.G = G.decompose(units).value
#         self.c_instance = _SphericalNFWPotential(G=self.G, **self._c_parameters)

# # ============================================================================
# #    Flattened NFW potential
# #
# cdef class _FlattenedNFWPotential(_CPotential):

#     def __cinit__(self, double G, double v_c, double r_s, double q_z):
#         self._parvec = np.array([G, v_c,r_s,q_z])
#         self._parameters = &(self._parvec)[0]
#         self.c_value = &flattenednfw_value
#         self.c_gradient = &flattenednfw_gradient
#         self.c_density = &flattenednfw_density

# class FlattenedNFWPotential(CPotentialBase):
#     r"""
#     FlattenedNFWPotential(v_c, r_s, q_z, units)

#     Flattened NFW potential. Separate from the triaxial potential below to
#     optimize for speed. Much faster than computing the triaxial case.

#     .. math::

#         \Phi(r) = -\frac{v_h^2}{\sqrt{\ln 2 - \frac{1}{2}}} \frac{\ln(1 + r/r_s)}{r/r_s}\\
#         r^2 = x^2 + y^2 + z^2/q_z^2

#     Parameters
#     ----------
#     v_c : numeric
#         Circular velocity at the scale radius.
#     r_s : numeric
#         Scale radius.
#     q_z : numeric
#         Flattening.
#     units : `~gary.units.UnitSystem` (optional)
#         Set of non-reducable units that specify (at minimum) the
#         length, mass, time, and angle units.

#     """
#     def __init__(self, v_c, r_s, q_z, units):
#         self.parameters = dict(v_c=v_c, r_s=r_s, q_z=q_z)
#         super(FlattenedNFWPotential, self).__init__(units=units)
#         self.G = G.decompose(units).value
#         self.c_instance = _FlattenedNFWPotential(G=self.G, **self._c_parameters)

# # ============================================================================
# #    Lee & Suto (2003) triaxial NFW potential
# #    http://adsabs.harvard.edu/abs/2003ApJ...585..151L
# #
# cdef class _LeeSutoTriaxialNFWPotential(_CPotential):

#     def __cinit__(self, double G, double v_c, double r_s,
#                   double a, double b, double c,
#                   double R11, double R12, double R13,
#                   double R21, double R22, double R23,
#                   double R31, double R32, double R33):
#         self._parvec = np.array([G, v_c,r_s,a,b,c, R11,R12,R13,R21,R22,R23,R31,R32,R33])
#         self._parameters = &(self._parvec)[0]
#         self.c_value = &leesuto_value
#         self.c_gradient = &leesuto_gradient
#         self.c_density = &leesuto_density

# class LeeSutoTriaxialNFWPotential(CPotentialBase):
#     r"""
#     LeeSutoTriaxialNFWPotential(v_c, r_s, a, b, c, units, phi=0., theta=0., psi=0.)

#     Approximation of a Triaxial NFW Potential with the flattening in the density,
#     not the potential. See Lee & Suto (2003) for details.

#     .. warning::

#         There is a known bug with using the Euler angles to rotate the potential.
#         Avoid this for now.

#     Parameters
#     ----------
#     v_c : numeric
#         Circular velocity.
#     r_s : numeric
#         Scale radius.
#     a : numeric
#         Major axis.
#     b : numeric
#         Intermediate axis.
#     c : numeric
#         Minor axis.
#     phi : numeric (optional)
#         Euler angle for rotation about z-axis (using the x-convention
#         from Goldstein). Allows for specifying a misalignment between
#         the halo and disk potentials.
#     theta : numeric (optional)
#         Euler angle for rotation about x'-axis (using the x-convention
#         from Goldstein). Allows for specifying a misalignment between
#         the halo and disk potentials.
#     psi : numeric (optional)
#         Euler angle for rotation about z'-axis (using the x-convention
#         from Goldstein). Allows for specifying a misalignment between
#         the halo and disk potentials.
#     units : `~gary.units.UnitSystem` (optional)
#         Set of non-reducable units that specify (at minimum) the
#         length, mass, time, and angle units.

#     """
#     def __init__(self, v_c, r_s, a, b, c, units, phi=0., theta=0., psi=0., R=None):
#         self.parameters = dict(v_c=v_c, r_s=r_s, a=a, b=b, c=c)
#         super(LeeSutoTriaxialNFWPotential, self).__init__(units=units)
#         self.G = G.decompose(units).value

#         if R is None:
#             if theta != 0 or phi != 0 or psi != 0:
#                 D = rotation_matrix(phi, "z", unit=u.radian) # TODO: Bad assuming radians
#                 C = rotation_matrix(theta, "x", unit=u.radian)
#                 B = rotation_matrix(psi, "z", unit=u.radian)
#                 R = np.asarray(B.dot(C).dot(D))

#             else:
#                 R = np.eye(3)

#         # Note: R is the upper triangle of the rotation matrix
#         R = np.ravel(R)
#         if R.size != 9:
#             raise ValueError("Rotation matrix parameter, R, should have 9 elements.")

#         c_params = self.parameters.copy()
#         c_params['R11'] = R[0]
#         c_params['R12'] = R[1]
#         c_params['R13'] = R[2]
#         c_params['R21'] = R[3]
#         c_params['R22'] = R[4]
#         c_params['R23'] = R[5]
#         c_params['R31'] = R[6]
#         c_params['R32'] = R[7]
#         c_params['R33'] = R[8]
#         self.c_instance = _LeeSutoTriaxialNFWPotential(G=self.G, **c_params)
#         self.parameters['R'] = np.ravel(R).copy()*u.one

# # ============================================================================
# #    Triaxial, Logarithmic potential
# #
# cdef class _LogarithmicPotential(_CPotential):

#     def __cinit__(self, double v_c, double r_h,
#                   double q1, double q2, double q3,
#                   double R11, double R12, double R13,
#                   double R21, double R22, double R23,
#                   double R31, double R32, double R33):
#         self._parvec = np.array([v_c,r_h,q1,q2,q3, R11,R12,R13,R21,R22,R23,R31,R32,R33])
#         self._parameters = &(self._parvec)[0]
#         self.c_value = &logarithmic_value
#         self.c_gradient = &logarithmic_gradient
#         self.c_density = &nan_density

# class LogarithmicPotential(CPotentialBase):
#     r"""
#     LogarithmicPotential(v_c, r_h, q1, q2, q3, units, phi=0., theta=0., psi=0.)

#     Triaxial logarithmic potential.

#     .. math::

#         \Phi(x,y,z) &= \frac{1}{2}v_{c}^2\ln((x/q_1)^2 + (y/q_2)^2 + (z/q_3)^2 + r_h^2)\\

#     Parameters
#     ----------
#     v_c : numeric
#         Circular velocity.
#     r_h : numeric
#         Scale radius.
#     q1 : numeric
#         Flattening in X.
#     q2 : numeric
#         Flattening in Y.
#     q3 : numeric
#         Flattening in Z.
#     phi : numeric (optional)
#         Euler angle for rotation about z-axis (using the x-convention
#         from Goldstein). Allows for specifying a misalignment between
#         the halo and disk potentials.
#     theta : numeric (optional)
#         Euler angle for rotation about x'-axis (using the x-convention
#         from Goldstein). Allows for specifying a misalignment between
#         the halo and disk potentials.
#     psi : numeric (optional)
#         Euler angle for rotation about z'-axis (using the x-convention
#         from Goldstein). Allows for specifying a misalignment between
#         the halo and disk potentials.
#     units : `~gary.units.UnitSystem` (optional)
#         Set of non-reducable units that specify (at minimum) the
#         length, mass, time, and angle units.

#     """
#     def __init__(self, v_c, r_h, q1, q2, q3, units, phi=0., theta=0., psi=0., R=None):
#         self.parameters = dict(v_c=v_c, r_h=r_h, q1=q1, q2=q2, q3=q3)
#         super(LogarithmicPotential, self).__init__(units=units)
#         self.G = G.decompose(units).value

#         if R is None:
#             if theta != 0 or phi != 0 or psi != 0:
#                 D = rotation_matrix(phi, "z", unit=u.radian) # TODO: Bad assuming radians
#                 C = rotation_matrix(theta, "x", unit=u.radian)
#                 B = rotation_matrix(psi, "z", unit=u.radian)
#                 R = np.asarray(B.dot(C).dot(D))

#             else:
#                 R = np.eye(3)

#         R = np.ravel(R)
#         if R.size != 9:
#             raise ValueError("Rotation matrix parameter, R, should have 9 elements.")

#         c_params = self._c_parameters.copy()
#         c_params['R11'] = R[0]
#         c_params['R12'] = R[1]
#         c_params['R13'] = R[2]
#         c_params['R21'] = R[3]
#         c_params['R22'] = R[4]
#         c_params['R23'] = R[5]
#         c_params['R31'] = R[6]
#         c_params['R32'] = R[7]
#         c_params['R33'] = R[8]
#         self.c_instance = _LogarithmicPotential(**c_params)
#         self.parameters['R'] = np.ravel(R).copy()*u.one

# # ============================================================================
# #    Rotating, triaxial, Logarithmic potential
# #
# cdef class _RotatingLogarithmicPotential(_CPotential):

#     def __cinit__(self, double v_c, double r_h,
#                   double q1, double q2, double q3,
#                   double alpha, double Omega):
#         self._parvec = np.array([v_c,r_h,q1,q2,q3,alpha,Omega])
#         self._parameters = &(self._parvec)[0]
#         self.c_value = &rotating_logarithmic_value
#         self.c_gradient = &rotating_logarithmic_gradient
#         self.c_density = &nan_density

# class RotatingLogarithmicPotential(CPotentialBase):
#     r"""
#     RotatingLogarithmicPotential(v_c, r_h, q1, q2, q3, alpha, Omega, units)

#     Rotating, triaxial logarithmic potential.

#     .. math::

#         \Phi(x,y,z) &= \frac{1}{2}v_{c}^2\ln((x/q_1)^2 + (y/q_2)^2 + (z/q_3)^2 + r_h^2)\\

#     Parameters
#     ----------
#     v_c : numeric
#         Circular velocity.
#     r_h : numeric
#         Scale radius.
#     q1 : numeric
#         Flattening in X.
#     q2 : numeric
#         Flattening in Y.
#     q3 : numeric
#         Flattening in Z.
#     alpha : numeric
#         Initial bar angle.
#     Omega : numeric
#         Pattern speed.
#     units : `~gary.units.UnitSystem` (optional)
#         Set of non-reducable units that specify (at minimum) the
#         length, mass, time, and angle units.

#     """
#     def __init__(self, v_c, r_h, q1, q2, q3, alpha, Omega, units):
#         self.parameters = dict(v_c=v_c, r_h=r_h, q1=q1, q2=q2, q3=q3, alpha=alpha, Omega=Omega)
#         super(RotatingLogarithmicPotential, self).__init__(units=units)
#         self.G = G.decompose(units).value
#         self.c_instance = _RotatingLogarithmicPotential(**self._c_parameters)

# # ------------------------------------------------------------------------
# # HACK
# cdef class _LM10Potential(_CPotential):

#     def __cinit__(self, double G, double m_spher, double c,
#                   double G2, double m_disk, double a, double b,
#                   double v_c, double r_h,
#                   double q1, double q2, double q3,
#                   double R11, double R12, double R13,
#                   double R21, double R22, double R23,
#                   double R31, double R32, double R33):
#         self._parvec = np.array([G,m_spher,c,
#                                  G,m_disk,a,b,
#                                  v_c,r_h,q1,q2,q3,
#                                  R11,R12,R13,R21,R22,R23,R31,R32,R33])
#         self._parameters = &(self._parvec[0])
#         self.c_value = &lm10_value
#         self.c_gradient = &lm10_gradient
#         self.c_density = &nan_density

# # BROKEN NOW
# # class LM10Potential(CPotentialBase):
# #     r"""
# #     LM10Potential(units, bulge=dict(), disk=dict(), halo=dict())

# #     Three-component Milky Way potential model from Law & Majewski (2010).

# #     Parameters
# #     ----------
# #     units : iterable
# #         Unique list of non-reducable units that specify (at minimum) the
# #         length, mass, time, and angle units.
# #     bulge : dict
# #         Dictionary of parameter values for a :class:`HernquistPotential`.
# #     disk : dict
# #         Dictionary of parameter values for a :class:`MiyamotoNagaiPotential`.
# #     halo : dict
# #         Dictionary of parameter values for a :class:`LogarithmicPotential`.

# #     """
# #     def __init__(self, units=galactic, bulge=dict(), disk=dict(), halo=dict()):
# #         self.G = G.decompose(units).value
# #         self.parameters = dict()
# #         default_bulge = dict(m=3.4E10*u.Msun, c=0.7*u.kpc)
# #         default_disk = dict(m=1E11*u.Msun, a=6.5*u.kpc, b=0.26*u.kpc)
# #         default_halo = dict(q1=1.38, q2=1., q3=1.36, r_h=12.*u.kpc,
# #                             phi=97*u.degree,
# #                             v_c=np.sqrt(2)*(121.858*u.km/u.s),
# #                             theta=0., psi=0.)

# #         for k,v in default_disk.items():
# #             if k not in disk:
# #                 disk[k] = v
# #         self.parameters['disk'] = disk

# #         for k,v in default_bulge.items():
# #             if k not in bulge:
# #                 bulge[k] = v
# #         self.parameters['bulge'] = bulge

# #         for k,v in default_halo.items():
# #             if k not in halo:
# #                 halo[k] = v
# #         self.parameters['halo'] = halo

# #         super(LM10Potential, self).__init__(units=units)

# #         if halo.get('R', None) is None:
# #             if halo['theta'] != 0 or halo['phi'] != 0 or halo['psi'] != 0:
# #                 D = rotation_matrix(halo['phi'], "z", unit=u.radian) # TODO: Bad assuming radians
# #                 C = rotation_matrix(halo['theta'], "x", unit=u.radian)
# #                 B = rotation_matrix(halo['psi'], "z", unit=u.radian)
# #                 R = np.asarray(B.dot(C).dot(D))

# #             else:
# #                 R = np.eye(3)
# #         else:
# #             R = halo['R']

# #         R = np.ravel(R)
# #         if R.size != 9:
# #             raise ValueError("Rotation matrix parameter, R, should have 9 elements.")

# #         c_params = dict()

# #         # bulge
# #         c_params['G'] = self.G
# #         c_params['m_spher'] = bulge['m']
# #         c_params['c'] = bulge['c']

# #         # disk
# #         c_params['G2'] = self.G
# #         c_params['m_disk'] = disk['m']
# #         c_params['a'] = disk['a']
# #         c_params['b'] = disk['b']

# #         # halo
# #         c_params['v_c'] = halo['v_c']
# #         c_params['r_h'] = halo['r_h']
# #         c_params['q1'] = halo['q1']
# #         c_params['q2'] = halo['q2']
# #         c_params['q3'] = halo['q3']
# #         c_params['R11'] = R[0]
# #         c_params['R12'] = R[1]
# #         c_params['R13'] = R[2]
# #         c_params['R21'] = R[3]
# #         c_params['R22'] = R[4]
# #         c_params['R23'] = R[5]
# #         c_params['R31'] = R[6]
# #         c_params['R32'] = R[7]
# #         c_params['R33'] = R[8]
# #         self.c_instance = _LM10Potential(**c_params)
