import sys, argparse
from cmd import *



def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--act", help="command and args.")
    parser.add_argument("--ct_name", help="container name.")
    parser.add_argument("--img", help="base container image.")
    parser.add_argument("--ct_path", help="ctl, container path.")
    parser.add_argument("--ssh_user", help="ssh username.")
    parser.add_argument("--portforward", help="port forward literal. {protocol}:{sport}:{dport}")
    parser.add_argument("--snap_name", help="lxc snapshot name, lxc info containerName.")
    parser.add_argument("--expand_size", help="size of expand zfs disk. ex) --expand_size 5G, --expand_size 2900M.")
    return parser.parse_args()


if __name__ == '__main__':

    cmd_args = parse_args()
    inv = cmd.CmdFactory().create(cmd_args)
    inv.exec()
