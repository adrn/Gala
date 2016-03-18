# coding: utf-8

""" Read and write potentials to text (YAML) files. """

from __future__ import division, print_function

__author__ = "adrn <adrn@astro.columbia.edu>"

# Standard library
import os

# Third-party
import astropy.units as u
from astropy.utils import isiterable
import yaml

from .. import potential as gp

__all__ = ['load', 'save']

def pythonify(node):
    for key, item in node.items():
        if hasattr(item, 'items'):
            pythonify(item)
        else:
            if hasattr(item,'unit'):
                node[key] = item.value
                node[key+'_unit'] = str(item.unit)

                if hasattr(node[key], 'tolist'):
                    node[key] = node[key].tolist()

            elif hasattr(item,'tolist'):
                node[key] = item.tolist()

            elif isiterable(item) and not isinstance(item, str):
                node[key] = map(float, list(item))

            elif '_unit' in key:
                continue

            elif key+'_unit' in node:
                node[key] = float(item)*u.Unit(node[key+'_unit'])
                del node[key+'_unit']

            else:
                node[key] = float(item)

def _parse_component(component, module):
    try:
        class_name = component['class']
    except KeyError:
        raise KeyError("Potential dictionary must contain a key 'class' for "
                       "specifying the name of the Potential class.")

    if 'units' not in component:
        unitsys = None
    else:
        try:
            unitsys = [u.Unit(unit) for ptype,unit in component['units'].items()]
        except KeyError:
            raise KeyError("Potential dictionary must contain a key 'units' with "
                           "a list of strings specifying the unit system.")

    if 'parameters' in component:
        params = component['parameters']
    else:
        params = dict()

    # need to crawl the dictionary structure and make sure everything is float or
    #   a list of floats
    pythonify(params)

    if module is None:
        from .. import potential
    else:
        potential = module

    Potential = getattr(potential, class_name)
    return Potential(units=unitsys, **params)

def from_dict(d, module=None):
    """
    Convert a dictionary potential specification into a
    :class:`~gary.potential.PotentialBase` subclass object.

    Parameters
    ----------
    d : dict
        Dictionary specification of a potential.
    module : namespace (optional)

    """

    if 'type' in d and d['type'] == 'composite':
        p = getattr(gp, d['class'])()
        for i,component in enumerate(d['components']):
            c = _parse_component(component, module)
            name = component.get('name', str(i))
            p[name] = c

    else:
        p = _parse_component(d, module)

    return p

def _to_dict_help(potential):
    d = dict()

    if potential.units is not None:
        d['units'] = dict([(str(ptype),str(unit)) for ptype,unit in potential.units.to_dict().items()])

    if len(potential.parameters) > 0:
        params = dict(**potential.parameters)
        pythonify(params)
        d['parameters'] = params

    return d

def to_dict(potential):
    """
    Turn a potential object into a dictionary that fully specifies the
    state of the object.

    Parameters
    ----------
    potential : :class:`~gary.potential.PotentialBase`
        The instantiated :class:`~gary.potential.PotentialBase` object.

    """

    if isinstance(potential, gp.CompositePotential):
        d = dict()
        d['type'] = 'composite'
        d['class'] = potential.__class__.__name__
        d['components'] = []
        for k,p in potential.items():
            comp_dict = _to_dict_help(p)
            comp_dict['name'] = k
            d['components'].append(comp_dict)

    else:
        d = _to_dict_help(potential)

    return d

def load(f, module=None):
    """
    Read a potential specification file and return a
    :class:`~gary.potential.PotentialBase` object instantiated with parameters
    specified in the spec file.

    Parameters
    ----------
    f : str, file_like
        A block of text, filename, or file-like object to parse and read
        a potential from.
    module : namespace (optional)

    """
    try:
        with open(os.path.abspath(f)) as fil:
            p_dict = yaml.load(fil.read())
    except:
        p_dict = yaml.load(f)

    return from_dict(p_dict, module=module)

def save(potential, f):
    """
    Write a :class:`~gary.potential.PotentialBase` object out to a text (YAML)
    file.

    Parameters
    ----------
    potential : :class:`~gary.potential.PotentialBase`
        The instantiated :class:`~gary.potential.PotentialBase` object.
    f : str, file_like
        A filename or file-like object to write the input potential object to.

    """
    d = to_dict(potential)

    if hasattr(f, 'write'):
        yaml.dump(d, f, default_flow_style=False)
    else:
        with open(f, 'w') as f:
            yaml.dump(d, f, default_flow_style=False)

