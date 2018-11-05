from util import shell, _os

class Portforward():

    port_rule_tmpl="sudo iptables -t nat {ACTION} PREROUTING -m {PROTO} -p {PROTO} -i {DEF_IF} --dport {SPORT} -j DNAT --to-destination {CT_IP}:{DPORT} -m comment --comment 'lxt_managed {CT_NAME}' "

    def __init__(self, ct):
        self.ct = ct


    def add_portforward(self, proto, s_port, d_port):
        self.sh = shell.ShellExec()
        self.sh.sh(self.get_port_rule_cmd('-A', proto, s_port, d_port))


    def remove_portforward(self, proto, s_port, d_port):
        self.sh = shell.ShellExec()
        self.sh.sh(self.get_port_rule_cmd('-D', proto, s_port, d_port))


    def get_port_rule_cmd(self, action, proto, s_port, d_port):
        port_rule_var =  {'ACTION': action,
               'PROTO': proto,
               'DEF_IF': _os.OS.default_if().replace('\n',''),
               'SPORT': s_port,
               'SPORT': s_port,
               'CT_IP': self.ct.main_ip(),
               'CT_NAME': self.ct.name,
               'DPORT': d_port}

        return Portforward.port_rule_tmpl.format(**port_rule_var)
