#!/bin/env python
# For experimenting with multiprocessing threads
import sys, time, string, re, os, argparse, subprocess, shlex
import multiprocessing
import signal

op = argparse.ArgumentParser(description="""
Description of script goes here
""")

op.add_argument('--count',            help='Number of jobs to execute, defaults to 2')
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


def worker(name, arg):
  #def my_handler(signal, frame):
  #  global name
  #  print 'worker %s really caught signal' % name, signal
  #  #raise RuntimeError('worker aborted')

  #signal.signal(signal.SIGINT, my_handler)
  #signal.signal(signal.SIGTERM, my_handler)

  print '*** Begin worker %s, arg = %d ***' % (name, arg)
  #time.sleep(150)
  run_cmd('worker.py')
  print '*** Exit worker %s ***' % name

joblist = []
def signal_term_handler(signal, frame):
  global joblist
  print 'thread_test.py: Aborting all threads...'
  for job in joblist:
    if job.is_alive():
      job.terminate()
  sys.exit(1)

signal.signal(signal.SIGINT, signal_term_handler)
signal.signal(signal.SIGTERM, signal_term_handler)

try:
  count = 2
  if opts.count:
    count = int(opts.count)
  for i in range(count):
    name = 'worker-%d' % i
    job = multiprocessing.Process(name=worker, target=worker, args=(worker, i))
    #job.daemon = True
    job.start()
    joblist.append(job)


  count = 1
  for job in joblist:
    print '*** Waiting on job %d ***' % count
    job.join()
    count += 1

  print '*** All jobs terminated'
except:
  print '*** Aborting all jobs'
  for job in joblist:
    job.terminate()
  print '*** All jobs aborted'


