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
import cython
cimport cython

# Project
from .cpotential cimport _CPotential
from .cpotential import CPotential
from .core import CartesianPotential

cdef extern from "math.h":
    double sqrt(double x) nogil
    double cbrt(double x) nogil
    double sin(double x) nogil
    double cos(double x) nogil
    double log(double x) nogil
    double fabs(double x) nogil
    double exp(double x) nogil
    double pow(double x, double n) nogil

__all__ = ['HernquistPotential', 'MiyamotoNagaiPotential',
           'LeeSutoNFWPotential', 'LogarithmicPotential',
           'JaffePotential']

# ============================================================================
#    Hernquist Spheroid potential from Hernquist 1990
#    http://adsabs.harvard.edu/abs/1990ApJ...356..359H
#
cdef class _HernquistPotential(_CPotential):

    # here need to cdef all the attributes
    cdef public double G, GM
    cdef public double m, c

    def __init__(self, double G, double m, double c):
        """ Units of everything should be in the system:
                kpc, Myr, radian, M_sun
        """
        # cdef double G = 4.499753324353494927e-12 # kpc^3 / Myr^2 / M_sun
        # have to specify G in the correct units
        self.G = G

        # disk parameters
        self.GM = G*m
        self.m = m
        self.c = c

    cdef public inline double _value(self, double[:,::1] r, int k) nogil:
        cdef double R
        R = sqrt(r[k,0]*r[k,0] + r[k,1]*r[k,1] + r[k,2]*r[k,2])
        return -self.GM / (R + self.c)

    cdef public inline void _gradient(self, double[:,::1] r, double[:,::1] grad, int k) nogil:
        cdef double R, fac
        R = sqrt(r[k,0]*r[k,0] + r[k,1]*r[k,1] + r[k,2]*r[k,2])
        fac = self.GM / ((R + self.c) * (R + self.c) * R)

        grad[k,0] += fac*r[k,0]
        grad[k,1] += fac*r[k,1]
        grad[k,2] += fac*r[k,2]

class HernquistPotential(CPotential, CartesianPotential):
    r"""
    Hernquist potential for a spheroid.

    .. math::

        \Phi_{spher} = -\frac{GM_{spher}}{r + c}

    Parameters
    ----------
    m : numeric
        Mass.
    c : numeric
        Core concentration.
    units : iterable
        Unique list of non-reducable units that specify (at minimum) the
        length, mass, time, and angle units.

    """
    def __init__(self, m, c, units):
        self.units = units
        _G = G.decompose(units).value
        parameters = dict(G=_G, m=m, c=c)
        super(HernquistPotential, self).__init__(_HernquistPotential,
                                                 parameters=parameters)

# ============================================================================
#    Jaffe Spheroid potential
#
cdef class _JaffePotential(_CPotential):

    # here need to cdef all the attributes
    cdef public double G, GM
    cdef public double m, c

    def __init__(self, double G, double m, double c):
        """ Units of everything should be in the system:
                kpc, Myr, radian, M_sun
        """
        # cdef double G = 4.499753324353494927e-12 # kpc^3 / Myr^2 / M_sun
        # have to specify G in the correct units
        self.G = G

        # disk parameters
        self.GM = G*m
        self.m = m
        self.c = c

    cdef public inline double _value(self, double[:,::1] r, int k) nogil:
        cdef double R
        R = sqrt(r[k,0]*r[k,0] + r[k,1]*r[k,1] + r[k,2]*r[k,2])
        return self.GM / self.c * log(R / (R + self.c))

    cdef public inline void _gradient(self, double[:,::1] r, double[:,::1] grad, int k) nogil:
        cdef double R, fac
        R = sqrt(r[k,0]*r[k,0] + r[k,1]*r[k,1] + r[k,2]*r[k,2])
        fac = self.GM / ((R + self.c) * R * R)

        grad[k,0] += fac*r[k,0]
        grad[k,1] += fac*r[k,1]
        grad[k,2] += fac*r[k,2]

class JaffePotential(CPotential, CartesianPotential):
    r"""
    Jaffe potential for a spheroid.

    .. math::

        TODO

    Parameters
    ----------
    m : numeric
        Mass.
    c : numeric
        Core concentration.
    units : iterable
        Unique list of non-reducable units that specify (at minimum) the
        length, mass, time, and angle units.

    """
    def __init__(self, m, c, units):
        self.units = units
        _G = G.decompose(units).value
        parameters = dict(G=_G, m=m, c=c)
        super(JaffePotential, self).__init__(_JaffePotential,
                                             parameters=parameters)


# ============================================================================
#    Miyamoto-Nagai Disk potential from Miyamoto & Nagai 1975
#    http://adsabs.harvard.edu/abs/1975PASJ...27..533M
#
cdef class _MiyamotoNagaiPotential(_CPotential):

    # here need to cdef all the attributes
    cdef public double G, GM
    cdef public double m, a, b, b2

    def __init__(self, double G, double m, double a, double b):
        """ Units of everything should be in the system:
                kpc, Myr, radian, M_sun
        """
        # cdef double G = 4.499753324353494927e-12 # kpc^3 / Myr^2 / M_sun
        # have to specify G in the correct units
        self.G = G

        # disk parameters
        self.GM = G*m
        self.m = m
        self.a = a
        self.b = b
        self.b2 = b*b

    cdef public inline double _value(self, double[:,::1] r, int k) nogil:
        cdef double zd
        zd = (self.a + sqrt(r[k,2]*r[k,2] + self.b2))
        return -self.GM / sqrt(r[k,0]*r[k,0] + r[k,1]*r[k,1] + zd*zd)

    cdef public inline void _gradient(self, double[:,::1] r, double[:,::1] grad, int k) nogil:
        cdef double sqrtz, zd, fac

        sqrtz = sqrt(r[k,2]*r[k,2] + self.b2)
        zd = self.a + sqrtz
        fac = self.GM*pow(r[k,0]*r[k,0] + r[k,1]*r[k,1] + zd*zd, -1.5)

        grad[k,0] += fac*r[k,0]
        grad[k,1] += fac*r[k,1]
        grad[k,2] += fac*r[k,2] * (1. + self.a / sqrtz)

class MiyamotoNagaiPotential(CPotential, CartesianPotential):
    r"""
    Miyamoto-Nagai potential for a flattened mass distribution.

    .. math::

        \Phi_{disk} = -\frac{GM_{disk}}{\sqrt{R^2 + (a + \sqrt{z^2 + b^2})^2}}

    Parameters
    ----------
    m : numeric
        Mass.
    a : numeric
    b : numeric
    units : iterable
        Unique list of non-reducable units that specify (at minimum) the
        length, mass, time, and angle units.

    """
    def __init__(self, m, a, b, units):
        self.units = units
        _G = G.decompose(units).value
        parameters = dict(G=_G, m=m, a=a, b=b)
        super(MiyamotoNagaiPotential, self).__init__(_MiyamotoNagaiPotential,
                                                     parameters=parameters)

# ============================================================================
#    Lee & Suto (2003) triaxial NFW potential
#    http://adsabs.harvard.edu/abs/2003ApJ...585..151L
#
cdef class _LeeSutoNFWPotential(_CPotential):

    # here need to cdef all the attributes
    cdef public double v_h, r_h, a, b, c, e_b2, e_c2, G
    cdef public double v_h2, r_h2, a2, b2, c2, x0
    cdef public double[:,::1] R, Rinv
    cdef public unsigned int rotated, spherical

    def __init__(self, double v_h, double r_h, double a, double b, double c,
                 double[:,::1] R):
        """ Units of everything should be in the system:
                kpc, Myr, radian, M_sun
        """

        self.v_h = v_h
        self.v_h2 = v_h*v_h
        self.r_h = r_h
        self.r_h2 = r_h*r_h
        self.a = a
        self.a2 = a*a
        self.b = b
        self.b2 = b*b
        self.c = c
        self.c2 = c*c

        self.e_b2 = 1-pow(b/a,2)
        self.e_c2 = 1-pow(c/a,2)
        if (self.e_b2 == 0.) and (self.e_c2 == 0.):
            self.spherical = 1
        else:
            self.spherical = 0

        self.R = R
        self.Rinv = R.T.copy()

        self.rotated = 0
        for i in range(3):
            for j in range(3):
                if self.R[i,j] != self.Rinv[i,j]:
                    self.rotated = 1

        self.G = 4.49975332435e-12  # kpc, Myr, Msun

    cdef public inline double _value(self, double[:,::1] r, int k) nogil:

        if self.spherical == 1:
            return self._value_spherical(r, k)
        else:
            return self._value_triaxial(r, k)

    cdef public inline double _value_spherical(self, double[:,::1] r, int k) nogil:
        cdef double u
        u = sqrt(r[k,0]*r[k,0] + r[k,1]*r[k,1] + r[k,2]*r[k,2]) / self.r_h
        return -self.v_h2 * log(1 + u) / u

    cdef public inline double _value_triaxial(self, double[:,::1] r, int k) nogil:

        cdef double x, y, z, _r, u

        x = self.R[0,0]*r[k,0] + self.R[0,1]*r[k,1] + self.R[0,2]*r[k,2]
        y = self.R[1,0]*r[k,0] + self.R[1,1]*r[k,1] + self.R[1,2]*r[k,2]
        z = self.R[2,0]*r[k,0] + self.R[2,1]*r[k,1] + self.R[2,2]*r[k,2]

        _r = sqrt(x*x + y*y + z*z)
        u = _r / self.r_h
        return self.v_h2*((self.e_b2/2 + self.e_c2/2)*((1/u - 1/u**3)*log(u + 1) - 1 + (2*u**2 - 3*u + 6)/(6*u**2)) + (self.e_b2*y**2/(2*_r*_r) + self.e_c2*z*z/(2*_r*_r))*((u*u - 3*u - 6)/(2*u*u*(u + 1)) + 3*log(u + 1)/u/u/u) - log(u + 1)/u)

    cdef public inline void _gradient_spherical(self, double[:,::1] r, double[:,::1] grad, int k) nogil:
        cdef double fac, u

        u = sqrt(r[k,0]*r[k,0] + r[k,1]*r[k,1] + r[k,2]*r[k,2]) / self.r_h
        fac = self.v_h2 / (u*u*u) / self.r_h2 * (log(1+u) - u/(1+u))

        grad[k,0] += fac*r[k,0]
        grad[k,1] += fac*r[k,1]
        grad[k,2] += fac*r[k,2]

    cdef public inline void _gradient_triaxial(self, double[:,::1] r, double[:,::1] grad, int k) nogil:
        cdef:
            double x, y, z, _r, _r2, _r4, ax, ay, az
            double x0, x2, x22

            double x20, x21, x7, x1
            double x10, x13, x15, x16, x17

        x = self.R[0,0]*r[k,0] + self.R[0,1]*r[k,1] + self.R[0,2]*r[k,2]
        y = self.R[1,0]*r[k,0] + self.R[1,1]*r[k,1] + self.R[1,2]*r[k,2]
        z = self.R[2,0]*r[k,0] + self.R[2,1]*r[k,1] + self.R[2,2]*r[k,2]

        _r2 = x*x + y*y + z*z
        _r = sqrt(_r2)
        _r4 = _r2*_r2

        x0 = _r + self.r_h
        x1 = x0*x0
        x2 = self.v_h2/(12.*_r4*_r2*_r*x1)
        x10 = log(x0/self.r_h)

        x13 = _r*3.*self.r_h
        x15 = x13 - _r2
        x16 = x15 + 6.*self.r_h2
        x17 = 6.*self.r_h*x0*(_r*x16 - x0*x10*6.*self.r_h2)
        x20 = x0*_r2
        x21 = 2.*_r*x0
        x7 = self.e_b2*y*y + self.e_c2*z*z
        x22 = -12.*_r4*_r*self.r_h*x0 + 12.*_r4*self.r_h*x1*x10 + 3.*self.r_h*x7*(x16*_r2 - 18.*x1*x10*self.r_h2 + x20*(2.*_r - 3.*self.r_h) + x21*(x15 + 9.*self.r_h2)) - x20*(self.e_b2 + self.e_c2)*(-6.*_r*self.r_h*(_r2 - self.r_h2) + 6.*self.r_h*x0*x10*(_r2 - 3.*self.r_h2) + x20*(-4.*_r + 3.*self.r_h) + x21*(-x13 + 2.*_r2 + 6.*self.r_h2))

        ax = x2*x*(x17*x7 + x22)
        ay = x2*y*(x17*(x7 - _r2*self.e_b2) + x22)
        az = x2*z*(x17*(x7 - _r2*self.e_c2) + x22)

        grad[k,0] += self.Rinv[0,0]*ax + self.Rinv[0,1]*ay + self.Rinv[0,2]*az
        grad[k,1] += self.Rinv[1,0]*ax + self.Rinv[1,1]*ay + self.Rinv[1,2]*az
        grad[k,2] += self.Rinv[2,0]*ax + self.Rinv[2,1]*ay + self.Rinv[2,2]*az

    cdef public inline void _gradient(self, double[:,::1] r, double[:,::1] grad, int k) nogil:

        if self.spherical == 1:
            self._gradient_spherical(r, grad, k)
        else:
            self._gradient_triaxial(r, grad, k)

class LeeSutoNFWPotential(CPotential, CartesianPotential):
    r"""
    TODO:

    .. math::

        \Phi() =

    Parameters
    ----------
    phi : numeric (optional)
        Euler angle for rotation about z-axis (using the x-convention
        from Goldstein). Allows for specifying a misalignment between
        the halo and disk potentials.
    theta : numeric (optional)
        Euler angle for rotation about x'-axis (using the x-convention
        from Goldstein). Allows for specifying a misalignment between
        the halo and disk potentials.
    psi : numeric (optional)
        Euler angle for rotation about z'-axis (using the x-convention
        from Goldstein). Allows for specifying a misalignment between
        the halo and disk potentials.
    units : iterable
        Unique list of non-reducable units that specify (at minimum) the
        length, mass, time, and angle units.

    """
    def __init__(self, v_h, r_h, a, b, c, phi=0., theta=0., psi=0., units=None):
        self.units = units
        parameters = dict(v_h=v_h, r_h=r_h, a=a, b=b, c=c)

        if theta != 0 or phi != 0 or psi != 0:
            D = rotation_matrix(phi, "z", unit=u.radian) # TODO: Bad assuming radians
            C = rotation_matrix(theta, "x", unit=u.radian)
            B = rotation_matrix(psi, "z", unit=u.radian)
            R = np.array(B.dot(C).dot(D))

        else:
            R = np.eye(3)

        parameters['R'] = R
        super(LeeSutoNFWPotential, self).__init__(_LeeSutoNFWPotential,
                                                  parameters=parameters)

# ============================================================================
#    Triaxial, Logarithmic potential
#
cdef class _LogarithmicPotential(_CPotential):

    # here need to cdef all the attributes
    cdef public double v_c, r_h, q1, q2, q3, G
    cdef public double v_c2, r_h2, q1_2, q2_2, q3_2, x0
    cdef public double[:,::1] R, Rinv

    def __init__(self, double v_c, double r_h, double q1, double q2, double q3,
                 double[:,::1] R):
        """ Units of everything should be in the system:
                kpc, Myr, radian, M_sun
        """

        self.v_c = v_c
        self.v_c2 = v_c*v_c
        self.r_h = r_h
        self.r_h2 = r_h*r_h
        self.q1 = q1
        self.q1_2 = q1*q1
        self.q2 = q2
        self.q2_2 = q2*q2
        self.q3 = q3
        self.q3_2 = q3*q3

        self.R = R
        self.Rinv = np.linalg.inv(R)

        self.G = 4.49975332435e-12  # kpc, Myr, Msun

    cdef public inline double _value(self, double[:,::1] r, int k) nogil:

        cdef double x, y, z

        x = self.R[0,0]*r[k,0] + self.R[0,1]*r[k,1] + self.R[0,2]*r[k,2]
        y = self.R[1,0]*r[k,0] + self.R[1,1]*r[k,1] + self.R[1,2]*r[k,2]
        z = self.R[2,0]*r[k,0] + self.R[2,1]*r[k,1] + self.R[2,2]*r[k,2]

        return 0.5*self.v_c2 * log(x*x/self.q1_2 + y*y/self.q2_2 + z*z/self.q3_2 + self.r_h2)

    cdef public inline void _gradient(self, double[:,::1] r, double[:,::1] grad, int k) nogil:

        cdef double x, y, z, _r, _r2, ax, ay, az

        x = self.R[0,0]*r[k,0] + self.R[0,1]*r[k,1] + self.R[0,2]*r[k,2]
        y = self.R[1,0]*r[k,0] + self.R[1,1]*r[k,1] + self.R[1,2]*r[k,2]
        z = self.R[2,0]*r[k,0] + self.R[2,1]*r[k,1] + self.R[2,2]*r[k,2]

        _r2 = x*x + y*y + z*z
        _r = sqrt(_r2)

        fac = self.v_c2/(self.r_h2 + x*x/self.q1_2 + y*y/self.q2_2 + z*z/self.q3_2)
        ax = fac*x/self.q1_2
        ay = fac*y/self.q2_2
        az = fac*z/self.q3_2

        grad[k,0] += self.Rinv[0,0]*ax + self.Rinv[0,1]*ay + self.Rinv[0,2]*az
        grad[k,1] += self.Rinv[1,0]*ax + self.Rinv[1,1]*ay + self.Rinv[1,2]*az
        grad[k,2] += self.Rinv[2,0]*ax + self.Rinv[2,1]*ay + self.Rinv[2,2]*az

class LogarithmicPotential(CPotential, CartesianPotential):
    r"""
    Triaxial logarithmic potential.

    TODO:

    .. math::

        \Phi &= \frac{1}{2}v_{c}^2\ln((x/q_1)^2 + (y/q_2)^2 + (z/q_3)^2 + r_h^2)\\

    Parameters
    ----------
    v_c : numeric
        Circular velocity.
    r_h : numeric
        Scale radius.
    q1 : numeric
        Flattening in X-Y plane.
    q2 : numeric
        Flattening in X-Y plane.
    q3 : numeric
        Flattening in Z direction.
    phi : numeric (optional)
        Euler angle for rotation about z-axis (using the x-convention
        from Goldstein). Allows for specifying a misalignment between
        the halo and disk potentials.
    theta : numeric (optional)
        Euler angle for rotation about x'-axis (using the x-convention
        from Goldstein). Allows for specifying a misalignment between
        the halo and disk potentials.
    psi : numeric (optional)
        Euler angle for rotation about z'-axis (using the x-convention
        from Goldstein). Allows for specifying a misalignment between
        the halo and disk potentials.
    units : iterable
        Unique list of non-reducable units that specify (at minimum) the
        length, mass, time, and angle units.

    """
    def __init__(self, v_c, r_h, q1, q2, q3, phi=0., theta=0., psi=0., units=None):
        self.units = units
        parameters = dict(v_c=v_c, r_h=r_h, q1=q1, q2=q2, q3=q3)

        if theta != 0 or phi != 0 or psi != 0:
            D = rotation_matrix(phi, "z", unit=u.radian)  # TODO: Bad assuming radians
            C = rotation_matrix(theta, "x", unit=u.radian)
            B = rotation_matrix(psi, "z", unit=u.radian)
            R = np.array(B.dot(C).dot(D))

        else:
            R = np.eye(3)

        parameters['R'] = R
        super(LogarithmicPotential, self).__init__(_LogarithmicPotential,
                                                   parameters=parameters)

# ============================================================================
#    Pal5 Challenge Halo (for Gaia Challenge)
#
cdef class _Pal5AxisymmetricNFWPotential(_CPotential):

    # here need to cdef all the attributes
    cdef public double M, Rh, qz
    cdef public double G, GM, qz2

    def __init__(self, double M, double Rh, double qz):
        """ Units of everything should be in the system:
                kpc, Myr, radian, M_sun
        """
        self.M = M
        self.Rh = Rh
        self.qz = qz

        self.qz2 = self.qz * self.qz
        self.G = 4.49975332435e-12  # kpc, Myr, Msun
        self.GM = self.G * self.M

    cdef public inline double _value(self, double[:,::1] r, int k) nogil:
        cdef double R
        R = r[k,0]*r[k,0] + r[k,1]*r[k,1] + r[k,2]*r[k,2]/self.qz2
        return -self.GM / R * log(1. + R/self.Rh)

    cdef public inline void _gradient(self, double[:,::1] r, double[:,::1] grad, int k) nogil:
        cdef double R, dPhi_dR
        R = sqrt(r[k,0]*r[k,0] + r[k,1]*r[k,1] + r[k,2]*r[k,2]/self.qz2)
        dPhi_dR = self.GM / R / R * (log(1+R/self.Rh) - R/(R+self.Rh))
        grad[k,0] += dPhi_dR * r[k,0] / R
        grad[k,1] += dPhi_dR * r[k,1] / R
        grad[k,2] += dPhi_dR * r[k,2] / (R * self.qz2)

class Pal5AxisymmetricNFWPotential(CPotential, CartesianPotential):
    r"""
    Flattened, axisymmetric NFW potential Andreas used for the Pal 5 challenge.

    .. math::

        \Phi &=

    Parameters
    ----------
    TODO:
    qz : numeric
        Flattening in Z direction.
    units : iterable
        Unique list of non-reducable units that specify (at minimum) the
        length, mass, time, and angle units.

    """
    def __init__(self, M, Rh, qz, units=None):
        self.units = units
        parameters = dict(M=M, Rh=Rh, qz=qz)
        super(Pal5AxisymmetricNFWPotential, self).__init__(_Pal5AxisymmetricNFWPotential,
                                                           parameters=parameters)
