import argparse
from pyrewall.iptables_builder import IptablesBuilder

def main():
    parser = argparse.ArgumentParser(description="Pyrewall - IPTables CLI")

    # Required args
    parser.add_argument(
        "--chain", required=True, choices=IptablesBuilder.VALID_CHAINS,
        help="Chain to append rule to"
    )
    parser.add_argument(
        "--action", required=True, choices=[a.lower() for a in IptablesBuilder.VALID_ACTIONS],
        help="Action to perform on matching packets"
    )
    parser.add_argument(
        "--protocol", required=True, choices=IptablesBuilder.VALID_PROTOCOLS,
        help="Protocol (tcp, udp, icmp, all)"
    )

    # Optional args
    parser.add_argument("--table", default="filter", choices=IptablesBuilder.VALID_TABLES, help="Table name (default: filter)")
    parser.add_argument("--source-ip", help="Source IP address")
    parser.add_argument("--dest-ip", help="Destination IP address")
    parser.add_argument("--source-port", type=int, help="Source port")
    parser.add_argument("--dest-port", type=int, help="Destination port")
    parser.add_argument("--comment", help="Comment for the rule")
    parser.add_argument("--state", help="Connection states (e.g. NEW,ESTABLISHED)")
    parser.add_argument("--log-prefix", help="Log prefix string (enable logging)")
    parser.add_argument("--log-level", type=int, default=4, help="Log level 0-7 (default 4)")

    args = parser.parse_args()

    fw = IptablesBuilder()
    fw.reset()

    try:
        fw.table(args.table)
        fw.chain(args.chain)
        fw.protocol(args.protocol)
        fw.action(args.action.upper())

        if args.source_ip:
            fw.source_ip(args.source_ip)
        if args.dest_ip:
            fw.dest_ip(args.dest_ip)
        if args.source_port:
            fw.source_port(args.source_port)
        if args.dest_port:
            fw.dest_port(args.dest_port)
        if args.comment:
            fw.comment(args.comment)
        if args.state:
            fw.state(args.state)
        if args.log_prefix:
            fw.log(prefix=args.log_prefix, level=args.log_level)

        print(fw.build())

    except ValueError as ve:
        print(f"Error: {ve}")

if __name__ == "__main__":
   main()    
