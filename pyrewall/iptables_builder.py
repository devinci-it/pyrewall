import ipaddress

class IptablesBuilder:
    VALID_TABLES = {"filter", "nat", "mangle", "raw", "security"}
    VALID_CHAINS = {"INPUT", "OUTPUT", "FORWARD", "PREROUTING", "POSTROUTING"}
    VALID_ACTIONS = {"ACCEPT", "DROP", "REJECT", "LOG", "RETURN"}
    VALID_PROTOCOLS = {"tcp", "udp", "icmp", "all"}

    def __init__(self):
        self.parts = []

    def reset(self):
        self.parts = []
        return self

    def table(self, name="filter"):
        if name not in self.VALID_TABLES:
            raise ValueError(f"Invalid table name '{name}'. Must be one of {self.VALID_TABLES}")
        self.parts.append(f"-t {name}")
        return self

    def chain(self, name):
        if name not in self.VALID_CHAINS:
            raise ValueError(f"Invalid chain '{name}'. Must be one of {self.VALID_CHAINS}")
        self.parts.append(f"-A {name}")
        return self

    def action(self, action="ACCEPT"):
        action = action.upper()
        if action not in self.VALID_ACTIONS:
            raise ValueError(f"Invalid action '{action}'. Must be one of {self.VALID_ACTIONS}")
        self.parts.append(f"-j {action}")
        return self

    def protocol(self, proto):
        proto = proto.lower()
        if proto not in self.VALID_PROTOCOLS:
            raise ValueError(f"Invalid protocol '{proto}'. Must be one of {self.VALID_PROTOCOLS}")
        self.parts.append(f"-p {proto}")
        return self

    def source_ip(self, ip):
        if not self._validate_ip(ip):
            raise ValueError(f"Invalid source IP address '{ip}'")
        self.parts.append(f"-s {ip}")
        return self

    def dest_ip(self, ip):
        if not self._validate_ip(ip):
            raise ValueError(f"Invalid destination IP address '{ip}'")
        self.parts.append(f"-d {ip}")
        return self

    def source_port(self, port):
        if not self._validate_port(port):
            raise ValueError(f"Invalid source port '{port}'. Must be 1-65535")
        self.parts.append(f"--sport {port}")
        return self

    def dest_port(self, port):
        if not self._validate_port(port):
            raise ValueError(f"Invalid destination port '{port}'. Must be 1-65535")
        self.parts.append(f"--dport {port}")
        return self

    def comment(self, text):
        # Simple escaping for double quotes in comment text
        safe_text = text.replace('"', r'\"')
        self.parts.append(f'-m comment --comment "{safe_text}"')
        return self

    def state(self, states):
        # states can be a comma-separated string of states (e.g., "NEW,ESTABLISHED")
        if not states or not isinstance(states, str):
            raise ValueError("State must be a non-empty string")
        self.parts.append(f'-m conntrack --ctstate {states}')
        return self

    def log(self, prefix="IPT LOG", level=4):
        if not isinstance(prefix, str) or not prefix:
            raise ValueError("Log prefix must be a non-empty string")
        if not (0 <= level <= 7):
            raise ValueError("Log level must be between 0 and 7")
        safe_prefix = prefix.replace('"', r'\"')
        self.parts.append(
            f'-j LOG --log-prefix "{safe_prefix}: " --log-level {level}'
        )
        return self

    def build(self):
        if not self.parts:
            raise ValueError("No iptables rules parts to build command from")
        cmd = "iptables " + " ".join(self.parts)
        return cmd

    @staticmethod
    def _validate_ip(ip):
        try:
            ipaddress.ip_address(ip)
            return True
        except ValueError:
            return False

    @staticmethod
    def _validate_port(port):
        try:
            port_int = int(port)
            return 1 <= port_int <= 65535
        except (ValueError, TypeError):
            return False
