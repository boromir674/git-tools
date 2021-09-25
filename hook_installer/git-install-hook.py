#!/usr/bin/python3

import os
import argparse
import subprocess


here = os.path.dirname(os.path.realpath(__file__))

def get_args():
    parser = argparse.ArgumentParser(description="Interface to install git hooks")
    parser.add_argument('repo', nargs='?', default=os.getcwd(), help='the local checkout of repository, aka a directory monitored by git')
    parser.add_argument('hook_type', help='the type of git hook to install')
    parser.add_argument('file', help='an executable file to deploy as hook, eg a bash/perl script')
    return parser.parse_args()
    
    
def install_a_hook(h_type, h_to, h_from=None):
    if not h_from:
        h_from = './'
    cmd = '{}/install-hooks.pm {} {} {}'.format(here, h_from, h_type, h_to)
    try:
        out, err = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, shell=True).communicate()
        _print_big_grapple()
#        print(out)

    except Exception:
        print(err)

def _print_big_grapple():
#    print(here + '/Hook/single_hook_after_html.txt')
    with open(here + '/Hook/single_hook_after_html.txt', 'r') as f:
        print(f.read())

if __name__ == '__main__':
    args = get_args()
    install_a_hook(args.hook_type, args.file, args.repo)
