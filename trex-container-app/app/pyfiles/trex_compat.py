"""Compatibility shims for TRex v3.08 on Python 3.12+."""

import importlib
import sys
import types

_SCAPY_ROOT = "/opt/trex/trex-core/scripts/external_libs/scapy-2.4.3"
if _SCAPY_ROOT not in sys.path:
    sys.path.insert(0, _SCAPY_ROOT)

import scapy.modules.six as six

sys.modules.setdefault("scapy.modules.six.moves", six.moves)
sys.modules.setdefault("imp", types.SimpleNamespace(reload=importlib.reload))
