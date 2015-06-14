#!/bin/env python
# For multiprocessing testing
import sys, time, string, re, os, argparse, subprocess, shlex, signal

op = argparse.ArgumentParser(description="""
Description of script goes here
""")

op.add_argument('-X',                 help='Show commands, but do not execute',action='store_true')
op.add_argument('cmdline',            help='Positional arguments',nargs='*')
opts = op.parse_args(sys.argv[1:])

def run_cmd(cmd,quiet=None,read=None,always=False):
  if not quiet:
    print cmd
  if not opts.X or always:
    if not read:
      return os.system(cmd)
    else:
      proc = subprocess.Popen(shlex.split(cmd),stdout=subprocess.PIPE)
      return proc.stdout.readlines()
  return 0

def signal_term_handler(signal, frame):
  print 'worker.py: Aborting...'
  sys.exit(1)

signal.signal(signal.SIGINT, signal_term_handler)
signal.signal(signal.SIGTERM, signal_term_handler)

#try:
run_cmd('sleep 5')
#time.sleep(100)
#print 'worker.py sleep terminated - sleep then exit'
#time.sleep(10)
print 'worker.py Exited normally'
sys.exit(1)
#except:
#  print 'worker.py Exception received'

