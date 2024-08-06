import logging

from trex.common.trex_logger import Logger


log = logging.getLogger('run-trex')
log.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

fh = logging.FileHandler('/var/log/trex/run-trex.log')
fh.setLevel(logging.DEBUG)
fh.setFormatter(formatter)

fhd = logging.FileHandler('/var/log/trex/trex.log')
fhd.setLevel(logging.DEBUG)
fhd.setFormatter(formatter)

st = logging.StreamHandler()
st.setLevel(logging.DEBUG)
st.setFormatter(formatter)

log.addHandler(fh)
log.addHandler(fhd)
log.addHandler(st)


class CustomLogger(Logger):
    def __init__ (self, verbose="error"):
        super(CustomLogger, self).__init__(verbose)
        self.msg = ''
        self.force_exit = False

    def _write (self, msg, newline):
        if not self.force_exit:
            ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
            if isinstance(msg, (str, bytes)):
                msg = ansi_escape.sub('', msg)
                self.msg += msg
            if newline:
                log.debug(self.msg)
                self.msg = ''

    def _flush (self):
        pass