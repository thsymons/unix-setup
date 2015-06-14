#!/bin/env python
# For experimenting with multiprocessing threads
import sys, time, string, re, os, argparse, subprocess, shlex
import signal, traceback

op = argparse.ArgumentParser(description="""
Description of script goes here
""")

op.add_argument('--count',            help='Number of jobs to execute, defaults to 2')
op.add_argument('-X',                 help='Show commands, but do not execute',action='store_true')
op.add_argument('cmdline',            help='Positional arguments',nargs='*')
opts = op.parse_args(sys.argv[1:])

def run_cmd(cmd,quiet=None,read=None,always=False,nowait=True):
  if not quiet:
    print cmd
  if not opts.X or always:
    if not read:
      return os.system(cmd)
      #status = subprocess.Popen(shlex.split(cmd),stdout=subprocess.PIPE,close_fds=True)
    elif nowait:
      return subprocess.Popen(shlex.split(cmd), shell=True)
    else:
      proc = subprocess.Popen(shlex.split(cmd),stdout=subprocess.PIPE)
      return proc.stdout.readlines()
  return 0

def is_parent_running():
  try:
    os.kill(os.getppid(), 0)
    return True
  except OSError:
    return False

def worker(name, arg):
  print '*** Begin worker %s, arg = %d ***' % (name, arg)
  #time.sleep(150)
  status = run_cmd('worker.py')
  print '*** Exit worker %s ***' % name
  #if status != 0:
  #  raise RuntimeError('*** Worker terminated with exit status = %d ' % status)
  #os._exit(status)
  return status

child_hash = {}
child_process = False

def signal_term_handler(signal, frame):
  import signal
  global child_hash, child_process
  print 'fork_test.py: Aborting all threads (child=%s)...' % child_process
  if not child_process:
    for pid in child_hash:
      print 'killing pid = %d' % pid
      os.kill(pid, signal.SIGTERM)
    while len(child_hash) > 0:
      print 'Waiting for %d child processes' % len(child_hash)
      pid, status = os.wait()
      del child_hash[pid]
  sys.exit(1)

signal.signal(signal.SIGINT, signal_term_handler)
signal.signal(signal.SIGTERM, signal_term_handler)

try:
  count = 2
  if opts.count:
    count = int(opts.count)
  for i in range(count):
    name = 'worker-%d' % i
    #r, w = os.pipe()
    r = 0
    pid = os.fork()
    if pid == 0: # child
      #os.close(r)
      #w = os.fdopen(w, 'w')
      child_process = True
      #os.setpgrp()
      status = worker(name, i)
      #if is_parent_running():
        #w.write('%d' % status)
        #w.close()
      print 'child process exiting with status = %d' % status
      os._exit(status)
    elif pid == -1:
      print 'What the hell ?  pid == -1'
      sys.exit(1)
    else: # parent
      #os.close(w)
      #r = os.fdopen(r)
      child_hash[pid] = r


  while len(child_hash) > 0:
    print '*** Waiting on %d childred ***' % len(child_hash)
    pid, status = os.wait()
    print '*** child process %d exited with status %d ***' % (pid, status)
    del child_hash[pid]

  print '*** All jobs terminated'
except SystemExit, err:
  print 'SystemExit issued'
except:
  traceback.print_exc()
  print '*** Exception caught - child=%s ***' % child_process


